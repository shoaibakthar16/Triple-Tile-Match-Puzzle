import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:triple_tile_match_puzzle/game/components/tile_component.dart';
import 'package:triple_tile_match_puzzle/game/game.dart';
import 'package:triple_tile_match_puzzle/utils/constants.dart';
import 'package:triple_tile_match_puzzle/services/audio_manager.dart';
import 'package:triple_tile_match_puzzle/services/game_provider.dart';
import 'package:provider/provider.dart';

class TrayComponent extends PositionComponent
    with HasGameReference<TileMatchGame>, TapCallbacks {
  final List<TileComponent> tilesInTray = [];
  double traySlotSize = 60.0;
  int maxSlots = GameConstants.baseTraySlots;
  static const double padding = 5.0;
  bool _isMatching = false;

  /// When true, the 7th slot is locked and cannot hold tiles.
  bool is7thSlotLocked = true;

  /// Called when the locked 7th slot is tapped (so UI can show an ad).
  VoidCallback? onLockedSlotTapped;

  // Cached Rendering Objects for performance optimization
  Rect _mainRect = Rect.zero;
  RRect _mainRRect = RRect.zero;
  RRect _shadowRRect = RRect.zero;

  final List<RRect> _slotRRects = [];
  final List<RRect> _slotDepthRRects = [];

  // Cached lock icon painter
  TextPainter? _lockPainter;

  TrayComponent() : super(anchor: Anchor.topCenter);

  /// The effective number of usable slots (6 if locked, 7 if unlocked).
  int get effectiveSlots => is7thSlotLocked ? maxSlots - 1 : maxSlots;

  void updateSize(double screenWidth) {
    traySlotSize = game.tileSize;

    size = Vector2(
      (traySlotSize + padding) * maxSlots + padding,
      traySlotSize + padding * 2,
    );
    _updateCache();
  }

  void _updateCache() {
    _mainRect = Rect.fromLTWH(0, 0, size.x, size.y);
    _mainRRect = RRect.fromRectAndRadius(_mainRect, const Radius.circular(16));
    _shadowRRect = _mainRRect.shift(const Offset(0, 4));

    _slotRRects.clear();
    _slotDepthRRects.clear();

    for (int i = 0; i < maxSlots; i++) {
      final slotRect = Rect.fromLTWH(
        padding + i * (traySlotSize + padding),
        padding,
        traySlotSize,
        traySlotSize,
      );
      final slotRRect = RRect.fromRectAndRadius(
        slotRect,
        const Radius.circular(10),
      );
      _slotRRects.add(slotRRect);
      _slotDepthRRects.add(slotRRect.shift(const Offset(0, 3)));
    }

    // Pre-build lock icon painter
    _lockPainter = TextPainter(
      text: const TextSpan(
        text: '🔒',
        style: TextStyle(fontSize: 22),
      ),
      textDirection: TextDirection.ltr,
    );
    _lockPainter!.layout();
  }

  @override
  void render(Canvas canvas) {
    if (_mainRRect == RRect.zero) return;

    // Shadow
    canvas.drawRRect(
      _shadowRRect,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Glass Background
    canvas.drawRRect(
      _mainRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill,
    );

    // Border
    canvas.drawRRect(
      _mainRRect,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Draw slots
    final slotBorderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < maxSlots; i++) {
      if (i >= _slotRRects.length) break;

      final slotRRect = _slotRRects[i];
      final slotDepthRRect = _slotDepthRRects[i];
      final isLockedSlot = is7thSlotLocked && i == maxSlots - 1;

      // 3D Depth for slot
      canvas.drawRRect(
        slotDepthRRect,
        Paint()..color = Colors.black.withValues(alpha: 0.2),
      );

      if (isLockedSlot) {
        // Locked slot: darker tint + lock icon
        canvas.drawRRect(
          slotRRect,
          Paint()..color = Colors.black.withValues(alpha: 0.35),
        );
        canvas.drawRRect(
          slotRRect,
          Paint()
            ..color = Colors.orange.withValues(alpha: 0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5,
        );

        // Draw lock emoji centered in slot
        if (_lockPainter != null) {
          final slotCenter = Offset(
            slotRRect.outerRect.center.dx - _lockPainter!.width / 2,
            slotRRect.outerRect.center.dy - _lockPainter!.height / 2,
          );
          _lockPainter!.paint(canvas, slotCenter);
        }

        // Draw small "AD" label below lock
        final adPainter = TextPainter(
          text: TextSpan(
            text: 'AD',
            style: TextStyle(
              color: Colors.orange.withValues(alpha: 0.8),
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        adPainter.layout();
        adPainter.paint(
          canvas,
          Offset(
            slotRRect.outerRect.center.dx - adPainter.width / 2,
            slotRRect.outerRect.bottom - adPainter.height - 2,
          ),
        );
      } else {
        // Normal Slot Face
        canvas.drawRRect(
          slotRRect,
          Paint()..color = const Color(0xFFFFFDD0).withValues(alpha: 0.15),
        );
        // Slot Border
        canvas.drawRRect(slotRRect, slotBorderPaint);
      }
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    // Check if the locked 7th slot was tapped
    if (is7thSlotLocked && maxSlots > 0) {
      final lastSlotIndex = maxSlots - 1;
      if (lastSlotIndex < _slotRRects.length) {
        final slotRect = _slotRRects[lastSlotIndex].outerRect;
        if (slotRect.contains(event.localPosition.toOffset())) {
          onLockedSlotTapped?.call();
          return;
        }
      }
    }
  }

  /// Unlocks the 7th slot for the current level.
  void unlock7thSlot() {
    is7thSlotLocked = false;
  }

  /// Locks the 7th slot (called on level reset).
  void lock7thSlot() {
    is7thSlotLocked = true;
  }

  bool canAddTile() {
    if (tilesInTray.length >= effectiveSlots) {
      _triggerFullTrayShake();
      return false;
    }
    return true;
  }

  void _triggerFullTrayShake() {
    add(
      MoveEffect.by(
        Vector2(8, 0),
        EffectController(duration: 0.05, reverseDuration: 0.05, repeatCount: 4),
      ),
    );
  }

  void addTile(TileComponent tile) {
    if (canAddTile()) {
      tile.isInTray = true;

      // Group same types together
      int insertIndex = tilesInTray.length;
      for (int i = 0; i < tilesInTray.length; i++) {
        if (tilesInTray[i].data.type == tile.data.type) {
          insertIndex = i + 1;
        }
      }

      tilesInTray.insert(insertIndex, tile);
      rearrangeTiles(onComplete: _checkForMatches);

      // Safety net: check matches after a delay in case animation callback fails
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!_isMatching && isMounted) {
          _checkForMatches();
        }
      });

      // Warning shake if getting full
      if (tilesInTray.length >= 5) {
        _triggerWarningShake();
      }
    }
  }

  void _triggerWarningShake() {
    add(
      MoveEffect.by(
        Vector2(5, 0),
        EffectController(duration: 0.05, reverseDuration: 0.05, repeatCount: 5),
      ),
    );
  }

  void rearrangeTiles({VoidCallback? onComplete}) {
    int completedCount = 0;
    if (tilesInTray.isEmpty) {
      onComplete?.call();
      return;
    }

    final totalTiles = tilesInTray.length;

    for (int i = 0; i < tilesInTray.length; i++) {
      final tile = tilesInTray[i];
      final targetX = padding + i * (traySlotSize + padding);
      final targetY = padding;

      final trayTopLeft = position - Vector2(size.x / 2, 0);
      final targetPos = trayTopLeft + Vector2(targetX, targetY);

      tile.priority = 100 + i;

      // Cancel any existing movement effects so they don't fight each other
      tile.removeAll(tile.children.whereType<MoveEffect>());

      tile.add(
        MoveToEffect(
          targetPos,
          EffectController(duration: 0.2, curve: Curves.easeOutQuad),
          onComplete: () {
            completedCount++;
            if (completedCount >= totalTiles) {
              onComplete?.call();
            }
          },
        ),
      );

      // Shrink the physical rendering boundaries of the tile to fit the slot perfectly
      tile.add(
        SizeEffect.to(
          Vector2.all(traySlotSize),
          EffectController(duration: 0.2, curve: Curves.easeOutQuad),
        ),
      );
    }
  }

  void _checkForMatches() {
    if (_isMatching) return;

    final Map<dynamic, List<TileComponent>> groups = {};
    for (var tile in tilesInTray) {
      groups.putIfAbsent(tile.data.type, () => []).add(tile);
    }

    for (var type in groups.keys) {
      if (groups[type]!.length >= 3) {
        final match = groups[type]!.take(3).toList();
        _isMatching = true;

        // Handle Combo Logic

        _removeMatch(match);
        return;
      }
    }

    // No matches found. Check if the tray is full.
    game.checkLoseCondition();
  }

  void _removeMatch(List<TileComponent> match) {
    for (var tile in match) {
      tilesInTray.remove(tile);
    }

    final provider = game.buildContext != null
        ? Provider.of<GameProvider>(game.buildContext!, listen: false)
        : null;
    AudioManager.playTileMatch(provider?.isSoundEnabled ?? true);

    // Spawn particles for each matched tile
    for (var tile in match) {
      game.spawnMatchParticles(tile.position + tile.size / 2);
    }

    // Animate tile removal
    int removedCount = 0;
    for (var tile in match) {
      // White flash effect
      tile.add(
        ColorEffect(
          Colors.white,
          EffectController(duration: 0.1, reverseDuration: 0.1),
          opacityFrom: 0,
          opacityTo: 0.8,
        ),
      );

      // Scale down to zero and remove
      tile.add(
        ScaleEffect.to(
          Vector2.zero(),
          EffectController(
            duration: 0.3,
            startDelay: 0.1,
            curve: Curves.easeInBack,
          ),
          onComplete: () {
            tile.removeFromParent();
            removedCount++;
            if (removedCount >= match.length) {
              _isMatching = false;
              game.checkWinCondition();
              rearrangeTiles(onComplete: _checkForMatches);
            }
          },
        ),
      );
    }

    // Safety timeout: reset _isMatching after 1 second no matter what
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (_isMatching) {
        _isMatching = false;
        // Force remove any remaining match tiles
        for (var tile in match) {
          if (tile.isMounted) {
            tile.removeFromParent();
          }
        }
        game.checkWinCondition();
        rearrangeTiles(onComplete: _checkForMatches);
      }
    });
  }

  /// Magnet power-up: flies 3 same-type tiles directly into the tray and
  /// immediately triggers a match removal once they all arrive.
  /// This avoids the visual jitter of calling addTile() three times.
  void addMagnetTiles(List<TileComponent> tiles) {
    if (tiles.length != 3) return;

    // Calculate starting slot index (append after existing tiles)
    final startSlotIndex = tilesInTray.length;

    for (int i = 0; i < tiles.length; i++) {
      final tile = tiles[i];
      tile.isInTray = true;
      tilesInTray.add(tile);

      final slotIndex = startSlotIndex + i;
      final targetX = padding + slotIndex * (traySlotSize + padding);
      final targetY = padding;
      final trayTopLeft = position - Vector2(size.x / 2, 0);
      final targetPos = trayTopLeft + Vector2(targetX, targetY);

      tile.priority = 100 + slotIndex;

      // Cancel any existing movement effects
      tile.removeAll(tile.children.whereType<MoveEffect>());

      // Fly tile into the tray slot
      tile.add(
        MoveToEffect(
          targetPos,
          EffectController(duration: 0.35, curve: Curves.easeInOutCubic),
        ),
      );

      // Shrink to fit tray slot
      tile.add(
        SizeEffect.to(
          Vector2.all(traySlotSize),
          EffectController(duration: 0.35, curve: Curves.easeInOutCubic),
        ),
      );
    }

    // After the flight animation completes, trigger instant match removal
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!isMounted) return;
      _removeMatch(tiles);
    });
  }
}
