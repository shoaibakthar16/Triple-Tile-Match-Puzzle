import 'dart:math';
import 'package:triple_tile_match_puzzle/models/tile_data.dart';
import 'package:triple_tile_match_puzzle/models/level_config.dart';

class LevelManager {
  static int currentLevel = 1;

  static List<TileData> generateLevel(int level, double spacing) {
    currentLevel = level;
    final config = LevelConfig.getConfig(level);
    final random = Random(level);
    final levelFruits = _getFruitsForLevel(level);
    final numTileTypes = min(config.numTileTypes, levelFruits.length);
    final types = levelFruits.take(numTileTypes).toList();

    List<_TilePos> positions = _getLayoutPositions(level, config, spacing);
    final targetTiles = config.setsOfThree * 3;

    if (positions.length < targetTiles) {
      final basePositions = List<_TilePos>.from(positions);
      for (var pos in basePositions) {
        if (positions.length >= targetTiles) break;
        positions.add(_TilePos(pos.x + 4, pos.y + 4, pos.layer + 1));
      }
    }

    final totalSlots = min((positions.length ~/ 3) * 3, targetTiles);
    final usedPositions = positions.take(totalSlots).toList();

    final List<int> tilePool = [];
    final setsNeeded = totalSlots ~/ 3;
    for (int i = 0; i < setsNeeded; i++) {
      final type = types[i % types.length];
      tilePool.addAll([type, type, type]);
    }
    tilePool.shuffle(random);

    final tiles = <TileData>[];
    for (int i = 0; i < usedPositions.length; i++) {
      final pos = usedPositions[i];
      tiles.add(
        TileData(
          id: 'tile_${pos.layer}_$i',
          type: tilePool[i],
          layer: pos.layer,
          x: pos.x,
          y: pos.y,
        ),
      );
    }
    return tiles;
  }

  static List<_TilePos> _getLayoutPositions(
    int level,
    LevelConfig config,
    double s,
  ) {
    if (level > 50) return _layoutProcedural(level, config, s);
    switch (level) {
      case 1:
        return _layoutSimpleGrid(s);
      case 2:
        return _layoutTwoBlocks(s);
      case 3:
        return _layoutDiamond(s);
      case 4:
        return _layoutButterfly(s);
      case 5:
        return _layoutRing(s);
      case 6:
        return _layoutCross(s);
      case 7:
        return _layoutHourglass(s);
      case 8:
        return _layoutThreeBlocks(s);
      case 9:
        return _layoutConcentric(s);
      case 10:
        return _layoutPyramid(s);
      case 11:
        return _layoutSkull(s);
      case 12:
        return _layoutDenseHeart(s);
      case 13:
        return _layoutBigX(s);
      case 14:
        return _layoutAlienShip(s);
      case 15:
        return _layoutFourBlocks(s);
      case 16:
        return _layoutTwinDiamonds(s);
      case 17:
        return _layoutSunburst(s);
      case 18:
        return _layoutMaze(s);
      case 19:
        return _layoutHollowMountain(s);
      case 20:
        return _layoutAnchor(s);
      case 21:
        return _layoutSmiley(s);
      case 22:
        return _layoutHexagon(s);
      case 23:
        return _layoutDNA(s);
      case 24:
        return _layoutCheckerboard(s);
      case 25:
        return _layoutVault(s);
      case 26:
        return _layoutArrow(s);
      case 27:
        return _layoutCrown(s);
      case 28:
        return _layoutWave(s);
      case 29:
        return _layoutSpiral(s);
      case 30:
        return _layoutCastle(s);
      case 31:
        return _layoutShield(s);
      case 32:
        return _layoutTree(s);
      case 33:
        return _layoutMoon(s);
      case 34:
        return _layoutLightning(s);
      case 35:
        return _layoutTornado(s);
      case 36:
        return _layoutFish(s);
      case 37:
        return _layoutRocket(s);
      case 38:
        return _layoutSword(s);
      case 39:
        return _layoutMushroom(s);
      case 40:
        return _layoutBridge(s);
      case 41:
        return _layoutGate(s);
      case 42:
        return _layoutTower(s);
      case 43:
        return _layoutWindmill(s);
      case 44:
        return _layoutFlower(s);
      case 45:
        return _layoutLantern(s);
      case 46:
        return _layoutCompass(s);
      case 47:
        return _layoutKite(s);
      case 48:
        return _layoutGem(s);
      case 49:
        return _layoutLeaf(s);
      case 50:
        return _layoutInfinity(s);
      default:
        return _layoutSimpleGrid(s);
    }
  }

