import 'package:get/get.dart';

enum TextSpeedOption { slow, normal, fast, instant }

class SettingsState extends GetxController {
  final masterVolume = 85.0.obs;
  final textSpeed = TextSpeedOption.fast.obs;
  final screenShake = true.obs;
  final cloudSync = true.obs;
  final attackDelay = 2.0.obs;

  void setMasterVolume(double value) {
    masterVolume.value = value;
  }

  void setTextSpeed(TextSpeedOption speed) {
    textSpeed.value = speed;
  }

  void setAttackDelay(double value) {
    attackDelay.value = value;
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
    attackDelay.value = 2.0;
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

  String get attackDelayLabel {
    if (attackDelay.value == 0) return 'Instant';
    return '${attackDelay.value.toStringAsFixed(1)}s';
  }
}
