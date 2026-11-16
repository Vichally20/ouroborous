import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/combat_event.dart';
import '../../models/combat_models.dart';
import '../../models/item.dart';
import '../../models/skill.dart';
import '../../states/player_state.dart';
import '../../states/combat_state.dart';
import '../../states/inventory_state.dart';
import '../../states/settings_state.dart';
import '../combat/combat_widgets.dart';
import '../widgets/etched_container.dart';
import '../../states/save_state.dart';
import '../widgets/toast.dart';
import '../../game/story_engine.dart';

/// Turn-based lane combat.
///
/// Layout (top to bottom): top bar (Flee, encounter, log) · turn banner with the
/// initiative ribbon · battlefield (enemy back/front lines, THE LINE, your
/// front/back lines) · HUD (HP/STA lag bars, AP pips, item pouch) · a hand of
/// four skill cards. The bottom navigation is hidden while a fight is on.
class CombatScreen extends StatefulWidget {
  const CombatScreen({super.key});

  @override
  State<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen> with TickerProviderStateMixin {
  static const _beatMs = 560.0;

  final controller = Get.find<CombatController>();

  /// Drives one hit: lean-in (0–120ms), hit-stop + flash (120–190ms),
  /// knockback (190–330ms), settle.
  late final AnimationController _beat =
      AnimationController(vsync: this, duration: Duration(milliseconds: _beatMs.toInt()));
  late final AnimationController _shake =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
  late final Worker _eventWorker;

  CombatEvent? _event;
  int _eventKey = 0;
  DateTime _eventAt = DateTime.fromMillisecondsSinceEpoch(0);

  /// Hand slot the player has readied: 0 = Strike, 1.. = hero skills, -1 = Defend.
  int? _armedSlot;

  @override
  void initState() {
    super.initState();
    _eventWorker = ever(controller.attackEventId, (_) {
      final e = controller.lastCombatEvent.value;
      if (e == null || !mounted) return;
      setState(() {
        _event = e;
        _eventKey++;
        _eventAt = DateTime.now();
      });
      _beat.forward(from: 0);
      if (_motionOn && (e.isCritical || e.targetId == 'player')) {
        _shake.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _eventWorker.dispose();
    _beat.dispose();
    _shake.dispose();
    super.dispose();
  }

  bool get _motionOn {
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shakeSetting = Get.isRegistered<SettingsState>() ? Get.find<SettingsState>().screenShake.value : true;
    return !reduce && shakeSetting;
  }

  bool _isEnemyId(String id) => controller.enemies.any((e) => e.id == id);

  // ─── Hit choreography ───

  Offset _offsetFor(String id) {
    final e = _event;
    if (e == null || !_motionOn || !_beat.isAnimating) return Offset.zero;
    final ms = _beat.value * _beatMs;
    if (id == e.attackerId) {
      final dir = _isEnemyId(id) ? 1.0 : -1.0; // enemies lean down, your side leans up
      final k = ms < 120
          ? Curves.easeIn.transform(ms / 120)
          : ms < 260
              ? 1 - Curves.easeOut.transform((ms - 120) / 140)
              : 0.0;
      return Offset(0, 10 * dir * k);
    }
    if (id == e.targetId && ms >= 190 && ms <= 330) {
      final dir = _isEnemyId(id) ? -1.0 : 1.0; // knocked away from the attacker
      final k = math.sin(math.pi * (ms - 190) / 140);
      return Offset(3 * k, 6 * dir * k);
    }
    return Offset.zero;
  }

  double _flashFor(String id) {
    final e = _event;
    if (e == null || id != e.targetId || !_beat.isAnimating) return 0;
    final ms = _beat.value * _beatMs;
    if (ms < 120) return 0;
    if (ms < 190) return 1; // hit-stop: hold the flash
    return (1 - (ms - 190) / 260).clamp(0.0, 1.0);
  }

  Offset get _shakeOffset {
    if (!_shake.isAnimating) return Offset.zero;
    final t = _shake.value;
    final amp = 4 * (1 - t);
    return Offset(math.sin(t * math.pi * 7) * amp, math.cos(t * math.pi * 5) * amp * 0.5);
  }

  Widget? _popupFor(String id) {
    final e = _event;
    final recent = DateTime.now().difference(_eventAt).inMilliseconds < 1200;
    if (e != null && recent && id == e.targetId && e.totalDamage > 0) {
      return Text(
        '-${e.totalDamage}',
        key: ValueKey('hit_$_eventKey'),
        style: VitruvianTypography.monospaceData(
          fontSize: e.isCritical ? 34 : 26,
          fontWeight: FontWeight.w700,
          color: e.isCritical ? CombatPalette.parchment : CombatPalette.wound,
        ).copyWith(shadows: const [Shadow(color: Colors.black, offset: Offset(0, 2))]),
      )
          .animate(delay: 120.ms)
          .scaleXY(begin: 1.45, end: 1.0, duration: 140.ms, curve: Curves.easeOutBack)
          .then()
          .moveY(begin: 0, end: -16, duration: 700.ms, curve: Curves.easeOut)
          .fadeOut(delay: 350.ms, duration: 350.ms);
    }
    final text = controller.damagePopups[id];
    if (text == null) return null;
    final negative = text.contains('-');
    return Text(
      text,
      key: ValueKey('pop_${id}_$text'),
      style: VitruvianTypography.monospaceData(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: negative ? CombatPalette.wound : CombatPalette.verdigris,
      ).copyWith(shadows: const [Shadow(color: Colors.black, offset: Offset(0, 1))]),
    ).animate().fadeIn(duration: 120.ms).moveY(begin: 4, end: -6, duration: 600.ms);
  }

  String _classPortrait() => Get.find<PlayerState>().activeHero.portrait;

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CombatPalette.ground,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge([_beat, _shake]),
          builder: (context, _) => Transform.translate(
            offset: _shakeOffset,
            child: Obx(() => _buildBody(context)),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isPlayerTurn = controller.isPlayerTurn.value;
    final enemies = controller.enemies;
    final isVictory = enemies.isNotEmpty && enemies.every((e) => e.isDead.value);
    final isDefeat = controller.playerHp.value <= 0;
    final armed = isPlayerTurn && !isVictory && !isDefeat ? _armedSlot : null;

    return Stack(
      children: [
        Column(
          children: [
            _buildTopBar(context),
            _buildTurnBanner(isPlayerTurn),
            Expanded(child: _buildBattlefield(armed)),
            _buildHud(context, isPlayerTurn, armed),
          ],
        ),
        _buildSkillPopupBanner(controller),
        if (isDefeat) _buildDefeatOverlay(controller),
        if (isVictory) _buildVictoryOverlay(controller),
      ],
    );
  }

  // ─── Top bar: Flee · encounter · log ───

  Widget _buildTopBar(BuildContext context) {
    final id = controller.currentEncounterId;
    final title = controller.isSandbox.value
        ? 'PROVING GROUNDS'
        : (id != null ? (controller.encounters[id]?['title'] as String? ?? 'COMBAT') : 'COMBAT').toUpperCase();
    return Container(
      height: 46,
      color: CombatPalette.chrome,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Flee',
            icon: const Icon(Icons.flag_outlined, color: CombatPalette.sepia, size: 22),
            onPressed: () => _confirmFlee(context),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: VitruvianTypography.serifTitle(fontSize: 17, color: CombatPalette.bone).copyWith(letterSpacing: 1.2),
            ),
          ),
          IconButton(
            tooltip: 'Combat log',
            icon: const Icon(Icons.history_edu, color: CombatPalette.sepia, size: 22),
            onPressed: () => _showLog(context),
          ),
        ],
      ),
    );
  }

