import 'package:flutter/foundation.dart';

enum TextSpeedOption { slow, normal, fast, instant }

class SettingsState extends ChangeNotifier {
  double masterVolume = 85.0;
  TextSpeedOption textSpeed = TextSpeedOption.fast;
  bool screenShake = true;
  bool cloudSync = true;

  void setMasterVolume(double value) {
    masterVolume = value;
    notifyListeners();
  }

  void setTextSpeed(TextSpeedOption speed) {
    textSpeed = speed;
    notifyListeners();
  }

  void toggleScreenShake() {
    screenShake = !screenShake;
    notifyListeners();
  }

  void toggleCloudSync() {
    cloudSync = !cloudSync;
    notifyListeners();
  }

  void wipeSaveData() {
    // Reset defaults
    masterVolume = 80.0;
    textSpeed = TextSpeedOption.normal;
    screenShake = true;
    cloudSync = false;
    notifyListeners();
  }

  String get textSpeedLabel {
    switch (textSpeed) {
      case TextSpeedOption.slow:
        return 'Slow';
      case TextSpeedOption.normal:
        return 'Normal';
      case TextSpeedOption.fast:
        return 'Fast';
      case TextSpeedOption.instant:
        return 'Instant';
    }
  }
}
