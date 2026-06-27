import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../states/player_state.dart';

class HudOverlay extends StatelessWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final playerState = Get.find<PlayerState>();

    return Obx(() {
      final vitals = playerState.vitals.value;
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
    });
  }
}