  void _confirmFlee(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CombatPalette.raised,
      shape: const RoundedRectangleBorder(side: BorderSide(color: CombatPalette.hairlineStrong)),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('FLEE THE FIGHT?', style: VitruvianTypography.serifTitle(fontSize: 18, color: CombatPalette.parchment)),
              const SizedBox(height: 8),
              Text(
                  controller.isSandbox.value
                      ? 'You escape with the wounds you have. This fight gives no reward.'
                      : 'You escape with the wounds you have, and drop a tenth of the crowns you carry. '
                          'Crowns banked at the Counting House are safe.',
                  style: VitruvianTypography.serifBody(fontSize: 14, color: CombatPalette.bone)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CombatPalette.ash,
                        side: const BorderSide(color: CombatPalette.hairlineStrong),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('STAY'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CombatPalette.wound,
                        side: const BorderSide(color: CombatPalette.rust),
                        shape: const RoundedRectangleBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.escapeCombat();
                      },
                      child: const Text('FLEE'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CombatPalette.raised,
      shape: const RoundedRectangleBorder(side: BorderSide(color: CombatPalette.hairlineStrong)),
      builder: (ctx) => SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: _buildPostCombatLogReview(controller))),
    );
  }

  // ─── Turn banner + initiative ribbon ───

  Widget _buildTurnBanner(bool isPlayerTurn) {
    final actor = controller.currentActorId.value;
    String label;
    if (isPlayerTurn) {
      label = 'YOUR TURN · R${controller.round.value}';
    } else {
      final enemy = controller.enemies.firstWhereOrNull((e) => e.id == actor);
      final ally = controller.allies.firstWhereOrNull((a) => a.id == actor);
      label = '${(enemy?.name ?? ally?.name ?? 'THE FOE').toUpperCase()} ACTS';
    }
    final enemyActing = !isPlayerTurn && _isEnemyId(actor ?? '');

    final slots = <OrderSlot>[];
    for (final id in controller.turnOrder) {
      if (id == 'player') {
        if (controller.playerHp.value > 0) slots.add(OrderSlot(id, _classPortrait()));
        continue;
      }
      final e = controller.enemies.firstWhereOrNull((x) => x.id == id && !x.isDead.value);
      if (e != null) {
        slots.add(OrderSlot(id, e.imageAsset, enemy: true));
        continue;
      }
      final a = controller.allies.firstWhereOrNull((x) => x.id == id && !x.isDead.value);
      if (a != null) slots.add(OrderSlot(id, a.imageAsset));
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: enemyActing ? CombatPalette.defeatWash : CombatPalette.chrome,
        border: Border(bottom: BorderSide(color: enemyActing ? CombatPalette.rust : CombatPalette.hairline)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enemyActing ? CombatPalette.wound : CombatPalette.brass,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            flex: 3,
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: VitruvianTypography.serifTitle(
                fontSize: 15,
                color: enemyActing ? CombatPalette.wound : CombatPalette.parchment,
              ).copyWith(letterSpacing: 1.2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true,
              child: OrderRibbon(slots: slots, currentId: actor),
            ),
          ),
          if (isPlayerTurn) ...[
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: controller.playerAp.value == 0 ? CombatPalette.ground : CombatPalette.bone,
                backgroundColor: controller.playerAp.value == 0 ? CombatPalette.brass : CombatPalette.raised,
                side: const BorderSide(color: CombatPalette.hairlineStrong),
                shape: const RoundedRectangleBorder(),
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 10),
              ),
              onPressed: () {
                setState(() => _armedSlot = null);
                controller.endPlayerTurn();
              },
              child: Text('END TURN', style: VitruvianTypography.monospaceData(fontSize: 11)),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Battlefield ───

  Widget _buildBattlefield(int? armed) {
    final living = controller.enemies.where((e) => !e.isDead.value).toList();
    return Container(
      color: CombatPalette.sunk,
      child: Column(
        children: [
          Expanded(flex: 5, child: _enemyLane('ENEMY BACK LINE', living.where((e) => e.lane.value == 'back').toList(), armed, 0.86)),
          Expanded(flex: 6, child: _enemyLane('ENEMY FRONT LINE', living.where((e) => e.lane.value == 'front').toList(), armed, 1.0)),
          SizedBox(
            height: 14,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(height: 1, color: CombatPalette.sepia),
                Container(
                  color: CombatPalette.sunk,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('THE LINE',
                      style: VitruvianTypography.serifTitle(fontSize: 11, color: CombatPalette.sepia).copyWith(letterSpacing: 3)),
                ),
              ],
            ),
          ),
          Expanded(flex: 5, child: _playerLane(front: true)),
          Expanded(flex: 5, child: _playerLane(front: false)),
        ],
      ),
    );
  }

  Widget _laneFrame(String label, Widget row, {bool bottomRule = true}) {
    return Container(
      decoration: BoxDecoration(
        border: bottomRule ? const Border(bottom: BorderSide(color: CombatPalette.hairline)) : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 12,
            top: 5,
            child: Text(label, style: VitruvianTypography.monospaceData(fontSize: 10, color: CombatPalette.ash)),
          ),
          Positioned.fill(
            top: 18,
            child: Center(child: FittedBox(fit: BoxFit.scaleDown, child: Padding(padding: const EdgeInsets.all(6), child: row))),
          ),
        ],
      ),
    );
  }

  Widget _enemyLane(String label, List<ActiveEnemy> laneEnemies, int? armed, double scale) {
    final selectedId = controller.selectedEnemyId.value;
    return _laneFrame(
      label,
      Row(
        mainAxisSize: MainAxisSize.min,
        children: laneEnemies.map((enemy) {
          final intent = enemy.intent.value;
          String? targetName;
          if (intent?.kind == IntentKind.attack && intent?.targetId != null && intent!.targetId != 'player') {
            targetName = controller.allies.firstWhereOrNull((a) => a.id == intent.targetId)?.name;
          }
          final reach = controller.skillReaches(armed == null || armed < 0 ? 0 : armed, enemy);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: DragTarget<int>(
              onWillAcceptWithDetails: (d) => _slotTargetsEnemy(d.data) && controller.skillReaches(d.data, enemy),
              onAcceptWithDetails: (d) {
                controller.selectEnemy(enemy.id);
                _cast(d.data);
              },
              builder: (context, candidates, _) => CombatantCard(
                name: enemy.name,
                image: enemy.imageAsset,
                hp: enemy.hp.value,
                maxHp: enemy.maxHp,
                statuses: [
                  if (enemy.bleedStacks.value > 0) StatusMark(StatusKind.bleed, enemy.bleedStacks.value),
                  if (enemy.poisonStacks.value > 0) StatusMark(StatusKind.poison, enemy.poisonStacks.value),
                ],
                intent: intent == null ? null : IntentBadge(intent, targetName: targetName),
                selected: selectedId == enemy.id,
                outOfReach: !reach,
                acting: controller.currentActorId.value == enemy.id && !controller.isPlayerTurn.value,
                dropHighlight: candidates.isNotEmpty,
                scale: scale,
                offset: _offsetFor(enemy.id),
                flash: _flashFor(enemy.id),
                popup: _popupFor(enemy.id),
                onTap: () => _tapEnemy(enemy, armed),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _playerLane({required bool front}) {
    final laneName = front ? 'front' : 'back';
    final playerHere = controller.playerLane.value == laneName;
    final laneAllies = controller.allies.where((a) => a.lane.value == laneName && !a.isDead.value).toList();
    final canMove = controller.isPlayerTurn.value && controller.playerAp.value >= 1;

    final children = <Widget>[];
    if (playerHere) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CombatantCard(
          name: controller.playerName.value.split(' ').first,
          image: _classPortrait(),
          hp: controller.playerHp.value,
          maxHp: controller.playerMaxHp.value,
          isPlayer: true,
          statuses: [
            if (controller.isDefending.value) const StatusMark(StatusKind.guard),
            if (controller.playerBleedStacks.value > 0) StatusMark(StatusKind.bleed, controller.playerBleedStacks.value),
            if (controller.playerPoisonStacks.value > 0) StatusMark(StatusKind.poison, controller.playerPoisonStacks.value),
          ],
          acting: controller.isPlayerTurn.value,
          offset: _offsetFor('player'),
          flash: _flashFor('player'),
          popup: _popupFor('player'),
        ),
      ));
    } else {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: _moveSlot(front: front, enabled: canMove),
      ));
    }
    for (final ally in laneAllies) {
      children.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: CombatantCard(
          name: ally.name,
          image: ally.imageAsset,
          hp: ally.hp.value,
          maxHp: ally.maxHp,
          ally: true,
          statuses: [
            if (ally.bleedStacks.value > 0) StatusMark(StatusKind.bleed, ally.bleedStacks.value),
            if (ally.poisonStacks.value > 0) StatusMark(StatusKind.poison, ally.poisonStacks.value),
          ],
          acting: controller.currentActorId.value == ally.id && !controller.isPlayerTurn.value,
          offset: _offsetFor(ally.id),
          flash: _flashFor(ally.id),
          popup: _popupFor(ally.id),
        ),
      ));
    }
    return _laneFrame(front ? 'YOUR FRONT LINE' : 'YOUR BACK LINE', Row(mainAxisSize: MainAxisSize.min, children: children),
        bottomRule: front);
  }

  /// The empty lane is a tappable target that says what moving costs and gives.
  Widget _moveSlot({required bool front, required bool enabled}) {
    final title = front ? 'STEP FORWARD' : 'FALL BACK';
    final payoff = front ? 'reach their back line' : 'back-line foes can\'t reach';
    return Semantics(
      button: true,
      label: '$title, 1 action point, $payoff',
      child: GestureDetector(
        onTap: enabled
            ? () {
                setState(() => _armedSlot = null);
                controller.playerMove();
              }
            : null,
        child: Container(
          width: 112,
          constraints: const BoxConstraints(minHeight: 66),
          decoration: BoxDecoration(
            border: Border.all(color: enabled ? CombatPalette.brass.withValues(alpha: 0.7) : CombatPalette.hairlineStrong),
            color: enabled ? CombatPalette.brass.withValues(alpha: 0.06) : Colors.transparent,
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(front ? Icons.north : Icons.south, size: 16, color: enabled ? CombatPalette.brass : CombatPalette.ash),
              Text(title, style: VitruvianTypography.monospaceData(fontSize: 10, color: enabled ? CombatPalette.parchment : CombatPalette.ash)),
              Text('1 AP · $payoff',
                  textAlign: TextAlign.center,
                  style: VitruvianTypography.monospaceData(fontSize: 9, color: CombatPalette.ash)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Targeting & casting ───

  bool _slotTargetsEnemy(int slot) {
    if (slot < 0) return false;
    final t = controller.skillForSlot(slot).target;
    return t == SkillTarget.singleEnemy || t == SkillTarget.allEnemies;
  }

  void _tapEnemy(ActiveEnemy enemy, int? armed) {
    controller.selectEnemy(enemy.id);
    if (armed != null && _slotTargetsEnemy(armed) && controller.skillReaches(armed, enemy)) {
      _cast(armed);
    }
  }

  void _tapHand(int slot) {
    if (_armedSlot == slot) {
      _cast(slot);
    } else {
      setState(() => _armedSlot = slot);
    }
  }

  void _cast(int slot) {
    setState(() => _armedSlot = null);
    if (slot == -1) {
      controller.playerDefend();
    } else {
      controller.playerAttack(slot);
    }
  }

  // ─── HUD: vitals, AP, pouch, hand ───

  Widget _buildHud(BuildContext context, bool isPlayerTurn, int? armed) {
    final slots = <int>[0, ...List.generate(math.min(2, controller.playerSkills.length), (i) => i + 1), -1];
    final armedCost = armed == null ? 0 : (armed == -1 ? 1 : controller.skillForSlot(armed).apCost);
    final consumables = Get.find<InventoryState>().ledger.where((i) => i.category == ItemCategory.consumable).fold<int>(0, (n, i) => n + i.count);

    return Container(
      decoration: const BoxDecoration(
        color: CombatPalette.chrome,
        border: Border(top: BorderSide(color: CombatPalette.hairline)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _vitalRow('HP', controller.playerHp.value, controller.playerMaxHp.value, CombatPalette.blood, CombatPalette.bloodTrough),
                    const SizedBox(height: 5),
                    _vitalRow('STA', controller.playerStamina.value, controller.playerMaxStamina.value, CombatPalette.stamina, CombatPalette.sunk),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Column(
                children: [
                  ApPips(current: controller.playerAp.value, preview: isPlayerTurn ? armedCost : 0),
                  const SizedBox(height: 4),
                  Text('AP', style: VitruvianTypography.monospaceData(fontSize: 9, color: CombatPalette.sepia)),
                ],
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: 'Item pouch (1 AP)',
                child: InkWell(
                  onTap: isPlayerTurn && controller.playerAp.value > 0 ? () => _showItemsBottomSheet(context, controller) : null,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(border: Border.all(color: CombatPalette.hairlineStrong), color: CombatPalette.raised),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.science_outlined, size: 20,
                            color: isPlayerTurn && controller.playerAp.value > 0 ? CombatPalette.verdigris : CombatPalette.ash),
                        Positioned(
                          right: 2,
                          bottom: 1,
                          child: Text('$consumables', style: VitruvianTypography.monospaceData(fontSize: 9, color: CombatPalette.ash)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(
            height: 26, // leaves room for a readied card to lift 8px without covering the hint
            child: Align(
              alignment: Alignment.topCenter,
              child: Text(
                armed == null
                    ? (isPlayerTurn ? 'Tap a card to ready it' : '')
                    : (armed == -1 || !_slotTargetsEnemy(armed))
                        ? 'Tap again to use it'
                        : 'Tap again or tap an enemy to strike · or drag onto a target',
                style: VitruvianTypography.serifBody(fontSize: 12, color: CombatPalette.ash).copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ),
          Row(
            children: [
              for (final s in slots) ...[
                Expanded(child: _handCard(s, isPlayerTurn: isPlayerTurn, armed: armed == s)),
                if (s != slots.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _vitalRow(String label, int value, int max, Color fill, Color trough) {
    return Row(
      children: [
        SizedBox(width: 26, child: Text(label, style: VitruvianTypography.monospaceData(fontSize: 10, color: CombatPalette.ash))),
        Expanded(child: LagBar(value: value, max: max, fill: fill, trough: trough)),
        SizedBox(
          width: 62,
          child: Text('$value/$max',
              textAlign: TextAlign.right,
              style: VitruvianTypography.monospaceData(fontSize: 12, color: CombatPalette.parchment)),
        ),
      ],
    );
  }

  Widget _handCard(int slot, {required bool isPlayerTurn, required bool armed}) {
    final isDefend = slot == -1;
    final CombatSkill? skill = isDefend ? null : controller.skillForSlot(slot);
    final name = isDefend ? 'Defend' : skill!.name;
    final icon = isDefend ? Icons.shield : skill!.icon;
    final apCost = isDefend ? 1 : skill!.apCost;
    final staCost = isDefend ? 0 : skill!.staminaCost;
    final targetsEnemy = _slotTargetsEnemy(slot);
    final magic = skill?.type == SkillType.magical;

    final target = controller.enemies.firstWhereOrNull((e) => e.id == controller.selectedEnemyId.value && !e.isDead.value);
    final preview = targetsEnemy && target != null ? controller.previewSkillDamage(slot, target) : null;
    final reach = !targetsEnemy || target == null || controller.skillReaches(slot, target);

    String? reason;
    if (isPlayerTurn) {
      if (controller.playerAp.value < apCost) {
        reason = 'NO AP';
      } else if (controller.playerStamina.value < staCost) {
        reason = 'NEEDS $staCost STA';
      } else if (!reach) {
        reason = 'OUT OF REACH';
      }
    }
    final enabled = isPlayerTurn && reason == null;

    String effect;
    if (isDefend) {
      effect = '+${30 + (controller.playerConstitution.value * 1.5).round()} STA';
    } else if (preview != null) {
      effect = preview.$1 == preview.$2 ? '${preview.$1}' : '${preview.$1}–${preview.$2}';
    } else if (skill!.staminaRestore > 0) {
      effect = '+${skill.staminaRestore} STA';
    } else {
      effect = targetsEnemy ? 'PICK A TARGET' : 'SELF';
    }

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutBack,
      height: 94,
      transform: Matrix4.translationValues(0, armed ? -8 : 0, 0),
      padding: const EdgeInsets.fromLTRB(4, 7, 4, 5),
      decoration: BoxDecoration(
        color: CombatPalette.raised,
        border: Border.all(color: armed ? CombatPalette.brass : CombatPalette.hairlineStrong, width: armed ? 1.5 : 1),
        boxShadow: armed ? [BoxShadow(color: CombatPalette.brass.withValues(alpha: 0.4), blurRadius: 10)] : null,
      ),
      child: Opacity(
        opacity: enabled || !isPlayerTurn ? 1 : 0.45,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, size: 24, color: magic ? CombatPalette.lapis : (isDefend ? CombatPalette.brass : CombatPalette.parchment)),
            Text(name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: VitruvianTypography.serifTitle(fontSize: 11, color: CombatPalette.bone).copyWith(height: 1.05)),
            Text(effect,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: VitruvianTypography.monospaceData(fontSize: 10, color: CombatPalette.parchment)),
            Text(
              reason ?? '$apCost AP${staCost > 0 ? ' · $staCost' : ''}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: VitruvianTypography.monospaceData(fontSize: 9, color: reason != null ? CombatPalette.wound : CombatPalette.stamina),
            ),
          ],
        ),
      ),
    );

    final tappable = Semantics(
      button: true,
      enabled: enabled,
      label: '$name, $apCost action point${apCost == 1 ? '' : 's'}, $effect${reason != null ? ', $reason' : ''}',
      child: GestureDetector(onTap: enabled ? () => _tapHand(slot) : null, child: card),
    );

    if (!enabled || !targetsEnemy) return tappable;
    return Draggable<int>(
      data: slot,
      onDragStarted: () => setState(() => _armedSlot = slot),
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(width: 80, child: Opacity(opacity: 0.9, child: card)),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: tappable,
    );
  }

  // Items Selection Bottom Sheet
  void _showItemsBottomSheet(BuildContext context, CombatController controller) {
    final invState = Get.find<InventoryState>();
    final consumables = invState.ledger.where((item) => item.category == ItemCategory.consumable).toList();

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF0E0C0A),
          border: Border(
            top: BorderSide(color: Color(0xFF2A2218), width: 1.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'INVENTORY POTIONS & ELIXIRS',
              style: VitruvianTypography.serifTitle(fontSize: 16, color: Colors.cyanAccent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            if (consumables.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Text(
                  'No usable consumables in inventory.',
                  style: VitruvianTypography.serifBody(
                    fontSize: 14,
                    color: Colors.white24,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            if (consumables.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 220),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: consumables.length,
                  itemBuilder: (context, index) {
                    final item = consumables[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: InkWell(
                        onTap: () {
                          Get.back(); // close sheet
                          controller.useCombatItem(item);
                        },
                        child: EtchedContainer(
                          padding: const EdgeInsets.all(12),
                          borderColor: const Color(0xFF1E3535),
                          backgroundColor: const Color(0xFF0F1B1B),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.name} (x${item.count})',
                                      style: VitruvianTypography.serifTitle(
                                        fontSize: 14,
                                        color: VitruvianColors.agedBone,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.description,
                                      style: VitruvianTypography.serifBody(
                                        fontSize: 12,
                                        color: const Color(0xFF7BA6A6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'USE (1 AP)',
                                style: VitruvianTypography.monospaceData(
                                  fontSize: 11,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E1710),
                foregroundColor: VitruvianColors.agedBone,
                side: const BorderSide(color: Color(0xFF382C1F)),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                'CANCEL',
                style: VitruvianTypography.monospaceData(fontSize: 12),
              ),
              onPressed: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCombatLogReview(CombatController controller) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF100E0C),
        border: Border.all(color: const Color(0xFF3C3224)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFF1E1A16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BATTLE RECAP & LOGS',
                  style: VitruvianTypography.monospaceData(fontSize: 11, color: VitruvianColors.agedBone),
                ),
                Text(
                  '${controller.combatLogs.length} EVENTS',
                  style: VitruvianTypography.monospaceData(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: controller.combatLogs.length,
              itemBuilder: (context, index) {
                final log = controller.combatLogs[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    log,
                    style: VitruvianTypography.monospaceData(
                      fontSize: 12,
                      color: log.contains('CRITICAL') || log.contains('VICTORY')
                          ? const Color(0xFFC89B5D)
                          : log.contains('damage') || log.contains('inflicts') || log.contains('DEFEAT')
                              ? const Color(0xFFD47A7A)
                              : const Color(0xFFA69A8E),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Defeat Overlay Screen
  Widget _buildDefeatOverlay(CombatController controller) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.heart_broken,
              color: VitruvianColors.rustBlood,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              controller.isSandbox.value ? 'PROVING GROUNDS DEFEAT' : 'YOU FELL PAST THE VEIL',
              style: VitruvianTypography.serifTitle(
                fontSize: 26,
                color: VitruvianColors.rustBlood,
              ).copyWith(letterSpacing: 2.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              controller.isSandbox.value
                  ? 'You were overcome in the Sandbox Arena. Refine your loadout and attributes to conquer this wave.'
                  : 'The subterranean shadows of the undercroft consume your essence. The werewolves continue their rhythmic clicking...',
              style: VitruvianTypography.serifBody(
                fontSize: 15,
                color: const Color(0xFF8C7D73),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            _buildPostCombatLogReview(controller),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _DefeatButton(
                    label: controller.isSandbox.value ? 'RETRY WAVE' : 'RETRY CONFLICT',
                    icon: Icons.replay,
                    fill: const Color(0xFF3E1212),
                    edge: const Color(0xFFB0413E),
                    onTap: controller.retryCombat,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DefeatButton(
                    label: controller.isSandbox.value
                        ? 'RETURN TO SETUP'
                        : (controller.currentDefeatNodeId.value != null ? 'CARRY ON' : 'RETREAT TO SANCTUARY'),
                    icon: controller.isSandbox.value ? Icons.arrow_back : Icons.restore,
                    fill: const Color(0xFF151310),
                    edge: VitruvianColors.goldLeaf,
                    onTap: () => _retreat(controller),
                  ),
                ),
              ],
            ),
            if (!controller.isSandbox.value && controller.currentDefeatNodeId.value == null) ...[
              const SizedBox(height: 10),
              Text(
                'Retreating returns you to your last saved checkpoint.',
                textAlign: TextAlign.center,
                style: VitruvianTypography.serifBody(fontSize: 12, color: const Color(0xFF8C7D73)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Sandbox: back to wave setup. Story: reload the last save (the moment before
  /// this fight), so the defeat and its 1 HP are not carried forward.
  Future<void> _retreat(CombatController controller) async {
    if (controller.isSandbox.value) {
      controller.escapeCombat();
      return;
    }
    // This fight's story carries on after a loss: go to that scene instead.
    final defeatNode = controller.currentDefeatNodeId.value;
    if (defeatNode != null) {
      controller.finishCombatDefeat();
      Get.find<StoryEngine>().goToNode(defeatNode);
      return;
    }
    final save = Get.isRegistered<SaveState>() ? Get.find<SaveState>() : null;
    final error = save == null ? 'There is no saved checkpoint for this game.' : await save.restoreCheckpoint();
    if (error != null) {
      controller.finishCombatDefeat();
      showToast('NO CHECKPOINT', error, tone: ToastTone.danger);
    } else {
      showToast('CHECKPOINT RESTORED', 'You wake where you last rested, before the fight.');
    }
  }

  // Victory Overlay Screen
  Widget _buildVictoryOverlay(CombatController controller) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.95),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.stars,
              color: Color(0xFFC89B5D),
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              controller.isSandbox.value ? 'WAVE CONQUERED' : 'THE FOE VANQUISHED',
              style: VitruvianTypography.serifTitle(
                fontSize: 26,
                color: const Color(0xFFC89B5D),
              ).copyWith(letterSpacing: 2.0),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              controller.isSandbox.value
                  ? 'You stand victorious in the Proving Grounds. Prepare your vitals for the next trial.'
                  : 'The lupine monsters dissolve into the ancient stone floor. Silence returns to the scriptorium chamber. Your blades drip with black bile.',
              style: VitruvianTypography.serifBody(
                fontSize: 15,
                color: const Color(0xFF8C7D73),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF3A4E3A)),
                color: const Color(0xFF132213),
              ),
              child: Text(
                controller.isSandbox.value ? 'ARENA REWARD: VITALS RESTORED' : '+50 XP REWARDED',
                style: VitruvianTypography.monospaceData(
                  fontSize: 12,
                  color: Colors.greenAccent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildPostCombatLogReview(controller),
            const SizedBox(height: 24),
            if (controller.isSandbox.value)
              Row(
                children: [
                  if (controller.onSandboxNextWave != null) ...[
                    Expanded(
                      flex: 3,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC89B5D),
                          foregroundColor: Colors.black,
                          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => controller.onSandboxNextWave!(),
                        child: Text(
                          'PROCEED TO NEXT WAVE',
                          style: VitruvianTypography.monospaceData(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF151310),
                        foregroundColor: VitruvianColors.agedBone,
                        side: const BorderSide(color: Color(0xFF3C3224)),
                        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        controller.inCombat.value = false;
                        controller.isSandbox.value = false;
                      },
                      child: Text(
                        'RETURN TO SETUP',
                        style: VitruvianTypography.monospaceData(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC89B5D),
                    foregroundColor: Colors.black,
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    controller.finishCombatVictory();
                  },
                  child: Text(
                    'COLLECT TROPHIES & TRAVERSE',
                    style: VitruvianTypography.monospaceData(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Skill Popup Banner (slides up from bottom, above HUD) ───
  Widget _buildSkillPopupBanner(CombatController controller) {
    return Obx(() {
      final eventId = controller.attackEventId.value;
      final event = controller.lastCombatEvent.value;

      if (eventId == 0 || event == null) return const SizedBox.shrink();

      // Just under the turn banner, clear of your cards and the hand.
      return Positioned(
        top: 96,
        left: 24,
        right: 24,
        key: ValueKey('skill_popup_$eventId'),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xDD0A0806),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: event.isPlayerAction
                    ? const Color(0xFFC89B5D)
                    : VitruvianColors.rustBlood,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: (event.isPlayerAction
                          ? const Color(0xFFC89B5D)
                          : VitruvianColors.rustBlood)
                      .withValues(alpha: 0.3),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Weapon ⟫ Skill Name
                Text(
                  event.formattedWeaponSkill,
                  style: VitruvianTypography.serifTitle(
                    fontSize: 15,
                    color: event.isPlayerAction
                        ? const Color(0xFFE4DCD0)
                        : const Color(0xFFFFAAAA),
                  ).copyWith(letterSpacing: 1.0),
                  textAlign: TextAlign.center,
                ),
                // Perk text (if any)
                if (event.perks.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.perks.join(' · '),
                    style: VitruvianTypography.monospaceData(
                      fontSize: 11,
                      color: const Color(0xFF8BFF8B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          )
              .animate()
              .slideY(begin: 1.5, end: 0, duration: 220.ms, curve: Curves.easeOutCubic)
              .fadeIn(duration: 200.ms)
              .then(delay: 1200.ms)
              .fadeOut(duration: 300.ms)
              .slideY(begin: 0, end: -0.3, duration: 300.ms),
        ),
      );
    });
  }

  // ─── Animated Damage Number Overlay (centered on screen for emphasis) ───
}

/// One of the two defeat choices: equal height, a single line of text, a 1px
/// border in its own colour.
class _DefeatButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color fill;
  final Color edge;
  final VoidCallback onTap;

  const _DefeatButton({required this.label, required this.icon, required this.fill, required this.edge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: fill,
          foregroundColor: VitruvianColors.agedBone,
          side: BorderSide(color: edge, width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: onTap,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: edge),
              const SizedBox(width: 8),
              Text(label, maxLines: 1, style: VitruvianTypography.monospaceData(fontSize: 12, color: VitruvianColors.agedBone)),
            ],
          ),
        ),
      ),
    );
  }
}

