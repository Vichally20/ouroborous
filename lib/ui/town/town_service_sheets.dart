import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/typography.dart';
import '../../models/item.dart';
import '../../states/inventory_state.dart';
import '../../states/navigation_state.dart';
import '../../states/player_state.dart';
import '../../states/town_state.dart';
import '../combat/combat_widgets.dart' show CombatPalette;

/// Label for an NPC's button in the district view.
String townServiceLabel(TownService service) => switch (service) {
      TownService.temper => 'TEMPER',
      TownService.buyGear => 'SELL GEAR',
      TownService.bank => 'BANK',
      TownService.exchange => 'EXCHANGE',
      TownService.rest => 'REST',
      TownService.drink => 'ORDER',
    };

/// Opens the sheet for [service], run by [npc].
void showTownService(BuildContext context, TownService service, String npc) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: CombatPalette.raised,
    shape: const RoundedRectangleBorder(side: BorderSide(color: CombatPalette.hairlineStrong)),
    constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.82),
    builder: (_) => SafeArea(child: _ServiceSheet(service: service, npc: npc)),
  );
}

String _crowns(int n) {
  final s = n.abs().toString();
  final b = StringBuffer(n < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class _ServiceSheet extends StatefulWidget {
  final TownService service;
  final String npc;
  const _ServiceSheet({required this.service, required this.npc});

  @override
  State<_ServiceSheet> createState() => _ServiceSheetState();
}

class _ServiceSheetState extends State<_ServiceSheet> {
  final town = Get.find<TownState>();
  final inv = Get.find<InventoryState>();
  final player = Get.find<PlayerState>();

  String? _message;
  bool _error = false;

  /// Item id waiting for a second tap to confirm a sale.
  String? _confirmSell;

  void _result(String? error, String success) {
    setState(() {
      _error = error != null;
      _message = error ?? success;
      _confirmSell = null;
    });
  }

  String get _greeting => switch (widget.service) {
        TownService.temper => '"Steel remembers every blow. Bring me crowns and I\'ll teach yours a few more."',
        TownService.buyGear => '"Master says I can buy what you don\'t need. Fair prices. Mostly."',
        TownService.bank => '"Crowns in a vault earn their keep. Crowns in a purse get dropped in ditches."',
        TownService.exchange => '"Old drachma? The vault takes them at ${TownState.drachmaRate} crowns apiece."',
        TownService.rest => '"Beds are dry, mostly. Pay first, and keep your boots on if you want to keep them."',
        TownService.drink => '"Ale for the nerves, stew for the holes in you. Coin on the bar, love."',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      child: Obx(() {
        // Touch the reactive sources so every balance and list stays current.
        inv.ledger.length;
        player.heroes.length;
        player.loadout.value;
        town.bankedCrowns.value;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.npc.toUpperCase(),
                      style: VitruvianTypography.serifTitle(fontSize: 18, color: CombatPalette.parchment)),
                ),
                _Balance(label: 'PURSE', value: town.purse),
                if (widget.service == TownService.bank) ...[
                  const SizedBox(width: 8),
                  _Balance(label: 'VAULT', value: town.bankedCrowns.value),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(_greeting,
                style: VitruvianTypography.serifBody(fontSize: 14, color: CombatPalette.ash)
                    .copyWith(fontStyle: FontStyle.italic)),
            const SizedBox(height: 14),
            Flexible(child: _body()),
            if (_message != null) ...[
              const SizedBox(height: 10),
              Text(_message!,
                  style: VitruvianTypography.serifBody(
                      fontSize: 14, color: _error ? CombatPalette.wound : CombatPalette.verdigris)),
            ],
          ],
        );
      }),
    );
  }

  Widget _body() => switch (widget.service) {
        TownService.temper => _forge(),
        TownService.buyGear => _sell(),
        TownService.bank => _bank(),
        TownService.exchange => _exchange(),
        TownService.rest => _rest(),
        TownService.drink => _drink(),
      };

  // ─── Forge ──────────────────────────────────────────────────────────────────

  String _statLine(ArtifactItem item, {ArtifactItem? next}) {
    final label = item.category == ItemCategory.weapon ? 'DMG' : 'ARMOUR';
    return next == null ? '$label ${item.power}' : '$label ${item.power} → ${next.power}';
  }

  Widget _forge() {
    final gear = town.forgeableGear;
    if (gear.isEmpty) return _empty('You have nothing for the anvil.');
    return ListView.separated(
      shrinkWrap: true,
      itemCount: gear.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final (:item, :equipped) = gear[i];
        final cost = town.temperCost(item);
        final next = cost == null ? null : item.copyWith(temper: item.temper + 1);
        final affordable = cost != null && town.purse >= cost;
        return _Row(
          title: item.displayName,
          tag: equipped ? 'WORN' : null,
          detail: _statLine(item, next: next),
          pips: item.temper,
          action: cost == null ? 'MASTERWORK' : 'TEMPER · ${_crowns(cost)}',
          enabled: affordable,
          onTap: () => _result(
            town.temper(item, equipped: equipped),
            '${item.name} is now +${item.temper + 1}. ${_statLine(next!)}.',
          ),
        );
      },
    );
  }

  // ─── Apprentice ─────────────────────────────────────────────────────────────

  Widget _sell() {
    final gear = town.sellableGear;
    if (gear.isEmpty) return _empty('Nothing in your pack the apprentice wants. Take worn gear off first.');
    return ListView.separated(
      shrinkWrap: true,
      itemCount: gear.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final item = gear[i];
        final price = town.sellPrice(item);
        final confirming = _confirmSell == item.id;
        return _Row(
          title: item.count > 1 ? '${item.displayName} ×${item.count}' : item.displayName,
          detail: _statLine(item),
          pips: item.temper,
          action: confirming ? 'CONFIRM · ${_crowns(price)}' : 'SELL · ${_crowns(price)}',
          danger: confirming,
          onTap: () {
            if (!confirming) {
              setState(() {
                _confirmSell = item.id;
                _message = null;
              });
              return;
            }
            _result(town.sell(item), 'Sold ${item.displayName} for ${_crowns(price)} crowns.');
          },
        );
      },
    );
  }

  // ─── Counting House ─────────────────────────────────────────────────────────

  Widget _bank() {
    final purse = town.purse, vault = town.bankedCrowns.value;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Banked crowns earn ${(TownState.interestRate * 100).round()}% after every battle you win, '
            'and stay safe if you flee. Fleeing drops a tenth of what you carry.',
            style: VitruvianTypography.serifBody(fontSize: 14, color: CombatPalette.bone),
          ),
          const SizedBox(height: 14),
          _label('DEPOSIT'),
          _amounts(purse, (n) => _result(town.deposit(n), 'Deposited ${_crowns(n)} crowns.')),
          const SizedBox(height: 12),
          _label('WITHDRAW'),
          _amounts(vault, (n) => _result(town.withdraw(n), 'Withdrew ${_crowns(n)} crowns.')),
        ],
      ),
    );
  }

  Widget _amounts(int available, void Function(int) onPick) {
    final options = <(String, int)>[('100', 100), ('500', 500), ('ALL', available)];
    return Row(
      children: [
        for (final (i, (label, n)) in options.indexed) ...[
          if (i > 0) const SizedBox(width: 8),
          Expanded(
            child: _Button(
              label: label == 'ALL' ? 'ALL · ${_crowns(n)}' : label,
              enabled: n > 0 && n <= available,
              onTap: () => onPick(n),
            ),
          ),
        ],
      ],
    );
  }

  // ─── Vault Warden ───────────────────────────────────────────────────────────

  Widget _exchange() {
    final d = town.drachma;
    if (d == 0) return _empty('You carry no drachma.');
    final ten = d < 10 ? d : 10;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label('ANCIENT DRACHMA · ${_crowns(d)} CARRIED'),
        Row(
          children: [
            Expanded(
              child: _Button(
                label: 'CHANGE $ten → ${_crowns(ten * TownState.drachmaRate)}',
                onTap: () => _result(town.exchangeDrachma(ten), 'Changed $ten drachma for ${_crowns(ten * TownState.drachmaRate)} crowns.'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _Button(
                label: 'ALL → ${_crowns(d * TownState.drachmaRate)}',
                onTap: () => _result(town.exchangeDrachma(d), 'Changed $d drachma for ${_crowns(d * TownState.drachmaRate)} crowns.'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Drowned Lantern Inn ────────────────────────────────────────────────────

  /// One line per hero: HP, stamina and sanity as they stand.
  Widget _partyVitals({bool activeOnly = false}) {
    final heroes = activeOnly ? [player.activeHero] : player.heroes.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final h in heroes)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(h.name,
                      overflow: TextOverflow.ellipsis,
                      style: VitruvianTypography.serifTitle(fontSize: 14, color: CombatPalette.parchment)),
                ),
                Text(
                  'HP ${h.vitals.currentHp}/${h.vitals.maxHp}  STA ${h.vitals.currentStamina}/${h.vitals.maxStamina}  '
                  'SAN ${h.vitals.currentSanity}',
                  style: VitruvianTypography.monospaceData(
                      fontSize: 11,
                      color: h.vitals.currentHp < h.vitals.maxHp ? CombatPalette.wound : CombatPalette.bone),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _rest() {
    final fresh = town.partyFresh;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('YOUR PARTY'),
          _partyVitals(),
          const SizedBox(height: 12),
          for (final room in InnRoom.values) ...[
            _Offer(
              title: room.label,
              detail: room.blurb,
              action: 'SLEEP · ${_crowns(room.price)}',
              enabled: !fresh && town.purse >= room.price,
              onTap: () => _result(town.rest(room), 'You sleep in the ${room.label.toLowerCase()} and wake rested.'),
            ),
            const SizedBox(height: 8),
          ],
          if (fresh) _empty('Everyone is already rested.'),
        ],
      ),
    );
  }

  Widget _drink() {
    final hero = player.activeHero;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('SERVED TO ${hero.name.toUpperCase()}'),
          _partyVitals(activeOnly: true),
          const SizedBox(height: 12),
          for (final fare in InnFare.values) ...[
            _Offer(
              title: fare.label,
              detail: fare.summary,
              action: 'BUY · ${_crowns(fare.price)}',
              enabled: town.purse >= fare.price,
              onTap: () => _result(town.drink(fare), '${hero.name} finishes the ${fare.unit}. ${fare.summary}.'),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: VitruvianTypography.monospaceData(fontSize: 11, color: CombatPalette.brass)),
      );

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(text, style: VitruvianTypography.serifBody(fontSize: 14, color: CombatPalette.ash)),
      );
}

class _Balance extends StatelessWidget {
  final String label;
  final int value;
  const _Balance({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: CombatPalette.sunk,
          border: Border.all(color: CombatPalette.hairlineStrong),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(label, style: VitruvianTypography.monospaceData(fontSize: 9, color: CombatPalette.ash)),
            Text(_crowns(value), style: VitruvianTypography.monospaceData(fontSize: 13, color: CombatPalette.brass)),
          ],
        ),
      );
}

/// One piece of gear with its numbers, temper pips and an action button.
class _Row extends StatelessWidget {
  final String title;
  final String? tag;
  final String detail;
  final int pips;
  final String action;
  final bool enabled;
  final bool danger;
  final VoidCallback onTap;

  const _Row({
    required this.title,
    this.tag,
    required this.detail,
    required this.pips,
    required this.action,
    this.enabled = true,
    this.danger = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: CombatPalette.surface,
        border: Border.all(color: CombatPalette.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title,
                          overflow: TextOverflow.ellipsis,
                          style: VitruvianTypography.serifTitle(fontSize: 15, color: CombatPalette.parchment)),
                    ),
                    if (tag != null) ...[
                      const SizedBox(width: 6),
                      Text(tag!, style: VitruvianTypography.monospaceData(fontSize: 9, color: CombatPalette.verdigris)),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    for (var i = 0; i < ArtifactItem.maxTemper; i++)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < pips ? CombatPalette.brass : Colors.transparent,
                          border: Border.all(color: CombatPalette.brass.withValues(alpha: 0.6)),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(detail,
                          overflow: TextOverflow.ellipsis,
                          style: VitruvianTypography.monospaceData(fontSize: 11, color: CombatPalette.bone)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Button(label: action, enabled: enabled, danger: danger, onTap: onTap, compact: true),
        ],
      ),
    );
  }
}

/// A priced offer (a bed, a drink) with a line of what it does.
class _Offer extends StatelessWidget {
  final String title;
  final String detail;
  final String action;
  final bool enabled;
  final VoidCallback onTap;

  const _Offer({required this.title, required this.detail, required this.action, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: CombatPalette.surface,
        border: Border.all(color: CombatPalette.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: VitruvianTypography.serifTitle(fontSize: 15, color: CombatPalette.parchment)),
                const SizedBox(height: 4),
                Text(detail, style: VitruvianTypography.serifBody(fontSize: 13, color: CombatPalette.bone)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _Button(label: action, enabled: enabled, onTap: onTap, compact: true),
        ],
      ),
    );
  }
}

class _Button extends StatelessWidget {
  final String label;
  final bool enabled;
  final bool danger;
  final bool compact;
  final VoidCallback onTap;

  const _Button({required this.label, required this.onTap, this.enabled = true, this.danger = false, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final fg = !enabled ? CombatPalette.ash : (danger ? CombatPalette.wound : CombatPalette.brass);
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: fg,
        disabledForegroundColor: CombatPalette.ash,
        side: BorderSide(color: danger ? CombatPalette.rust : (enabled ? CombatPalette.brass : CombatPalette.hairlineStrong)),
        shape: const RoundedRectangleBorder(),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 8, vertical: 12),
        minimumSize: const Size(0, 40),
      ),
      onPressed: enabled ? onTap : null,
      child: Text(label, style: VitruvianTypography.monospaceData(fontSize: 11, color: fg)),
    );
  }
}
