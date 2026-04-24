import 'dart:math';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/particles.dart';
import 'package:triple_tile_match_puzzle/game/components/tile_component.dart';
import 'package:triple_tile_match_puzzle/game/components/tray_component.dart';
import 'package:triple_tile_match_puzzle/game/components/hammer_component.dart';
import 'package:triple_tile_match_puzzle/game/managers/level_manager.dart';
import 'package:triple_tile_match_puzzle/models/tile_data.dart';
import 'package:triple_tile_match_puzzle/utils/constants.dart';
import 'package:flutter/material.dart';

class TileMatchGame extends FlameGame {
  late final TrayComponent tray;
  final Function(int)? onWin;
  final VoidCallback? onLose;
  final VoidCallback? onLevelChanged;
  final VoidCallback? onLockedSlotTapped;

  DateTime _startTime = DateTime.now();
  bool _levelLoaded = false;
  bool _isAnimating = false;
  double tileSize = 60.0;

  TileMatchGame({
    this.onWin,
    this.onLose,
    this.onLevelChanged,
    this.onLockedSlotTapped,
  });

  @override
  Color backgroundColor() => Colors.transparent;

  void refreshSettings() {}

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    tray = TrayComponent();
    tray.onLockedSlotTapped = () {
      onLockedSlotTapped?.call();
    };
    add(tray);

    refreshSettings();

