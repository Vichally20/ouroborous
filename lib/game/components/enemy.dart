import 'package:flame/components.dart';
import '../../states/navigation_state.dart';
import '../city_game.dart';

class Enemy extends PositionComponent with HasGameReference<CityGame> {
  final double speed;

  Enemy({required super.position, this.speed = 150})
      : super(size: Vector2(48, 48));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameController.navigationState.currentMode != MapViewMode.tactical) return;

    position.x -= speed * dt;
    if (position.x < -size.x) {
      removeFromParent();
    }
  }
}
