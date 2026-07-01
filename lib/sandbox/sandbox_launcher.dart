import 'package:flutter/material.dart';
import 'sandbox_dungeon_screen.dart';

class SandboxLauncher {
  static void openSandbox(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SandboxDungeonScreen(),
      ),
    );
  }
}
