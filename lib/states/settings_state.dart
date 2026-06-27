import 'package:get/get.dart';

enum TextSpeedOption { slow, normal, fast, instant }

class SettingsState extends GetxController {
  final masterVolume = 85.0.obs;
  final textSpeed = TextSpeedOption.fast.obs;
  final screenShake = true.obs;
  final cloudSync = true.obs;

  void setMasterVolume(double value) {
    masterVolume.value = value;
  }

  void setTextSpeed(TextSpeedOption speed) {
    textSpeed.value = speed;
  }

  void toggleScreenShake() {
    screenShake.value = !screenShake.value;
  }

  void toggleCloudSync() {
    cloudSync.value = !cloudSync.value;
  }

  void wipeSaveData() {
    masterVolume.value = 80.0;
    textSpeed.value = TextSpeedOption.normal;
    screenShake.value = true;
    cloudSync.value = false;
  }

  String get textSpeedLabel {
    switch (textSpeed.value) {
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
