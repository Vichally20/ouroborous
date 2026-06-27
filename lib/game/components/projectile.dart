import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../states/navigation_state.dart';
import '../city_game.dart';

class Projectile extends PositionComponent with HasGameReference<CityGame> {
  final Vector2 velocity;

  Projectile({required super.position, required this.velocity}) : super(size: Vector2(8, 16));

  @override
  void update(double dt) {
    super.update(dt);
    final navState = Get.find<NavigationState>();
    if (navState.currentMode.value != MapViewMode.tactical) return;

    position += velocity * dt;
    if (position.y < -size.y || position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final navState = Get.find<NavigationState>();
    if (navState.currentMode.value != MapViewMode.tactical) return;

    final paint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawRect(size.toRect(), paint);
  }
}
