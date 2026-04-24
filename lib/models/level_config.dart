/// Configuration for each game level difficulty.
/// 5 tiers: Tutorial (1-5), Easy (6-15), Medium (16-30), Hard (31-50), Expert (51+)
class LevelConfig {
  final int level;
  final int numTileTypes;
  final int setsOfThree;
  final int maxLayers;

  const LevelConfig({
    required this.level,
    required this.numTileTypes,
    required this.setsOfThree,
    required this.maxLayers,
  });

  /// Progressive difficulty curve with 5 tiers:
  ///
  /// Tutorial (L1-5):  3-4 types, 3-5 sets (9-15 tiles), 1 layer
  /// Easy (L6-15):     5-7 types, 6-10 sets (18-30 tiles), 2 layers
  /// Medium (L16-30):  8-10 types, 11-16 sets (33-48 tiles), 3 layers
  /// Hard (L31-50):    11-13 types, 17-22 sets (51-66 tiles), 3-4 layers
  /// Expert (L51+):    14-16 types, 23-30 sets (69-90 tiles), 4 layers
  static LevelConfig getConfig(int level) {
    int tileTypes;
    int sets;
    int layers;

    if (level <= 5) {
      // Tutorial: very gentle
      tileTypes = (2 + level).clamp(3, 5);
      sets = (2 + level).clamp(3, 5);
      layers = 1;
    } else if (level <= 15) {
      // Easy: ramp up tile types and sets
      final progress = level - 5; // 1..10
      tileTypes = (4 + (progress / 2).ceil()).clamp(5, 7);
      sets = (5 + progress).clamp(6, 10);
      layers = 2;
    } else if (level <= 30) {
      // Medium: significant complexity
      final progress = level - 15; // 1..15
      tileTypes = (7 + (progress / 3).ceil()).clamp(8, 10);
      sets = (10 + (progress * 0.4).ceil()).clamp(11, 16);
      layers = 3;
    } else if (level <= 50) {
      // Hard: dense stacking
      final progress = level - 30; // 1..20
      tileTypes = (10 + (progress / 4).ceil()).clamp(11, 13);
      sets = (16 + (progress * 0.3).ceil()).clamp(17, 22);
      layers = progress >= 10 ? 4 : 3;
    } else {
      // Expert / Endless: max complexity, slight growth
      final progress = level - 50; // 1..∞
      tileTypes = (13 + (progress / 5).ceil()).clamp(14, 16);
      sets = (22 + (progress * 0.2).ceil()).clamp(23, 30);
      layers = 4;
    }

    return LevelConfig(
      level: level,
      numTileTypes: tileTypes,
      setsOfThree: sets,
      maxLayers: layers,
    );
  }
}