  // === SHAPES 1-25 ===

  static List<_TilePos> _layoutSimpleGrid(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 4; r++) {
      for (int c = 0; c < 3; c++) {
        p.add(_TilePos(c * s, r * s, 0));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutTwoBlocks(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        p.add(_TilePos(c * s, r * s, 0));
        p.add(_TilePos(c * s, (r + 4) * s, 0));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutDiamond(double s) {
    final p = <_TilePos>[];
    final w = [1, 3, 5, 5, 3, 1];
    for (int r = 0; r < w.length; r++) {
      final ox = (5 - w[r]) / 2.0 * s;
      for (int c = 0; c < w[r]; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
      }
    }
    for (var r in [1, 2, 3]) {
      final ox = (5 - 3) / 2.0 * s;
      for (int c = 0; c < 3; c++) {
        p.add(_TilePos(ox + c * s + 4, (r + 0.5) * s + 4, 1));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutButterfly(double s) {
    final p = <_TilePos>[];
    final m = [
      [1, 0, 0, 0, 1],
      [1, 1, 0, 1, 1],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 1, 0, 1, 1],
      [1, 0, 0, 0, 1],
    ];
    for (int r = 0; r < m.length; r++) {
      for (int c = 0; c < m[r].length; c++) {
        if (m[r][c] >= 1) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    for (int r = 2; r <= 4; r++) {
      for (int c = 1; c <= 3; c++) {
        if (m[r][c] >= 1) {
          p.add(_TilePos(c * s + 5, r * s + 5, 1));
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutRing(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 5; c++) {
        if ((r >= 2 && r <= 3) && (c >= 1 && c <= 3)) {
          continue;
        }
        p.add(_TilePos(c * s, r * s, 0));
      }
    }
    for (var pos in [ [0, 0], [2, 0], [4, 0], [0, 5], [2, 5], [4, 5] ]) {
      p.add(_TilePos(pos[0] * s + 5, pos[1] * s + 5, 1));
    }
    return p;
  }

  static List<_TilePos> _layoutCross(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        if ((r < 2 || r > 3) && (c < 2 || c > 3)) {
          continue;
        }
        p.add(_TilePos(c * s, r * s, 0));
      }
    }
    for (int r = 1; r < 4; r++) {
      for (int c = 1; c < 4; c++) {
        p.add(_TilePos(c * s + 5, r * s + 5, 1));
      }
    }
    p.add(_TilePos(2 * s + 5, 2 * s + 5, 2));
    return p;
  }

  static List<_TilePos> _layoutHourglass(double s) {
    final p = <_TilePos>[];
    final w = [5, 3, 1, 3, 5];
    for (int r = 0; r < w.length; r++) {
      final ox = (5 - w[r]) / 2.0 * s;
      for (int c = 0; c < w[r]; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutThreeBlocks(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 3; c++) {
        p.add(_TilePos(c * s, r * s, 0));
        p.add(_TilePos((c + 4) * s, r * s, 0));
        p.add(_TilePos((c + 2) * s, (r + 3) * s, 0));
      }
    }
    for (int r = 0; r < 2; r++) {
      for (int c = 0; c < 2; c++) {
        p.add(_TilePos(c * s + s * 0.5, r * s + s * 0.5, 1));
        p.add(_TilePos((c + 4) * s + s * 0.5, r * s + s * 0.5, 1));
        p.add(_TilePos((c + 2) * s + s * 0.5, (r + 3) * s + s * 0.5, 1));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutConcentric(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (r == 0 || r == 4 || c == 0 || c == 4) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    for (int r = 1; r < 4; r++) {
      for (int c = 1; c < 4; c++) {
        if (r == 1 || r == 3 || c == 1 || c == 3) {
          p.add(_TilePos(c * s + 4, r * s + 4, 1));
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutPyramid(double s) {
    final p = <_TilePos>[];
    final w0 = [1, 2, 3, 4, 5];
    for (int r = 0; r < w0.length; r++) {
      final ox = (5 - w0[r]) / 2.0 * s;
      for (int c = 0; c < w0[r]; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
      }
    }
    final w1 = [1, 2, 3];
    for (int r = 0; r < w1.length; r++) {
      final ox = (3 - w1[r]) / 2.0 * s + s;
      for (int c = 0; c < w1[r]; c++) {
        p.add(_TilePos(ox + c * s, r * s + s, 1));
      }
    }
    p.add(_TilePos(2 * s, 2 * s, 2));
    return p;
  }

  static List<_TilePos> _layoutSkull(double s) {
    final p = <_TilePos>[];
    final m = [
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 0, 1, 0, 1],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [0, 1, 0, 1, 0],
    ];
    for (int r = 0; r < m.length; r++) {
      for (int c = 0; c < m[r].length; c++) {
        if (m[r][c] == 1) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutDenseHeart(double s) {
    final p = <_TilePos>[];
    final m = [
      [0, 1, 0, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1],
      [0, 1, 1, 1, 0],
      [0, 0, 1, 0, 0],
    ];
    for (int r = 0; r < m.length; r++) {
      for (int c = 0; c < m[r].length; c++) {
        if (m[r][c] == 1) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutBigX(double s) {
    final p = <_TilePos>[];
    for (int i = 0; i < 7; i++) {
      p.add(_TilePos(i * s, i * s, 0));
      p.add(_TilePos((6 - i) * s, i * s, 0));
    }
    for (int i = 1; i < 6; i++) {
      p.add(_TilePos(i * s, i * s, 1));
      p.add(_TilePos((6 - i) * s, i * s, 1));
    }
    return p;
  }

  static List<_TilePos> _layoutAlienShip(double s) {
    final p = <_TilePos>[];
    final m = [
      [0, 0, 1, 0, 0],
      [0, 1, 1, 1, 0],
      [1, 1, 1, 1, 1],
      [1, 0, 1, 0, 1],
    ];
    for (int r = 0; r < m.length; r++) {
      for (int c = 0; c < m[r].length; c++) {
        if (m[r][c] == 1) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    p.add(_TilePos(2 * s, 1 * s, 1));
    return p;
  }

  static List<_TilePos> _layoutFourBlocks(double s) {
    final p = <_TilePos>[];
    for (int br = 0; br < 2; br++) {
      for (int bc = 0; bc < 2; bc++) {
        for (int r = 0; r < 2; r++) {
          for (int c = 0; c < 2; c++) {
            p.add(_TilePos((bc * 4 + c) * s, (br * 4 + r) * s, 0));
          }
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutTwinDiamonds(double s) {
    final p = <_TilePos>[];
    for (var ox in [0.0, 4 * s]) {
      final w = [1, 3, 1];
      for (int r = 0; r < w.length; r++) {
        final dox = (3 - w[r]) / 2.0 * s;
        for (int c = 0; c < w[r]; c++) {
          p.add(_TilePos(ox + dox + c * s, r * s, 0));
          p.add(_TilePos(ox + dox + c * s, (r + 4) * s, 0));
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutSunburst(double s) {
    final p = <_TilePos>[];
    for (int i = 0; i < 8; i++) {
      double angle = i * pi / 4;
      p.add(_TilePos(3 * s + cos(angle) * 3 * s, 3 * s + sin(angle) * 3 * s, 0));
      p.add(_TilePos(3 * s + cos(angle) * 2 * s, 3 * s + sin(angle) * 2 * s, 0));
    }
    p.add(_TilePos(3 * s, 3 * s, 0));
    p.add(_TilePos(3 * s, 3 * s, 1));
    return p;
  }

  static List<_TilePos> _layoutMaze(double s) {
    final p = <_TilePos>[];
    for (int i = 0; i < 7; i++) {
      p.add(_TilePos(i * s, 0, 0));
      p.add(_TilePos(i * s, 6 * s, 0));
      p.add(_TilePos(0, i * s, 0));
      p.add(_TilePos(6 * s, i * s, 0));
    }
    for (int i = 2; i < 5; i++) {
      p.add(_TilePos(i * s, 2 * s, 0));
      p.add(_TilePos(2 * s, i * s, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutHollowMountain(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 7; r++) {
      final ox = (7 - (r + 1)) / 2.0 * s;
      for (int c = 0; c < r + 1; c++) {
        if (c == 0 || c == r || r == 6) {
          p.add(_TilePos(ox + c * s, r * s, 0));
          p.add(_TilePos(ox + c * s, r * s, 1));
        }
      }
    }
    for (var i = 0; i < 3; i++) {
      p.add(_TilePos(3 * s, 4 * s, i));
    }
    return p;
  }

  static List<_TilePos> _layoutAnchor(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 6; r++) {
      p.add(_TilePos(3 * s, r * s, 0));
    }
    for (int c = 1; c <= 5; c++) {
      p.add(_TilePos(c * s, 1 * s, 0));
    }
    for (var pos in [[2, 5], [4, 5], [1, 4], [5, 4], [1, 3], [5, 3]]) {
      p.add(_TilePos(pos[0] * s, pos[1] * s, 0));
    }
    p.add(_TilePos(3 * s, 1 * s, 1));
    p.add(_TilePos(3 * s, 1 * s, 2));
    return p;
  }

  static List<_TilePos> _layoutSmiley(double s) {
    final p = <_TilePos>[];
    for (int c = 2; c <= 4; c++) {
      p.add(_TilePos(c * s, 0, 0));
      p.add(_TilePos(c * s, 6 * s, 0));
    }
    for (int r = 2; r <= 4; r++) {
      p.add(_TilePos(0, r * s, 0));
      p.add(_TilePos(6 * s, r * s, 0));
    }
    for (var pos in [[1, 1], [5, 1], [1, 5], [5, 5]]) {
      p.add(_TilePos(pos[0].toDouble() * s, pos[1].toDouble() * s, 0));
    }
    for (var pos in [[2, 2], [4, 2], [2, 4], [3, 4.5], [4, 4]]) {
      p.add(_TilePos(pos[0].toDouble() * s, pos[1].toDouble() * s, 1));
    }
    return p;
  }

  static List<_TilePos> _layoutHexagon(double s) {
    final p = <_TilePos>[];
    final w = [3, 4, 5, 6, 5, 4, 3];
    for (int r = 0; r < w.length; r++) {
      double ox = (6 - w[r]) / 2.0 * s;
      for (int c = 0; c < w[r]; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
        if (r > 1 && r < 5 && c > 0 && c < w[r] - 1) {
          p.add(_TilePos(ox + c * s, r * s, 1));
          if (r == 3 && c == 2) {
            p.add(_TilePos(ox + c * s, r * s, 2));
          }
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutDNA(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 7; r++) {
      double shift = (r % 4 < 2) ? 0 : 2 * s;
      p.add(_TilePos(1 * s + shift, r * s, 0));
      p.add(_TilePos(3 * s - shift, r * s, 0));
      if (r % 2 == 0) {
        p.add(_TilePos(2 * s, r * s, 0));
        p.add(_TilePos(2 * s, r * s, 1));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutCheckerboard(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 6; r++) {
      for (int c = 0; c < 6; c++) {
        if ((r + c) % 2 == 0) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutVault(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        if (r == 0 || r == 6 || c == 0 || c == 6 || (r == 3 && c == 3)) {
          p.add(_TilePos(c * s, r * s, 0));
          if (r == 3 && c == 3) {
            p.add(_TilePos(c * s, r * s, 1));
          }
        }
      }
    }
    return p;
  }

  // === SHAPES 26-50 ===

  static List<_TilePos> _layoutArrow(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 4; r++) {
      double ox = (4 - (r + 1)) / 2.0 * s;
      for (int c = 0; c < r + 1; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
      }
    }
    for (int r = 4; r < 7; r++) {
      p.add(_TilePos(1.5 * s, r * s, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutCrown(double s) {
    final p = <_TilePos>[];
    for (int c = 0; c < 5; c++) {
      p.add(_TilePos(c * s, 4 * s, 0));
    }
    for (int c = 0; c < 5; c += 2) {
      p.add(_TilePos(c * s, 2 * s, 0));
      p.add(_TilePos(c * s, 3 * s, 0));
    }
    p.add(_TilePos(s, 3 * s, 0));
    p.add(_TilePos(3 * s, 3 * s, 0));
    return p;
  }

  static List<_TilePos> _layoutWave(double s) {
    final p = <_TilePos>[];
    for (int c = 0; c < 8; c++) {
      double y = sin(c * pi / 4) * 2 * s + 3 * s;
      p.add(_TilePos(c * s, y, 0));
      p.add(_TilePos(c * s, y + s, 1));
    }
    return p;
  }

  static List<_TilePos> _layoutSpiral(double s) {
    final p = <_TilePos>[];
    for (int i = 0; i < 20; i++) {
      double r = i * s * 0.3;
      double a = i * 0.5;
      p.add(_TilePos(4 * s + cos(a) * r, 4 * s + sin(a) * r, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutCastle(double s) {
    final p = <_TilePos>[];
    for (int c = 0; c < 7; c += 2) {
      p.add(_TilePos(c * s, 0, 0));
    }
    for (int r = 1; r < 4; r++) {
      for (int c = 0; c < 7; c++) {
        p.add(_TilePos(c * s, r * s, 0));
      }
    }
    for (int c = 0; c < 7; c++) {
      if (c < 2 || c > 4) {
        p.add(_TilePos(c * s, 4 * s, 0));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutShield(double s) {
    final p = <_TilePos>[];
    final w = [5, 5, 5, 5, 3, 1];
    for (int r = 0; r < w.length; r++) {
      double ox = (5 - w[r]) / 2.0 * s;
      for (int c = 0; c < w[r]; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
      }
    }
    for (int r = 1; r < 4; r++) {
      for (int c = 1; c < 4; c++) {
        p.add(_TilePos(c * s, r * s, 1));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutTree(double s) {
    final p = <_TilePos>[];
    final w = [1, 3, 5, 3, 5, 7];
    for (int r = 0; r < w.length; r++) {
      double ox = (7 - w[r]) / 2.0 * s;
      for (int c = 0; c < w[r]; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
      }
    }
    for (int r = 6; r < 8; r++) {
      for (int c = 2; c <= 4; c++) {
        p.add(_TilePos(c * s, r * s, 0));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutMoon(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        double dr = r - 3.0, dc = c - 3.0;
        if (dr * dr + dc * dc <= 10 && dr * dr + (c - 4.5) * (c - 4.5) > 5) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    return p;
  }

  static List<_TilePos> _layoutLightning(double s) {
    final p = <_TilePos>[];
    final coords = [[2, 0], [3, 0], [1, 1], [2, 1], [0, 2], [1, 2], [2, 2], [3, 2], [1, 3], [2, 3], [0, 4], [1, 4]];
    for (var c in coords) {
      p.add(_TilePos(c[0].toDouble() * s, c[1].toDouble() * s, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutTornado(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 7; r++) {
      int width = 7 - r;
      double ox = r / 2.0 * s;
      for (int c = 0; c < width; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutFish(double s) {
    final p = <_TilePos>[];
    final m = [[0, 1, 1, 0, 0], [1, 1, 1, 1, 0], [1, 1, 1, 1, 1], [1, 1, 1, 1, 0], [0, 1, 1, 0, 0]];
    for (int r = 0; r < 5; r++) {
      for (int c = 0; c < 5; c++) {
        if (m[r][c] == 1) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    p.add(_TilePos(5 * s, 1 * s, 0));
    p.add(_TilePos(5 * s, 3 * s, 0));
    return p;
  }

  static List<_TilePos> _layoutRocket(double s) {
    final p = <_TilePos>[];
    p.add(_TilePos(2 * s, 0, 0));
    for (int r = 1; r < 5; r++) {
      for (int c = 1; c < 4; c++) {
        p.add(_TilePos(c * s, r * s, 0));
      }
    }
    p.add(_TilePos(0, 5 * s, 0));
    p.add(_TilePos(4 * s, 5 * s, 0));
    return p;
  }

  static List<_TilePos> _layoutSword(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 5; r++) {
      p.add(_TilePos(2 * s, r * s, 0));
    }
    for (int c = 0; c < 5; c++) {
      p.add(_TilePos(c * s, 5 * s, 0));
    }
    p.add(_TilePos(2 * s, 6 * s, 0));
    return p;
  }

  static List<_TilePos> _layoutMushroom(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 3; r++) {
      double ox = (3 - (r + 3)) / 2.0 * s + s;
      for (int c = 0; c < r + 3; c++) {
        p.add(_TilePos(ox + c * s, r * s, 0));
      }
    }
    for (int r = 3; r < 6; r++) {
      p.add(_TilePos(2 * s, r * s, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutBridge(double s) {
    final p = <_TilePos>[];
    for (int c = 0; c < 7; c++) {
      p.add(_TilePos(c * s, 2 * s, 0));
    }
    for (int r = 3; r < 6; r++) {
      p.add(_TilePos(0, r * s, 0));
      p.add(_TilePos(6 * s, r * s, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutGate(double s) {
    final p = <_TilePos>[];
    for (int i = 0; i < 5; i++) {
        p.add(_TilePos(0, i.toDouble() * s, 0));
        p.add(_TilePos(4 * s, i.toDouble() * s, 0));
        p.add(_TilePos(i.toDouble() * s, 0, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutTower(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 6; r++) {
        p.add(_TilePos(s, r.toDouble() * s, 0));
        p.add(_TilePos(2 * s, r.toDouble() * s, 0));
    }
    p.add(_TilePos(0.5 * s, 0, 1));
    p.add(_TilePos(2.5 * s, 0, 1));
    return p;
  }

  static List<_TilePos> _layoutWindmill(double s) {
    final p = <_TilePos>[];
    for (int i = 0; i < 4; i++) {
        p.add(_TilePos(2 * s, i.toDouble() * s, 0));
        p.add(_TilePos(i.toDouble() * s, 2 * s, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutFlower(double s) {
    final p = <_TilePos>[];
    p.add(_TilePos(2 * s, 2 * s, 1));
    for (int i = 0; i < 6; i++) {
        double a = i * 2 * pi / 6;
        p.add(_TilePos(2 * s + cos(a) * 1.5 * s, 2 * s + sin(a) * 1.5 * s, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutLantern(double s) {
    final p = <_TilePos>[];
    for (int r = 1; r < 5; r++) {
      for (int c = 1; c < 4; c++) {
        p.add(_TilePos(c * s, r * s, 0));
      }
    }
    p.add(_TilePos(2 * s, 0, 0));
    p.add(_TilePos(2 * s, 5 * s, 0));
    return p;
  }

  static List<_TilePos> _layoutCompass(double s) {
    final p = <_TilePos>[];
    p.add(_TilePos(3 * s, 0, 0));
    p.add(_TilePos(3 * s, 6 * s, 0));
    p.add(_TilePos(0, 3 * s, 0));
    p.add(_TilePos(6 * s, 3 * s, 0));
    for (int r = 2; r < 5; r++) {
      for (int c = 2; c < 5; c++) {
        p.add(_TilePos(c * s, r * s, 0));
      }
    }
    return p;
  }

  static List<_TilePos> _layoutKite(double s) {
    final p = <_TilePos>[];
    final w = [1, 3, 5, 3, 1];
    for (int r = 0; r < w.length; r++) {
        double ox = (5 - w[r]) / 2.0 * s;
        for (int c = 0; c < w[r]; c++) {
          p.add(_TilePos(ox+c*s, r*s, 0));
        }
    }
    for (int i = 5; i < 8; i++) {
      p.add(_TilePos(2*s + (i%2==0?0.5*s:-0.5*s), i.toDouble()*s, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutGem(double s) {
    final p = <_TilePos>[];
    final w = [3, 5, 3, 1];
    for (int r = 0; r < w.length; r++) {
        double ox = (5 - w[r]) / 2.0 * s;
        for (int c = 0; c < w[r]; c++) {
          p.add(_TilePos(ox+c*s, r*s, 0));
        }
    }
    return p;
  }

  static List<_TilePos> _layoutLeaf(double s) {
    final p = <_TilePos>[];
    for (int r = 0; r < 5; r++) {
        double ox = r * 0.5 * s;
        for (int c = 0; c < 3; c++) {
          p.add(_TilePos(ox + c * s, r * s, 0));
        }
    }
    return p;
  }

  static List<_TilePos> _layoutInfinity(double s) {
    final p = <_TilePos>[];
    for (int i = 0; i < 16; i++) {
        double t = i * 2 * pi / 16;
        double x = cos(t) * 3 * s / (1 + sin(t) * sin(t));
        double y = sin(t) * cos(t) * 3 * s / (1 + sin(t) * sin(t));
        p.add(_TilePos(3 * s + x, 3 * s + y, 0));
    }
    return p;
  }

  static List<_TilePos> _layoutProcedural(int level, LevelConfig config, double s) {
    final random = Random(level);
    final p = <_TilePos>[];
    int w = 5 + (level % 4);
    int h = 6 + (level % 3);
    for (int r = 0; r < h; r++) {
      for (int c = 0; c < w; c++) {
        if (random.nextDouble() < 0.6) {
          p.add(_TilePos(c * s, r * s, 0));
        }
      }
    }
    for (int layer = 1; layer < config.maxLayers; layer++) {
      double density = 0.5 - (layer * 0.1);
      for (int r = 1; r < h - 1; r++) {
        for (int c = 1; c < w - 1; c++) {
          if (random.nextDouble() < density) {
             p.add(_TilePos(c * s + s * 0.2, r * s + s * 0.2, layer));
          }
        }
      }
    }
    return p;
  }

  static List<int> _getFruitsForLevel(int level) {
    if (level == 1) {
      final list = List.generate(12, (i) => i + 1);
      list.shuffle(Random(level));
      return list;
    }
    final list = List.generate(32, (i) => i + 1);
    list.shuffle(Random(level * 100));
    return list;
  }
}

class _TilePos {
  final double x;
  final double y;
  final int layer;
  _TilePos(this.x, this.y, this.layer);
}
