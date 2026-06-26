import 'package:flame/components.dart';
import '../../states/navigation_state.dart';
import '../city_game.dart';

class Projectile extends PositionComponent with HasGameReference<CityGame> {
  final Vector2 velocity;

  Projectile({required super.position, required this.velocity})
      : super(size: Vector2(16, 8));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameController.navigationState.currentMode != MapViewMode.tactical) return;

    position += velocity * dt;
    if (position.x > game.size.x || position.y > game.size.y || position.x < 0 || position.y < 0) {
      removeFromParent();
    }
  }
}
