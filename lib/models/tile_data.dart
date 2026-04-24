class TileData {
  final String id;
  final int type;
  final int layer;
  final double x;
  final double y;

  TileData({
    required this.id,
    required this.type,
    required this.layer,
    required this.x,
    required this.y,
  });

  String get iconAsset => '';

  static const List<String> _tileAssets = [
    // Fruits (1-12)
    'apple.png', 'banana.png', 'strawberry.png', 'pineapple.png',
    'watermelon.png', 'kiwi.png', 'peach.png', 'cherry.png',
    'lemon.png', 'orange.png', 'pear.png', 'blueberry.png',
    // Sweets (13-20)
    'cupcake.png', 'cake.png', 'donut.png', 'cookie.png',
    'chocolate.png', 'candy.png', 'iceCream.png', 'popsicle.png',
    // Food (21-24)
    'pizza.png', 'burger.png', 'hotdog.png', 'fries.png',
    // Nature (25-32)
    'rose.png', 'sunflower.png', 'tulip.png', 'clover.png',
    'cactus.png', 'lightning.png', 'water_drop.png', 'star.png',
  ];

  String? get imagePath {
    if (type < 1 || type > _tileAssets.length) return null;
    return 'tiles/${_tileAssets[type - 1]}';
  }
}
