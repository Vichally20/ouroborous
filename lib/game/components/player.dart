import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../states/navigation_state.dart';
import '../city_game.dart';

class Player extends PositionComponent with HasGameReference<CityGame> {
  Player() : super(size: Vector2(64, 64));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(game.size.x / 2 - size.x / 2, game.size.y - 120);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final navState = Get.find<NavigationState>();
    if (navState.currentMode.value != MapViewMode.tactical) return;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final navState = Get.find<NavigationState>();
    if (navState.currentMode.value != MapViewMode.tactical) return;

    final paint = Paint()..color = const Color(0xFFE0C8B0);
    canvas.drawRect(size.toRect(), paint);

    final borderPaint = Paint()
      ..color = const Color(0xFFC0A080)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRect(size.toRect(), borderPaint);
  }
}
