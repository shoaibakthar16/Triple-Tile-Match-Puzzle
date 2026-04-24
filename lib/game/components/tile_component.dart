import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'package:triple_tile_match_puzzle/models/tile_data.dart';
import 'package:triple_tile_match_puzzle/game/game.dart';

class TileComponent extends PositionComponent
    with TapCallbacks, HasPaint, HasGameReference<TileMatchGame> {
  final TileData data;
  bool isBlocked = false;
  bool isInTray = false;
  Vector2? boardPosition;
  int? boardPriority;
  Sprite? _sprite;

  // Cached rendering objects to avoid GC pressure in render()
  Rect _rect = Rect.zero;
  RRect _rrect = RRect.zero;
  RRect _shadowRRect = RRect.zero;
  RRect _depthRRect = RRect.zero;
  Rect _hitbox = Rect.zero;
  Shader? _glossShader;
  TextPainter? _textPainter;
  Offset _textOffset = Offset.zero;

  Rect get hitbox => _hitbox;

  // Cached Paint objects for performance optimization
  static final _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.3)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

  static final _depthPaint = Paint()
    ..color = const Color(0xFFB0C4DE)
    ..style = PaintingStyle.fill;

  static final _mainPaint = Paint()..style = PaintingStyle.fill;

  static final _highlightPaint = Paint()
    ..color = Colors.white.withValues(alpha: 0.8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final _borderPaint = Paint()
    ..color = Colors.grey.withValues(alpha: 0.2)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5;

  static final _glossPaint = Paint()..style = PaintingStyle.fill;

  TileComponent({required this.data, double? initialTileSize})
    : super(
        position: Vector2(data.x, data.y),
        size: Vector2.all(initialTileSize ?? 60.0),
        priority: data.layer,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    size = Vector2.all(game.tileSize);
    boardPosition = position.clone();
    boardPriority = priority;

    if (data.imagePath != null) {
      final path = data.imagePath!;
      _sprite = await game.loadSprite(path);
    }

    _updateCache();

    // Entrance animation: fall from above into position
    final finalPos = position.clone();
    position.y -= 400; // Start above screen
    opacity = 0;

    add(OpacityEffect.to(1.0, EffectController(duration: 0.3)));
    add(
      MoveEffect.to(
        finalPos,
        EffectController(
          duration: 0.5 + (data.id.hashCode % 5) / 10,
          curve: Curves.bounceOut,
        ),
      ),
    );
  }

  void moveTo(Vector2 targetPosition, {VoidCallback? onComplete}) {
    // Clear ALL existing effects to prevent conflicts
    children.whereType<MoveEffect>().forEach((e) => e.removeFromParent());
    children.whereType<ScaleEffect>().forEach((e) => e.removeFromParent());
    children.whereType<OpacityEffect>().forEach((e) => e.removeFromParent());

    // When moving back to tray or during shuffle, we need a standard size
    add(
      ScaleEffect.to(
        Vector2.all(1.1),
        EffectController(duration: 0.1, reverseDuration: 0.2),
      ),
    );

    add(
      SizeEffect.to(
        Vector2.all(game.tileSize),
        EffectController(duration: 0.3, curve: Curves.easeOutCubic),
        onComplete: _updateCache,
      ),
    );

    add(
      MoveEffect.to(
        targetPosition,
        EffectController(duration: 0.3, curve: Curves.easeOutCubic),
        onComplete: onComplete,
      ),
    );
  }

  void returnToBoard(
    Vector2 targetPosition,
    int targetPriority, {
    VoidCallback? onComplete,
  }) {
    // Specialized "whoosh" animation for revive
    children.whereType<MoveEffect>().forEach((e) => e.removeFromParent());
    children.whereType<ScaleEffect>().forEach((e) => e.removeFromParent());

    // Slight scale up during transition
    add(
      ScaleEffect.to(
        Vector2.all(1.2),
        EffectController(duration: 0.15, reverseDuration: 0.25),
      ),
    );

    add(
      SizeEffect.to(
        Vector2.all(game.tileSize),
        EffectController(duration: 0.4, curve: Curves.elasticOut),
      ),
    );

    add(
      MoveEffect.to(
        targetPosition,
        EffectController(duration: 0.5, curve: Curves.easeOutBack),
        onComplete: () {
          priority = targetPriority;
          onComplete?.call();
        },
      ),
    );
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _updateCache();
  }

  void _updateCache() {
    _rect = Rect.fromLTWH(0, 0, size.x, size.y);
    _rrect = RRect.fromRectAndRadius(_rect, const Radius.circular(14));
    _shadowRRect = _rrect.shift(const Offset(3, 6));
    _depthRRect = _rrect.shift(const Offset(0, 5));

    final pos = boardPosition ?? position;
    _hitbox = Rect.fromLTWH(
      pos.x,
      pos.y,
      size.x,
      size.y,
    ).deflate(size.x * 0.15);

    _glossShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.center,
      colors: [Colors.white.withValues(alpha: 0.4), Colors.transparent],
    ).createShader(_rect);

    if (_sprite == null) {
      _textPainter = TextPainter(
        text: TextSpan(
          text: data.iconAsset,
          style: TextStyle(
            fontSize: size.x * 0.7,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(1, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      _textPainter!.layout();
      _textOffset = Offset(
        (size.x - _textPainter!.width) / 2,
        (size.y - _textPainter!.height) / 2 - 1,
      );
    }
  }

  @override
  void render(Canvas canvas) {
    if (_rrect == RRect.zero) return;

    // Deep Shadow
    canvas.drawRRect(_shadowRRect, _shadowPaint);

    // 3D Depth (Sides) - Light blue like reference
    canvas.drawRRect(_depthRRect, _depthPaint);

    // Main Body (Face) - Clean white
    _mainPaint.color = isBlocked ? Colors.grey.shade300 : Colors.white;
    canvas.drawRRect(_rrect, _mainPaint);

    // Top highlight bevel
    canvas.drawRRect(_rrect, _highlightPaint);

    // Subtle border
    canvas.drawRRect(_rrect, _borderPaint);

    // Icon/Emoji - Large and centered
    if (_sprite != null) {
      // Draw the crisp AI generated PNG sprite
      final spriteSize = size.x * 0.75;
      _sprite!.render(
        canvas,
        position: Vector2((size.x - spriteSize) / 2, (size.y - spriteSize) / 2),
        size: Vector2.all(spriteSize),
      );
    } else if (_textPainter != null) {
      // Fallback to emoji rendering (cached)
      _textPainter!.paint(canvas, _textOffset);
    }

    // Subtle top gloss
    if (_glossShader != null) {
      _glossPaint.shader = _glossShader;
      canvas.drawRRect(_rrect, _glossPaint);
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (isInTray) return;

    if (game.isHammerMode) {
      game.useHammerOnTile(this);
      // Trigger a rebuild of the screen to remove the hammer overlay
      game.onLevelChanged?.call();
      return;
    }

    if (isBlocked) {
      // Small feedback even if blocked so user knows it's interactive but stuck
      add(
        ScaleEffect.by(
          Vector2.all(0.95),
          EffectController(duration: 0.05, reverseDuration: 0.05),
        ),
      );
      return;
    }

    add(
      ScaleEffect.by(
        Vector2.all(0.9),
        EffectController(duration: 0.05, reverseDuration: 0.05),
      ),
    );

    game.onTileTapped(this);
  }
}
