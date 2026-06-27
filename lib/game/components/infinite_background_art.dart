import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../states/navigation_state.dart';
import '../city_game.dart';

class InfiniteBackgroundArt extends Component with HasGameReference<CityGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final navState = Get.find<NavigationState>();
    if (navState.currentMode.value != MapViewMode.tactical) return;

    final paint = Paint()..color = const Color(0xFF1E1C18);
    canvas.drawRect(Rect.fromLTWH(0, 0, game.size.x, game.size.y), paint);

    final gridPaint = Paint()
      ..color = const Color(0xFF2E2820)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const gridSize = 64.0;
    for (double x = 0; x < game.size.x; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, game.size.y), gridPaint);
    }
    for (double y = 0; y < game.size.y; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(game.size.x, y), gridPaint);
    }
  }
}
