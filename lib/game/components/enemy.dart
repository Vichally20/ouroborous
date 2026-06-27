import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../states/navigation_state.dart';
import '../city_game.dart';

class Enemy extends PositionComponent with HasGameReference<CityGame> {
  final double speed;

  Enemy({required super.position, this.speed = 100.0}) : super(size: Vector2(48, 48));

  @override
  void update(double dt) {
    super.update(dt);
    final navState = Get.find<NavigationState>();
    if (navState.currentMode.value != MapViewMode.tactical) return;

    position.y += speed * dt;
    if (position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final navState = Get.find<NavigationState>();
    if (navState.currentMode.value != MapViewMode.tactical) return;

    final paint = Paint()..color = const Color(0xFF8B0000);
    canvas.drawRect(size.toRect(), paint);
  }
}
