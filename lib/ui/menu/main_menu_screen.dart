import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/constants/typography.dart';
import '../../states/save_state.dart';
import '../screens/settings_screen.dart';
import 'menu_style.dart';
import 'vector_backdrop.dart';
import '../widgets/toast.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final save = Get.find<SaveState>();
    return Scaffold(
      backgroundColor: ChronicleStyle.ink,
      body: VectorBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const Spacer(flex: 3),
                    const _Title(),
                    const Spacer(flex: 4),
                    Obx(() {
                      final latest = save.latestSlot;
                      final summary = latest == null ? null : save.slots[latest];
                      final buttons = <Widget>[
                        MenuButton(
                          label: 'NEW GAME',
                          icon: Icons.auto_awesome,
                          primary: true,
                          onTap: () => _newGame(context, save),
                        ),
                        MenuButton(
                          label: 'CONTINUE',
                          icon: Icons.play_arrow_rounded,
                          caption: summary == null ? 'No chronicle yet' : '${summary.heroName} · ${summary.place}',
                          enabled: summary != null,
                          onTap: () => _load(save, latest!),
                        ),
                        MenuButton(
                          label: 'SLOTS',
                          icon: Icons.layers_outlined,
                          caption: '${save.slots.where((s) => s != null).length} of ${SaveState.slotCount} used',
                          onTap: () => showSlotsSheet(context),
                        ),
                        MenuButton(
                          label: 'SETTINGS',
                          icon: Icons.tune,
                          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const _SettingsPage())),
                        ),
                      ];
                      return Column(
                        children: [
                          for (final (i, b) in buttons.indexed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: b.animate().fadeIn(delay: (150 + i * 90).ms, duration: 400.ms).moveY(begin: 12, end: 0),
                            ),
                        ],
                      );
                    }),
                    const Spacer(flex: 2),
                    Text('v1.1 · SCRIBE BRANCH',
                        style: VitruvianTypography.monospaceData(fontSize: 10, color: ChronicleStyle.faint)),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static void _newGame(BuildContext context, SaveState save) {
    final empty = save.firstEmptySlot;
    if (empty != null) {
      save.startNewGame(empty);
    } else {
      showSlotsSheet(context, pickForNewGame: true);
    }
  }

  static Future<void> _load(SaveState save, int slot) async {
    final error = await save.load(slot);
    if (error != null) showToast('COULD NOT LOAD', error);
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 74,
          height: 74,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ChronicleStyle.gold.withValues(alpha: 0.7), width: 1.4),
            gradient: RadialGradient(colors: [ChronicleStyle.crimson.withValues(alpha: 0.35), Colors.transparent]),
          ),
          child: const Icon(Icons.all_inclusive, color: ChronicleStyle.gold, size: 34),
        ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
        const SizedBox(height: 18),
        Text(
          'VITRUVIAN',
          textAlign: TextAlign.center,
          style: VitruvianTypography.serifTitle(fontSize: 40, color: ChronicleStyle.bone).copyWith(letterSpacing: 8, height: 1),
        ),
        Text(
          'SHADOW',
          textAlign: TextAlign.center,
          style: VitruvianTypography.serifTitle(fontSize: 40, color: ChronicleStyle.gold).copyWith(letterSpacing: 14, height: 1.1),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 28, height: 1, color: ChronicleStyle.gold.withValues(alpha: 0.5)),
            const SizedBox(width: 10),
            Text('AN OUROBOROS CHRONICLE',
                style: VitruvianTypography.monospaceData(fontSize: 10, color: ChronicleStyle.muted).copyWith(letterSpacing: 2.5)),
            const SizedBox(width: 10),
            Container(width: 28, height: 1, color: ChronicleStyle.gold.withValues(alpha: 0.5)),
          ],
        ),
      ],
    ).animate().fadeIn(duration: 700.ms);
  }
}

/// A glassy pill button: gold-edged, with an optional caption under the label.
class MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? caption;
  final bool primary;
  final bool enabled;
  final VoidCallback onTap;

  const MenuButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.caption,
    this.primary = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final fg = !enabled ? ChronicleStyle.faint : (primary ? ChronicleStyle.ink : ChronicleStyle.bone);
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: enabled ? onTap : null,
          child: Ink(
            height: caption == null ? 54 : 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: primary
                  ? const LinearGradient(colors: [Color(0xFFE6C27F), Color(0xFFC08A3E)])
                  : const LinearGradient(colors: [Color(0xD91A1424), Color(0xB3120E1A)]),
              border: Border.all(color: primary ? Colors.transparent : ChronicleStyle.gold.withValues(alpha: 0.35)),
              boxShadow: primary
                  ? [BoxShadow(color: ChronicleStyle.gold.withValues(alpha: 0.35), blurRadius: 24, spreadRadius: -4)]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                Icon(icon, color: fg, size: 20),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: VitruvianTypography.serifTitle(fontSize: 16, color: fg).copyWith(letterSpacing: 2.5)),
                      if (caption != null)
                        Text(caption!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: VitruvianTypography.serifBody(fontSize: 12, color: primary ? ChronicleStyle.ink : ChronicleStyle.muted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: fg.withValues(alpha: 0.6), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The three save slots. With [pickForNewGame] the player is choosing one to overwrite.
void showSlotsSheet(BuildContext context, {bool pickForNewGame = false}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF110E16),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (_) => SafeArea(child: _SlotsSheet(pickForNewGame: pickForNewGame)),
  );
}

