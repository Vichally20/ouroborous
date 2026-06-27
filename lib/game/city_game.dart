import 'package:flame/game.dart';
import 'package:get/get.dart';
import '../states/game_controller.dart';
import 'components/infinite_background_art.dart';
import 'components/player.dart';

class CityGame extends FlameGame {
  GameController get gameController => Get.find<GameController>();

  CityGame();

  late final Player player;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    await add(InfiniteBackgroundArt());
    player = Player();
    await add(player);
  }
}
