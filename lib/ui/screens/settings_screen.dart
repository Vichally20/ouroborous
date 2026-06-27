import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/settings_state.dart';
import '../widgets/etched_container.dart';
import '../widgets/manuscript_controls.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsState = Get.find<SettingsState>();

    return Obx(() {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Embossed Leather Manuscript Cover Header Banner
            Container(
              height: 140,
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0A08),
                border: Border.all(color: const Color(0xFF1E1A16), width: 1.0),
                gradient: const RadialGradient(
                  center: Alignment.center,
                  radius: 0.8,
                  colors: [Color(0xFF1C1712), Color(0xFF0A0806)],
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Opacity(
                    opacity: 0.18,
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: VitruvianColors.sepiaUmber, width: 3),
                      ),
                      child: const Center(
                        child: Icon(Icons.history_edu, size: 50, color: VitruvianColors.sepiaUmber),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.6),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // AUDIO SECTION
            _buildSectionHeader('AUDIO'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('MASTER VOLUME', style: VitruvianTypography.serifBody(fontSize: 16)),
                Text('${settingsState.masterVolume.value.round()}',
                    style: VitruvianTypography.serifBody(fontSize: 16, color: VitruvianColors.sepiaUmber)),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.0,
                activeTrackColor: VitruvianColors.sepiaUmber,
                inactiveTrackColor: VitruvianColors.etchedHairline,
                thumbShape: const RectangularSliderThumbShape(width: 8, height: 20),
                thumbColor: VitruvianColors.agedBone,
                overlayColor: VitruvianColors.sepiaUmber.withValues(alpha: 0.15),
              ),
              child: Slider(
                value: settingsState.masterVolume.value,
                min: 0,
                max: 100,
                onChanged: settingsState.setMasterVolume,
              ),
            ),
            const SizedBox(height: 32),

            // GAMEPLAY SECTION
            _buildSectionHeader('GAMEPLAY'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TEXT SPEED', style: VitruvianTypography.serifBody(fontSize: 16)),
                Text(settingsState.textSpeedLabel,
                    style: VitruvianTypography.serifBody(fontSize: 16, color: VitruvianColors.sepiaUmber)),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2.0,
                activeTrackColor: VitruvianColors.sepiaUmber,
                inactiveTrackColor: VitruvianColors.etchedHairline,
                thumbShape: const RectangularSliderThumbShape(width: 8, height: 20),
                thumbColor: VitruvianColors.agedBone,
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                value: settingsState.textSpeed.value.index.toDouble(),
                min: 0,
                max: 3,
                divisions: 3,
                onChanged: (val) =>
                    settingsState.setTextSpeed(TextSpeedOption.values[val.round()]),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('SCREEN SHAKE', style: VitruvianTypography.serifBody(fontSize: 16)),
                const DottedHairline(),
                EtchedSwitch(
                  value: settingsState.screenShake.value,
                  onChanged: (_) => settingsState.toggleScreenShake(),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // SYSTEM SECTION
            _buildSectionHeader('SYSTEM'),
            const SizedBox(height: 24),
            Row(
              children: [
                Text('CLOUD SYNC', style: VitruvianTypography.serifBody(fontSize: 16)),
                const DottedHairline(),
                EtchedSwitch(
                  value: settingsState.cloudSync.value,
                  onChanged: (_) => settingsState.toggleCloudSync(),
                ),
              ],
            ),
            const SizedBox(height: 36),

            // WIPE SAVE DATA BUTTON
            InkWell(
              onTap: () => _showWipeDialog(context, settingsState),
              child: EtchedContainer(
                padding: const EdgeInsets.symmetric(vertical: 18),
                borderColor: VitruvianColors.rustBlood,
                backgroundColor: const Color(0xFF100808),
                child: Center(
                  child: Text(
                    'WIPE SAVE DATA',
                    style: VitruvianTypography.serifBody(
                      fontSize: 16,
                      color: const Color(0xFFD8A0A0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),

            // FOOTER INFO
            Center(
              child: Text(
                'VERSION 1.0.4 - SCRIBE BRANCH',
                style: VitruvianTypography.monospaceData(fontSize: 11, color: Colors.white30),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.terminal, size: 16, color: Colors.white24),
                SizedBox(width: 16),
                Icon(Icons.shield_outlined, size: 16, color: Colors.white24),
                SizedBox(width: 16),
                Icon(Icons.menu_book, size: 16, color: Colors.white24),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: VitruvianTypography.serifTitle(
            fontSize: 18,
            color: VitruvianColors.sepiaUmber,
          ),
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: const Color(0xFF2E2820)),
      ],
    );
  }

  void _showWipeDialog(BuildContext context, SettingsState settingsState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VitruvianColors.voidBlack,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(color: VitruvianColors.rustBlood),
        ),
        title: Text('CLINICAL PURGE', style: VitruvianTypography.serifTitle(color: VitruvianColors.rustBlood)),
        content: Text('Are you certain you wish to purge all recorded manuscript progress? This cannot be undone.',
            style: VitruvianTypography.serifBody()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ABORT', style: VitruvianTypography.monospaceData()),
          ),
          TextButton(
            onPressed: () {
              settingsState.wipeSaveData();
              Navigator.pop(context);
            },
            child: Text('PURGE', style: VitruvianTypography.monospaceData(color: VitruvianColors.rustBlood)),
          ),
        ],
      ),
    );
  }
}
