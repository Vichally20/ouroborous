import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/typography.dart';

/// What a toast is about; sets its accent colour and icon.
enum ToastTone { info, success, danger, loot }

/// The game's one toast: a compact rounded card at the top, at most 380 wide,
/// gone in about two seconds. A new toast replaces the one on screen instead of
/// stacking under it. Does nothing when no screen is up (headless tests).
void showToast(
  String title,
  String message, {
  ToastTone tone = ToastTone.info,
  IconData? icon,
  Duration duration = const Duration(milliseconds: 2200),
}) {
  if (Get.overlayContext == null) return;
  // Close only the toast on screen, then show this one. (Get.closeAllSnackbars()
  // clears its queue a microtask later, which would cancel this new toast too.)
  if (Get.isSnackbarOpen) {
    Get.closeCurrentSnackbar().then((_) => _show(title, message, tone, icon, duration));
  } else {
    _show(title, message, tone, icon, duration);
  }
}

void _show(String title, String message, ToastTone tone, IconData? icon, Duration duration) {

  final accent = switch (tone) {
    ToastTone.info => const Color(0xFFC8A26A),
    ToastTone.success => const Color(0xFF6FBF8E),
    ToastTone.danger => const Color(0xFFE0675C),
    ToastTone.loot => const Color(0xFFE6C27F),
  };
  final glyph = icon ??
      switch (tone) {
        ToastTone.info => Icons.info_outline,
        ToastTone.success => Icons.check_circle_outline,
        ToastTone.danger => Icons.heart_broken_outlined,
        ToastTone.loot => Icons.inventory_2_outlined,
      };

  Get.snackbar(
    title,
    message,
    titleText: title.isEmpty
        ? const SizedBox.shrink()
        : Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: VitruvianTypography.monospaceData(fontSize: 10, color: accent).copyWith(letterSpacing: 1.5)),
    messageText: Text(message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: VitruvianTypography.serifBody(fontSize: 13, color: const Color(0xFFEDE6DA)).copyWith(height: 1.25)),
    icon: Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Icon(glyph, color: accent, size: 18),
    ),
    shouldIconPulse: false,
    snackPosition: SnackPosition.TOP,
    maxWidth: 380,
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    padding: const EdgeInsets.fromLTRB(12, 8, 14, 9),
    borderRadius: 12,
    backgroundColor: const Color(0xF2171319),
    borderColor: accent.withValues(alpha: 0.55),
    borderWidth: 1,
    boxShadows: [BoxShadow(color: Colors.black.withValues(alpha: 0.45), blurRadius: 14, offset: const Offset(0, 4))],
    duration: duration,
    animationDuration: const Duration(milliseconds: 280),
    isDismissible: true,
    dismissDirection: DismissDirection.up,
  );
}
