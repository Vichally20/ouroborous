import 'package:flame/components.dart';
import '../../states/navigation_state.dart';
import '../city_game.dart';

class Player extends PositionComponent with HasGameReference<CityGame> {
  Player() : super(size: Vector2(64, 64));

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    position = Vector2(100, game.size.y - 150);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameController.navigationState.currentMode != MapViewMode.tactical) return;
  }
}
