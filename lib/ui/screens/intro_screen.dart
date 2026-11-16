import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';

import '../../core/constants/typography.dart';
import '../../models/character_class.dart';
import '../../models/hero_character.dart';
import '../../models/hero_portraits.dart';
import '../../states/player_state.dart';
import '../../states/save_state.dart';
import '../menu/menu_style.dart';
import '../menu/vector_backdrop.dart';

/// New game: choose a path (warrior, assassin, sorcerer), pick one of its
/// likenesses, name the hero and begin.
class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  static const _paths = [PersonalityClassType.warrior, PersonalityClassType.assassin, PersonalityClassType.sorcerer];

  final _nameController = TextEditingController();
  PersonalityClassType _path = PersonalityClassType.warrior;
  final Map<PersonalityClassType, int> _look = {for (final p in _paths) p: 0};
  String? _nameError;

  PlayerState get _player => Get.find<PlayerState>();
  int get _heroIndex => _player.heroes.indexWhere((h) => h.characterClass.type == _path);
  HeroCharacter get _hero => _player.heroes[_heroIndex];
  String get _portrait => HeroPortraits.of(_path)[_look[_path]!];
  Color get _accent => ChronicleStyle.pathColor(_path);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _commence() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Scribe a name to begin.');
      return;
    }
    Get.find<SaveState>().beginChronicle(name: name, heroIndex: _heroIndex, portrait: _portrait);
  }

  @override
  Widget build(BuildContext context) {
    final save = Get.find<SaveState>();
    return Scaffold(
      backgroundColor: ChronicleStyle.ink,
      body: VectorBackdrop(
        accent: _accent,
        intensity: 0.7,
        child: SafeArea(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  children: [
                    _header(save),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _sectionLabel('CHOOSE THY PATH'),
                            _pathPicker(),
                            const SizedBox(height: 8),
                            _showcase(),
                            const SizedBox(height: 4),
                            _sectionLabel('CHOOSE THY LIKENESS'),
                            _likenessPicker(),
                            const SizedBox(height: 18),
                            _stats(),
                            const SizedBox(height: 22),
                            _sectionLabel('SCRIBE THY NAME'),
                            _nameField(),
                            const SizedBox(height: 22),
                            _commenceButton(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(SaveState save) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Back to menu',
              icon: const Icon(Icons.arrow_back, color: ChronicleStyle.bone),
              onPressed: save.cancelNewGame,
            ),
            Expanded(
              child: Text('NEW CHRONICLE',
                  textAlign: TextAlign.center,
                  style: VitruvianTypography.serifTitle(fontSize: 18, color: ChronicleStyle.bone).copyWith(letterSpacing: 3)),
            ),
            Obx(() => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: ChronicleStyle.gold.withValues(alpha: 0.5)),
                  ),
                  child: Text('SLOT ${(save.activeSlot.value ?? 0) + 1}',
                      style: VitruvianTypography.monospaceData(fontSize: 10, color: ChronicleStyle.gold)),
                )),
          ],
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 10),
        child: Row(
          children: [
            Expanded(child: Container(height: 1, color: ChronicleStyle.gold.withValues(alpha: 0.2))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(text,
                  style: VitruvianTypography.monospaceData(fontSize: 11, color: ChronicleStyle.gold).copyWith(letterSpacing: 2.5)),
            ),
            Expanded(child: Container(height: 1, color: ChronicleStyle.gold.withValues(alpha: 0.2))),
          ],
        ),
      );

  Widget _pathPicker() => Row(
        children: [
          for (final (i, p) in _paths.indexed) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(child: _PathCard(type: p, selected: p == _path, onTap: () => setState(() => _path = p))),
          ],
        ],
      );

  /// The chosen hero in full, head to feet, with the path's name and vitals beside it.
  Widget _showcase() {
    final v = _hero.vitals;
    return SizedBox(
      height: 400,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Glowing pedestal ellipse under the figure.
                Positioned(
                  bottom: 0,
                  child: AnimatedContainer(
                    duration: 400.ms,
                    width: 190,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.elliptical(95, 20)),
                      gradient: RadialGradient(colors: [_accent.withValues(alpha: 0.55), _accent.withValues(alpha: 0)]),
                      border: Border.all(color: _accent.withValues(alpha: 0.6)),
                    ),
                  ),
                ),
                // The portraits keep clear space above the head and stand on a common
                // baseline, so `contain` always shows the whole figure.
                Positioned.fill(
                  bottom: 14,
                  child: AnimatedSwitcher(
                    duration: 350.ms,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: Tween(begin: 0.96, end: 1.0).animate(anim), child: child),
                    ),
                    // Fill the area so `bottomCenter` stands the feet on the pedestal
                    // (the switcher would otherwise centre the image).
                    child: SizedBox.expand(
                      key: ValueKey(_portrait),
                      child: Image.asset(
                        _portrait,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, _, _) => Icon(ChronicleStyle.pathIcon(_path), size: 96, color: _accent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(ChronicleStyle.pathIcon(_path), color: _accent, size: 22),
                const SizedBox(height: 8),
                Text(ChronicleStyle.pathName(_path).toUpperCase(),
                    style: VitruvianTypography.serifTitle(fontSize: 18, color: ChronicleStyle.bone).copyWith(letterSpacing: 3)),
                const SizedBox(height: 6),
                Text(ChronicleStyle.pathTagline(_path),
                    style: VitruvianTypography.serifBody(fontSize: 12, color: ChronicleStyle.muted).copyWith(height: 1.35)),
                const SizedBox(height: 16),
                Container(height: 1, color: _accent.withValues(alpha: 0.35)),
                const SizedBox(height: 12),
                _vital('HEALTH', v.maxHp),
                _vital('STAMINA', v.maxStamina),
                _vital('MANA', v.maxMana),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _likenessPicker() {
    final looks = HeroPortraits.of(_path);
    return Row(
      children: [
        for (final (i, asset) in looks.indexed) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _LikenessCard(
              asset: asset,
              accent: _accent,
              selected: _look[_path] == i,
              label: 'LIKENESS ${['I', 'II', 'III'][i]}',
              onTap: () => setState(() => _look[_path] = i),
            ),
          ),
        ],
      ],
    );
  }

  Widget _stats() {
    final a = _hero.attributes;
    final entries = [
      ('STR', a.strength, 20),
      ('DEX', a.dexterity, 20),
      ('INT', a.intelligence, 20),
      ('CON', a.constitution, 20),
      ('INS', a.insight, 20),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: _accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          for (final (label, value, max) in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                      width: 38,
                      child: Text(label, style: VitruvianTypography.monospaceData(fontSize: 11, color: ChronicleStyle.muted))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Stack(
                        children: [
                          Container(height: 6, color: Colors.white.withValues(alpha: 0.08)),
                          AnimatedFractionallySizedBox(
                            duration: 400.ms,
                            curve: Curves.easeOutCubic,
                            widthFactor: (value / max).clamp(0.0, 1.0),
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.7), _accent]),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 30,
                    child: Text('$value',
                        textAlign: TextAlign.right,
                        style: VitruvianTypography.monospaceData(fontSize: 12, color: ChronicleStyle.bone)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _vital(String label, int value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            SizedBox(
              width: 34,
              child: Text('$value', style: VitruvianTypography.serifTitle(fontSize: 17, color: ChronicleStyle.bone)),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: VitruvianTypography.monospaceData(fontSize: 9, color: ChronicleStyle.muted).copyWith(letterSpacing: 1.5)),
          ],
        ),
      );

  Widget _nameField() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              color: Colors.white.withValues(alpha: 0.05),
              border: Border.all(color: (_nameError != null ? ChronicleStyle.crimson : ChronicleStyle.gold).withValues(alpha: 0.45)),
            ),
            alignment: Alignment.center,
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.center,
              cursorColor: ChronicleStyle.gold,
              textCapitalization: TextCapitalization.words,
              maxLength: 24,
              onChanged: (_) {
                if (_nameError != null) setState(() => _nameError = null);
              },
              onSubmitted: (_) => _commence(),
              style: VitruvianTypography.serifTitle(fontSize: 18, color: ChronicleStyle.bone),
              decoration: InputDecoration(
                border: InputBorder.none,
                counterText: '',
                hintText: 'Thy name…',
                hintStyle: VitruvianTypography.serifBody(fontSize: 16, color: ChronicleStyle.faint),
              ),
            ),
          ),
          if (_nameError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(_nameError!,
                  textAlign: TextAlign.center,
                  style: VitruvianTypography.serifBody(fontSize: 13, color: ChronicleStyle.crimson)),
            ),
        ],
      );

  Widget _commenceButton() => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: _commence,
          child: AnimatedContainer(
            duration: 400.ms,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(colors: [Color.lerp(_accent, Colors.white, 0.15)!, _accent]),
              boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.45), blurRadius: 24, spreadRadius: -6)],
            ),
            child: Text('COMMENCE CHRONICLE',
                style: VitruvianTypography.serifTitle(fontSize: 15, color: Colors.white).copyWith(letterSpacing: 2.5)),
          ),
        ),
      );
}

