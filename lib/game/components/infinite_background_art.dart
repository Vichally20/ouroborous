import 'package:flame/components.dart';
import '../../states/navigation_state.dart';
import '../city_game.dart';

class InfiniteBackgroundArt extends Component with HasGameReference<CityGame> {
  @override
  Future<void> onLoad() async {
    await super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (game.gameController.navigationState.currentMode != MapViewMode.tactical) return;
    // Scrolling logic
  }
}