class _SlotsSheet extends StatefulWidget {
  final bool pickForNewGame;
  const _SlotsSheet({required this.pickForNewGame});

  @override
  State<_SlotsSheet> createState() => _SlotsSheetState();
}

class _SlotsSheetState extends State<_SlotsSheet> {
  final save = Get.find<SaveState>();

  /// Slot waiting for a second tap (delete, or overwrite with a new game).
  int? _confirm;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Obx(() {
        save.slots.length;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: ChronicleStyle.faint, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.pickForNewGame ? 'CHOOSE A SLOT TO OVERWRITE' : 'SAVE SLOTS',
                style: VitruvianTypography.serifTitle(fontSize: 18, color: ChronicleStyle.bone).copyWith(letterSpacing: 2)),
            const SizedBox(height: 4),
            Text(
              widget.pickForNewGame
                  ? 'Every slot holds a chronicle. A new game replaces the one you pick.'
                  : 'Your game saves itself as you play.',
              style: VitruvianTypography.serifBody(fontSize: 13, color: ChronicleStyle.muted),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < SaveState.slotCount; i++) ...[
              _slot(i, save.slots[i]),
              const SizedBox(height: 10),
            ],
          ],
        );
      }),
    );
  }

  Widget _slot(int i, SaveSlotSummary? s) {
    final confirming = _confirm == i;
    final Widget action;
    if (s == null) {
      action = _SlotAction(label: 'NEW GAME', onTap: () => _begin(i));
    } else if (widget.pickForNewGame) {
      action = _SlotAction(
        label: confirming ? 'CONFIRM' : 'OVERWRITE',
        danger: true,
        onTap: () => confirming ? _begin(i) : setState(() => _confirm = i),
      );
    } else {
      action = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _SlotAction(label: 'LOAD', primary: true, onTap: () => _load(i)),
          const SizedBox(height: 6),
          _SlotAction(
            label: confirming ? 'CONFIRM' : 'DELETE',
            danger: true,
            onTap: () async {
              if (!confirming) return setState(() => _confirm = i);
              await save.deleteSlot(i);
              setState(() => _confirm = null);
            },
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: (s == null ? ChronicleStyle.faint : ChronicleStyle.pathColor(s.classType)).withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: RadialGradient(colors: [
                (s == null ? ChronicleStyle.faint : ChronicleStyle.pathColor(s.classType)).withValues(alpha: 0.45),
                Colors.transparent,
              ]),
            ),
            clipBehavior: Clip.antiAlias,
            child: s == null
                ? const Icon(Icons.add, color: ChronicleStyle.faint)
                : Image.asset(s.portrait,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                    errorBuilder: (_, _, _) => Icon(ChronicleStyle.pathIcon(s.classType), color: ChronicleStyle.bone)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SLOT ${i + 1}',
                    style: VitruvianTypography.monospaceData(fontSize: 10, color: ChronicleStyle.gold).copyWith(letterSpacing: 2)),
                const SizedBox(height: 2),
                Text(s == null ? 'Empty' : s.heroName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: VitruvianTypography.serifTitle(fontSize: 16, color: s == null ? ChronicleStyle.muted : ChronicleStyle.bone)),
                if (s != null) ...[
                  Text('${ChronicleStyle.pathName(s.classType)} · Level ${s.level}',
                      style: VitruvianTypography.serifBody(fontSize: 12, color: ChronicleStyle.muted)),
                  Text('${s.place} · ${_ago(s.savedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: VitruvianTypography.serifBody(fontSize: 12, color: ChronicleStyle.faint)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }

  void _begin(int slot) {
    Navigator.of(context).pop();
    save.startNewGame(slot);
  }

  Future<void> _load(int slot) async {
    Navigator.of(context).pop();
    final error = await save.load(slot);
    if (error != null) showToast('COULD NOT LOAD', error);
  }

  static String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inHours < 1) return '${d.inMinutes} min ago';
    if (d.inDays < 1) return '${d.inHours} h ago';
    if (d.inDays < 30) return '${d.inDays} d ago';
    return '${t.day}/${t.month}/${t.year}';
  }
}

class _SlotAction extends StatelessWidget {
  final String label;
  final bool primary;
  final bool danger;
  final VoidCallback onTap;

  const _SlotAction({required this.label, required this.onTap, this.primary = false, this.danger = false});

  @override
  Widget build(BuildContext context) {
    final color = danger ? ChronicleStyle.crimson : ChronicleStyle.gold;
    return SizedBox(
      height: 34,
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: primary ? ChronicleStyle.gold : Colors.transparent,
          foregroundColor: primary ? ChronicleStyle.ink : color,
          side: BorderSide(color: color.withValues(alpha: primary ? 0 : 0.7)),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: onTap,
        child: Text(label, style: VitruvianTypography.monospaceData(fontSize: 11, color: primary ? ChronicleStyle.ink : color)),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF0C0A08),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0C0A08),
          elevation: 0,
          title: Text('SETTINGS', style: VitruvianTypography.serifTitle(fontSize: 18, color: ChronicleStyle.bone)),
          centerTitle: true,
        ),
        body: const SettingsScreen(),
      );
}