    if (size.x > 0) {
      _updateLayout();
      if (!_levelLoaded) {
        _levelLoaded = true;
        _loadLevel(LevelManager.currentLevel);
      }
    }
  }

  void _updateLayout() {
    tileSize = (size.x / 8.5).clamp(40.0, 70.0);
    tray.updateSize(size.x);
    tray.position = Vector2(size.x / 2, size.y * 0.15);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded && size.x > 0) {
      _updateLayout();
      if (!_levelLoaded) {
        _levelLoaded = true;
        _loadLevel(LevelManager.currentLevel);
      }
    }
  }

  void _loadLevel(int level) {
    _isAnimating = true;
    final tileDataList = LevelManager.generateLevel(level, tileSize * 0.92);
    final result = _computeCenteredPositions(tileDataList);
    final centeredData = result.tiles;
    final dynamicScale = result.scale;

    // Apply dynamic scale if level is tight
    for (var tileData in centeredData) {
      final tile = TileComponent(data: tileData);
      tile.size = tile.size * dynamicScale;
      add(tile);
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      _updateBlockedStatus();
      _isAnimating = false;
    });

    onLevelChanged?.call();
  }

  _LayoutResult _computeCenteredPositions(List<TileData> tiles) {
    if (tiles.isEmpty || size.x <= 0) return _LayoutResult(tiles, 1.0);

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final t in tiles) {
      minX = min(minX, t.x);
      minY = min(minY, t.y);
      maxX = max(maxX, t.x + tileSize);
      maxY = max(maxY, t.y + tileSize);
    }

    double groupWidth = maxX - minX;
    double groupHeight = maxY - minY;

    final boardTop = tray.y + tray.size.y + 20;
    final boardBottom = size.y - 120.0;
    final availableWidth = size.x - 40.0;
    final availableHeight = boardBottom - boardTop - 20.0;

    double scale = 1.0;
    if (groupWidth > availableWidth) {
      scale = min(scale, availableWidth / groupWidth);
    }
    if (groupHeight > availableHeight) {
      scale = min(scale, availableHeight / groupHeight);
    }

    // Recalculate with scale
    if (scale < 1.0) {
      groupWidth *= scale;
      groupHeight *= scale;
    }

    final offsetX = (size.x - groupWidth) / 2 - (minX * scale);
    final boardCenterY = (boardTop + boardBottom) / 2;
    final offsetY = boardCenterY - (groupHeight / 2) - (minY * scale);

    final scaledTiles =
        tiles
            .map(
              (t) => TileData(
                id: t.id,
                type: t.type,
                layer: t.layer,
                x: t.x * scale + offsetX,
                y: t.y * scale + offsetY,
              ),
            )
            .toList();

    return _LayoutResult(scaledTiles, scale);
  }

  void _updateBlockedStatus() {
    final allTiles = children.whereType<TileComponent>().toList();
    final tilesOnBoard = allTiles.where((t) => !t.isInTray).toList();

    for (var tile in tilesOnBoard) {
      bool isCovered = false;
      final tileHitbox = tile.hitbox;
      final tilePriority = tile.priority;

      for (var other in tilesOnBoard) {
        if (other == tile) continue;
        if (other.priority > tilePriority) {
          if (other.hitbox.overlaps(tileHitbox)) {
            isCovered = true;
            break;
          }
        }
      }
      tile.isBlocked = isCovered;
    }
    for (var tile in allTiles) {
      if (tile.isInTray) tile.isBlocked = false;
    }
  }

  void onTileTapped(TileComponent tile) {
    if (_isAnimating || tile.isInTray || tile.isBlocked) return;

    if (tray.canAddTile()) {
      _lastMovedTile = tile;
      _lastTilePosition = tile.position.clone();
      _lastTilePriority = tile.priority;

      tile.removeFromParent();
      tray.addTile(tile);
      add(tile);

      _updateBlockedStatus();
      checkWinCondition();
    }
  }

  TileComponent? _lastMovedTile;
  Vector2? _lastTilePosition;
  int? _lastTilePriority;

  /// Returns true if undo was performed, false if nothing to undo.
  bool undo() {
    if (_lastMovedTile != null &&
        _lastMovedTile!.isInTray &&
        tray.tilesInTray.contains(_lastMovedTile)) {
      tray.tilesInTray.remove(_lastMovedTile);
      _lastMovedTile!.isInTray = false;
      _lastMovedTile!.position = _lastTilePosition!;
      _lastMovedTile!.priority = _lastTilePriority!;
      _lastMovedTile!.scale = Vector2.all(1.0);

      _lastMovedTile = null;
      _lastTilePosition = null;
      _lastTilePriority = null;

      tray.rearrangeTiles();
      _updateBlockedStatus();
      return true;
    }
    return false;
  }

  void shuffle() {
    final tilesOnBoard = children
        .whereType<TileComponent>()
        .where((t) => !t.isInTray)
        .toList();
    if (tilesOnBoard.isEmpty) return;
    _isAnimating = true;

    final positions = tilesOnBoard
        .map((t) => (t.boardPosition ?? t.position).clone())
        .toList();
    final priorities = tilesOnBoard
        .map((t) => t.boardPriority ?? t.priority)
        .toList();

    positions.shuffle();

    for (int i = 0; i < tilesOnBoard.length; i++) {
      final tile = tilesOnBoard[i];
      final targetPos = positions[i];
      final targetPriority = priorities[i];

      Future.delayed(Duration(milliseconds: i * 30), () {
        if (!tile.isMounted) return;
        tile.moveTo(targetPos);
        tile.priority = targetPriority;
        tile.boardPosition = targetPos.clone();
        tile.boardPriority = targetPriority;

        if (i == tilesOnBoard.length - 1) {
          _updateBlockedStatus();
          _isAnimating = false;
        }
      });
    }
  }

  void hint() {
    final tilesOnBoard = children
        .whereType<TileComponent>()
        .where((t) => !t.isInTray && !t.isBlocked)
        .toList();
    if (tilesOnBoard.isEmpty) return;

    final groups = <int, List<TileComponent>>{};
    for (var tile in tilesOnBoard) {
      groups.putIfAbsent(tile.data.type, () => []).add(tile);
    }

    for (var type in groups.keys) {
      if (groups[type]!.length >= 3) {
        for (var tile in groups[type]!.take(3)) {
          tile.add(
            ColorEffect(
              Colors.yellow,
              EffectController(
                duration: 0.5,
                reverseDuration: 0.5,
                repeatCount: 3,
              ),
              opacityFrom: 0,
              opacityTo: 0.5,
            ),
          );
        }
        return;
      }
    }
  }

  void addExtraSlot() {
    tray.unlock7thSlot();
  }

  bool isHammerMode = false;
  void activateHammer() {
    isHammerMode = true;
  }

  void useHammerOnTile(TileComponent tappedTile) {
    isHammerMode = false;
    _isAnimating = true;

    // Find all board tiles of the same type as the tapped tile
    final sameTypeTiles = children
        .whereType<TileComponent>()
        .where((t) => !t.isInTray && t.data.type == tappedTile.data.type)
        .toList();

    // Build the removal list: tapped tile first, then others (prefer unblocked)
    final tilesToRemove = <TileComponent>[tappedTile];
    final others = sameTypeTiles.where((t) => t != tappedTile).toList();
    // Sort: unblocked first so we preferentially remove accessible tiles
    others.sort((a, b) => (a.isBlocked ? 1 : 0).compareTo(b.isBlocked ? 1 : 0));
    for (var t in others) {
      if (tilesToRemove.length >= 3) break;
      tilesToRemove.add(t);
    }

    // Save positions/priorities for replacement tiles
    final savedPositions = tilesToRemove.map((t) => t.position.clone()).toList();
    final savedPriorities = tilesToRemove.map((t) => t.priority).toList();

    // Determine valid types for replacement tiles from remaining board tiles
    final remainingTypes = <int>{};
    for (var t in children.whereType<TileComponent>()) {
      if (!t.isInTray && !tilesToRemove.contains(t)) {
        remainingTypes.add(t.data.type);
      }
    }

    // Hammer animation on the tapped tile position
    add(
      HammerComponent(
        position: tappedTile.position.clone(),
        onHit: () {
          // Animate removal of all tiles in the set
          int removedCount = 0;
          for (var tile in tilesToRemove) {
            spawnMatchParticles(tile.position.clone());
            tile.add(
              ScaleEffect.to(
                Vector2.zero(),
                EffectController(duration: 0.3, curve: Curves.easeInBack),
                onComplete: () {
                  tile.removeFromParent();
                  if (tile.isInTray) {
                    tray.tilesInTray.remove(tile);
                    tray.rearrangeTiles();
                  }
                  removedCount++;
                  if (removedCount >= tilesToRemove.length) {
                    // All removed — now spawn replacements
                    _spawnReplacementTiles(
                      savedPositions,
                      savedPriorities,
                      remainingTypes,
                    );
                  }
                },
              ),
            );
          }
        },
      ),
    );
  }

  /// Spawns replacement tiles at the given positions, then shuffles the board.
  void _spawnReplacementTiles(
    List<Vector2> positions,
    List<int> priorities,
    Set<int> availableTypes,
  ) {
    final rng = Random();

    // Build a pool of types that still need matches on the board
    // Count remaining tiles per type
    final typeCount = <int, int>{};
    for (var t in children.whereType<TileComponent>()) {
      if (!t.isInTray) {
        typeCount[t.data.type] = (typeCount[t.data.type] ?? 0) + 1;
      }
    }

    // Prefer types where count % 3 != 0 (they need more tiles to complete a set)
    final needyTypes = typeCount.entries
        .where((e) => e.value % 3 != 0)
        .map((e) => e.key)
        .toList();

    // Replacement types: 3 tiles of the same type to form a valid matchable set
    int replacementType;
    if (needyTypes.isNotEmpty) {
      replacementType = needyTypes[rng.nextInt(needyTypes.length)];
    } else if (availableTypes.isNotEmpty) {
      replacementType = availableTypes.elementAt(rng.nextInt(availableTypes.length));
    } else {
      replacementType = 1; // fallback
    }

    for (int i = 0; i < positions.length; i++) {
      final tileData = TileData(
        id: 'hammer_${DateTime.now().millisecondsSinceEpoch}_$i',
        type: replacementType,
        layer: priorities[i],
        x: positions[i].x,
        y: positions[i].y,
      );
      final newTile = TileComponent(data: tileData);
      newTile.size = Vector2.all(tileSize);
      add(newTile);
    }

    // Shuffle the board once after a short delay to let tiles appear
    Future.delayed(const Duration(milliseconds: 500), () {
      shuffle();
      _updateBlockedStatus();
      _isAnimating = false;
      checkWinCondition();
    });
  }

  void revive() {
    _isLevelFinished = false;
    _isAnimating = true;
    isHammerMode = false;
    if (tray.tilesInTray.isNotEmpty) {
      final tilesToReturn = tray.tilesInTray.reversed.take(3).toList();
      int returnedCount = 0;

      for (int i = 0; i < tilesToReturn.length; i++) {
        final tile = tilesToReturn[i];
        Future.delayed(Duration(milliseconds: i * 40), () {
          if (!tile.isMounted) return;
          tray.tilesInTray.remove(tile);
          tile.isInTray = false;
          if (tile.boardPosition != null && tile.boardPriority != null) {
            tile.returnToBoard(
              tile.boardPosition!,
              tile.boardPriority!,
              onComplete: () {
                returnedCount++;
                if (returnedCount == tilesToReturn.length) {
                  shuffle();
                  _updateBlockedStatus();
                }
              },
            );
          } else {
            returnedCount++;
            if (returnedCount == tilesToReturn.length) {
              shuffle();
              _updateBlockedStatus();
            }
          }
        });
      }
    } else {
      shuffle();
    }
  }

  void useMagnet() {
    final tilesOnBoard = children
        .whereType<TileComponent>()
        .where((t) => !t.isInTray)
        .toList();
    final groups = <int, List<TileComponent>>{};
    for (var tile in tilesOnBoard) {
      groups.putIfAbsent(tile.data.type, () => []).add(tile);
    }

    for (var type in groups.keys) {
      if (groups[type]!.length >= 3) {
        if (tray.tilesInTray.length <= tray.maxSlots - 3) {
          final matchTiles = groups[type]!.take(3).toList();
          for (var tile in matchTiles) {
            tile.isBlocked = false;
            tile.removeFromParent();
            add(tile);
          }
          // Use dedicated magnet method for clean flight & instant match
          tray.addMagnetTiles(matchTiles);
          _updateBlockedStatus();
        }
        return;
      }
    }
  }

  bool _isLevelFinished = false;

  void checkWinCondition() {
    if (_isLevelFinished) return;
    final tilesOnBoard = children
        .whereType<TileComponent>()
        .where((t) => !t.isInTray)
        .toList();
    if (tilesOnBoard.isEmpty && tray.tilesInTray.isEmpty) {
      _isLevelFinished = true;
      final elapsed = DateTime.now().difference(_startTime).inSeconds;
      int stars = 1;
      if (elapsed < 45) {
        stars = 3;
      } else if (elapsed < 90) {
        stars = 2;
      }
      onWin?.call(stars);
    }
  }

  void checkLoseCondition() {
    if (_isLevelFinished) return;
    if (tray.tilesInTray.length >= tray.effectiveSlots) {
      _isLevelFinished = true;
      onLose?.call();
    }
  }

  void spawnMatchParticles(Vector2 position) {
    add(
      ParticleSystemComponent(
        position: position,
        particle: Particle.generate(
          count: 15,
          lifespan: 0.8,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2(
              (Random().nextDouble() - 0.5) * 200,
              (Random().nextDouble() - 0.5) * 200,
            ),
            child: CircleParticle(
              radius: 2 + Random().nextDouble() * 3,
              paint: Paint()..color = Colors.amber.withValues(alpha: 0.8),
            ),
          ),
        ),
      ),
    );
  }

  void resetLevel([int? newLevel]) {
    _isLevelFinished = false;
    children.whereType<TileComponent>().forEach((t) => t.removeFromParent());
    tray.tilesInTray.clear();
    tray.maxSlots = GameConstants.baseTraySlots;
    tray.lock7thSlot(); // Re-lock the 7th slot on level reset
    _updateLayout();
    tray.rearrangeTiles();
    _startTime = DateTime.now();
    _levelLoaded = true;
    if (newLevel != null) {
      LevelManager.currentLevel = newLevel;
    }
    _loadLevel(LevelManager.currentLevel);
    _isAnimating = false;
  }
}

class _LayoutResult {
  final List<TileData> tiles;
  final double scale;
  _LayoutResult(this.tiles, this.scale);
}