class _PathCard extends StatelessWidget {
  final PersonalityClassType type;
  final bool selected;
  final VoidCallback onTap;

  const _PathCard({required this.type, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = ChronicleStyle.pathColor(type);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected ? c.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: selected ? c : Colors.white.withValues(alpha: 0.1), width: selected ? 1.5 : 1),
          boxShadow: selected ? [BoxShadow(color: c.withValues(alpha: 0.35), blurRadius: 18, spreadRadius: -6)] : null,
        ),
        child: Column(
          children: [
            Icon(ChronicleStyle.pathIcon(type), color: selected ? c : ChronicleStyle.muted, size: 22),
            const SizedBox(height: 6),
            Text(ChronicleStyle.pathName(type).toUpperCase(),
                style: VitruvianTypography.serifTitle(fontSize: 11, color: selected ? ChronicleStyle.bone : ChronicleStyle.muted)
                    .copyWith(letterSpacing: 1.5)),
          ],
        ),
      ),
    );
  }
}

class _LikenessCard extends StatelessWidget {
  final String asset;
  final Color accent;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _LikenessCard({
    required this.asset,
    required this.accent,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 250.ms,
          height: 168,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              colors: [accent.withValues(alpha: selected ? 0.45 : 0.15), Colors.white.withValues(alpha: 0.03)],
            ),
            border: Border.all(color: selected ? accent : Colors.white.withValues(alpha: 0.1), width: selected ? 1.6 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // The whole figure, head to feet.
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
                child: Image.asset(
                  asset,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
              if (selected)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ).animate().scale(duration: 200.ms),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
