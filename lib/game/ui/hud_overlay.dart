import 'package:flutter/material.dart';
import '../../states/game_controller.dart';

class HudOverlay extends StatelessWidget {
  final GameController gameController;

  const HudOverlay({super.key, required this.gameController});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: gameController.playerState,
      builder: (context, child) {
        final vitals = gameController.playerState.vitals;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                  ),
                  child: Text(
                    'SANITY: ${vitals.currentSanity}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    border: Border.all(color: Colors.redAccent, width: 2),
                  ),
                  child: Text(
                    'HP: ${vitals.currentHp}/${vitals.maxHp}',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
