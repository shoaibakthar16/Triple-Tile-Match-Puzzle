import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

class HammerComponent extends PositionComponent with HasPaint {
  final VoidCallback onHit;

  HammerComponent({required Vector2 position, required this.onHit})
    : super(
        position: position,
        size: Vector2(80, 80),
        anchor: Anchor.bottomCenter,
      );

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    // Initial state: rotated back and above the tile
    angle = -pi / 4;
    position.y -= 50;
    position.x += 30;
    opacity = 0;

    // Animation sequence
    add(OpacityEffect.to(1.0, EffectController(duration: 0.1)));

    add(
      RotateEffect.to(
        pi / 6,
        EffectController(duration: 0.2, curve: Curves.easeInQuint),
        onComplete: () {
          onHit();
          // Bounce back and fade out
          add(
            RotateEffect.to(
              -pi / 8,
              EffectController(duration: 0.1, curve: Curves.easeOut),
            ),
          );
          add(
            OpacityEffect.to(
              0,
              EffectController(duration: 0.2, startDelay: 0.1),
              onComplete: () => removeFromParent(),
            ),
          );
        },
      ),
    );

    add(
      MoveEffect.by(
        Vector2(-30, 50),
        EffectController(duration: 0.2, curve: Curves.easeInQuint),
      ),
    );
  }

  @override
  void render(Canvas canvas) {
    // HasPaint mixin provides 'opacity' on the component
    final currentOpacity = opacity;

    // Handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(35, 30, 10, 50),
        const Radius.circular(5),
      ),
      paint..color = const Color(0xFF5D4037).withValues(alpha: currentOpacity),
    );

    // Head
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 10, 40, 25),
        const Radius.circular(4),
      ),
      paint..color = const Color(0xFF757575).withValues(alpha: currentOpacity),
    );

    // Head highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 10, 40, 5),
        const Radius.circular(2),
      ),
      paint..color = Colors.white.withValues(alpha: 0.3 * currentOpacity),
    );
  }
}
