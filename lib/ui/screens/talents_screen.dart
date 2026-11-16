import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/hero_character.dart';
import '../../models/talent_node.dart';
import '../../states/player_state.dart';

enum _NodeState { owned, available, locked }

/// The talent constellation for the active hero.
///
/// Rules (see [TalentTree] and [PlayerState]):
/// - Every hero starts with only the root (tier I).
/// - Each level gained after the first gives one point.
/// - A node can be taken only once a node above it is owned, and owned nodes are
///   permanent, so progress flows one way: downward from the root.
class TalentsScreen extends StatefulWidget {
  const TalentsScreen({super.key});

  @override
  State<TalentsScreen> createState() => _TalentsScreenState();
}

class _TalentsScreenState extends State<TalentsScreen> {
  static const _owned = VitruvianColors.goldLeaf;
  static const _available = Color(0xFFC89B5D);
  static const _locked = Color(0xFF3A3228);

  String? selectedId;

  _NodeState _stateOf(TalentTree tree, TalentNode node, HeroCharacter hero) {
    if (hero.unlockedTalents.contains(node.id)) return _NodeState.owned;
    if (tree.isReachable(node.id, hero.unlockedTalents)) return _NodeState.available;
    return _NodeState.locked;
  }

  @override
  Widget build(BuildContext context) {
    final playerState = Get.find<PlayerState>();

    return Obx(() {
      final hero = playerState.heroes[playerState.activeHeroIndex.value];
      final tree = hero.talentTree;
      final level = playerState.level.value;

      if (tree == null) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              '${hero.name.split(' ').first}\'s talent constellation has not been charted yet.',
              textAlign: TextAlign.center,
              style: VitruvianTypography.serifBody(fontSize: 15, color: const Color(0xFF8A7A68)),
            ),
          ),
        );
      }

      final points = playerState.talentPointsFor(hero);
      final selected = tree.node(selectedId ?? '') ??
          tree.nodes.firstWhere((n) => _stateOf(tree, n, hero) == _NodeState.available,
              orElse: () => tree.node(tree.rootId)!);

      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'TALENT GROWTH',
                    style: VitruvianTypography.serifTitle(fontSize: 18, color: VitruvianColors.agedBone)
                        .copyWith(letterSpacing: 2.0),
                  ),
                ),
                Text(
                  'LVL $level · ${points == 1 ? '1 POINT' : '$points POINTS'}',
                  style: VitruvianTypography.monospaceData(
                    fontSize: 12,
                    color: points > 0 ? _available : const Color(0xFF8A7A68),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              points > 0
                  ? 'Choose a lit node below one you own. Choices are permanent.'
                  : 'Gain a level to earn a talent point.',
              style: VitruvianTypography.serifBody(fontSize: 13, color: const Color(0xFF8A7A68))
                  .copyWith(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 12),

            Container(
              height: 430,
              clipBehavior: Clip.hardEdge,
              decoration: const BoxDecoration(color: Color(0xFF0C0A08)),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 60,
                    top: -50,
                    bottom: -50,
                    right: -140,
                    child: Opacity(
                      opacity: 0.35,
                      child: Image.asset('assets/images/skull.jpg', fit: BoxFit.cover),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF0C0A08),
                            const Color(0xFF0C0A08).withValues(alpha: 0.45),
                            const Color(0xFF0C0A08).withValues(alpha: 0.8),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // The tree is drawn on a 340×420 canvas; on narrow phones it scales
                  // down to fit instead of clipping the outer talents.
                  Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 340,
                        height: 420,
                        child: CustomPaint(
                          painter: _ConstellationPainter(tree, hero.unlockedTalents),
                          child: Stack(
                            children: tree.nodes.map((node) {
                              final state = _stateOf(tree, node, hero);
                              return Positioned(
                                left: node.pos.dx - 24,
                                top: node.pos.dy - 24,
                                child: _buildNode(node, state, isSelected: node.id == selected.id,
                                    canAfford: points > 0),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDetail(context, playerState, tree, hero, selected, points),
            const SizedBox(height: 24),
          ],
        ),
      );
    });
  }

  Widget _buildNode(TalentNode node, _NodeState state, {required bool isSelected, required bool canAfford}) {
    final color = switch (state) {
      _NodeState.owned => _owned,
      _NodeState.available => canAfford ? _available : const Color(0xFF6A5E52),
      _NodeState.locked => _locked,
    };
    return GestureDetector(
      onTap: () => setState(() => selectedId = node.id),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 48,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: state == _NodeState.owned ? const Color(0xFF1E1C16) : const Color(0xFF100E0A),
                border: Border.all(
                  color: isSelected ? VitruvianColors.agedBone : color,
                  width: isSelected ? 2.5 : (state == _NodeState.locked ? 1.2 : 2.0),
                ),
                boxShadow: state == _NodeState.owned || (state == _NodeState.available && canAfford)
                    ? [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 10, spreadRadius: 1)]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: _Medallion(node: node, state: state, dim: state == _NodeState.available && !canAfford, glyphColor: color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              node.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: VitruvianTypography.monospaceData(
                fontSize: 9,
                color: state == _NodeState.locked ? Colors.white30 : const Color(0xFFE0C8B0),
              ),
              maxLines: 2,
              overflow: TextOverflow.visible,
              softWrap: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, PlayerState playerState, TalentTree tree, HeroCharacter hero,
      TalentNode node, int points) {
    final state = _stateOf(tree, node, hero);
    String status;
    switch (state) {
      case _NodeState.owned:
        status = 'OWNED';
        break;
      case _NodeState.available:
        status = points > 0 ? 'AVAILABLE' : 'NEEDS A TALENT POINT';
        break;
      case _NodeState.locked:
        final parents = node.parentIds.map((id) => tree.node(id)?.title ?? id).join(' or ');
        status = 'REQUIRES $parents'.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151310),
        border: Border.all(color: const Color(0xFF3A2C20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                height: 52,
                child: _Medallion(node: node, state: state, dim: false, glyphColor: _owned, size: 52),
              ),
              const SizedBox(width: 12),
              // Title over rank, so a long rank ("TIER III : FROM A OR B") never
              // squeezes the title on a phone.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      node.title.toUpperCase(),
                      style: VitruvianTypography.serifTitle(fontSize: 16, color: const Color(0xFFE0C8B0))
                          .copyWith(letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      node.rank,
                      style: VitruvianTypography.serifTitle(fontSize: 12, color: const Color(0xFF8A7A68))
                          .copyWith(letterSpacing: 1.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            node.lore,
            style: VitruvianTypography.serifBody(fontSize: 14, color: const Color(0xFF8A7A68))
                .copyWith(fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A2218), thickness: 1),
          ...node.bonuses.map((b) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(b.label.toUpperCase(),
                          style: VitruvianTypography.monospaceData(fontSize: 12, color: VitruvianColors.agedBone)),
                    ),
                    Text(b.value, style: VitruvianTypography.monospaceData(fontSize: 13, color: _available)),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          Text(
            status,
            style: VitruvianTypography.monospaceData(
              fontSize: 11,
              color: state == _NodeState.owned ? _owned : const Color(0xFF8A7A68),
            ),
          ),
          if (state == _NodeState.available && points > 0) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: _available,
                foregroundColor: VitruvianColors.voidBlack,
                side: const BorderSide(color: _available),
                shape: const RoundedRectangleBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _confirmUnlock(context, playerState, node),
              child: Text('UNLOCK · 1 POINT', style: VitruvianTypography.serifTitle(fontSize: 14, color: VitruvianColors.voidBlack)),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmUnlock(BuildContext context, PlayerState playerState, TalentNode node) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151310),
      shape: const RoundedRectangleBorder(side: BorderSide(color: Color(0xFF3A2C20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('UNLOCK ${node.title.toUpperCase()}?',
                  style: VitruvianTypography.serifTitle(fontSize: 17, color: const Color(0xFFE0C8B0))),
              const SizedBox(height: 8),
              Text('Talents cannot be unlearned. This spends 1 point.',
                  style: VitruvianTypography.serifBody(fontSize: 14, color: VitruvianColors.agedBone)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF8A7A68),
                        side: const BorderSide(color: Color(0xFF3A2C20)),
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('CANCEL'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: _available,
                        foregroundColor: VitruvianColors.voidBlack,
                        side: const BorderSide(color: _available),
                        shape: const RoundedRectangleBorder(),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        playerState.unlockTalent(node.id);
                      },
                      child: const Text('UNLOCK'),
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
}

class _ConstellationPainter extends CustomPainter {
  final TalentTree tree;
  final Set<String> unlocked;

  _ConstellationPainter(this.tree, Set<String> unlocked) : unlocked = Set.of(unlocked);

  @override
  void paint(Canvas canvas, Size size) {
    final ownedPaint = Paint()
      ..color = VitruvianColors.goldLeaf
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    final openPaint = Paint()
      ..color = const Color(0xFFC89B5D).withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final lockedPaint = Paint()
      ..color = const Color(0xFF4A4032)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final node in tree.nodes) {
      for (final parentId in node.parentIds) {
        final parent = tree.node(parentId);
        if (parent == null) continue;
        final parentOwned = unlocked.contains(parentId);
        if (parentOwned && unlocked.contains(node.id)) {
          canvas.drawLine(parent.pos, node.pos, ownedPaint);
        } else {
          _drawDottedLine(canvas, parent.pos, node.pos, parentOwned ? openPaint : lockedPaint);
        }
      }
    }
  }

  void _drawDottedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    final distance = (p2 - p1).distance;
    if (distance == 0) return;
    final direction = (p2 - p1) / distance;
    const step = 5.0;
    const gap = 4.0;
    double current = 0.0;
    while (current < distance) {
      final next = (current + step).clamp(0.0, distance);
      canvas.drawLine(p1 + direction * current, p1 + direction * next, paint);
      current += step + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ConstellationPainter old) =>
      old.tree != tree || old.unlocked.length != unlocked.length || !old.unlocked.containsAll(unlocked);
}

/// A talent's engraved medallion, clipped round. Locked talents are shown in
/// grey and faded; one you can't afford yet is slightly dimmed.
class _Medallion extends StatelessWidget {
  final TalentNode node;
  final _NodeState state;
  final bool dim;
  final Color glyphColor;
  final double size;

  const _Medallion({required this.node, required this.state, required this.dim, required this.glyphColor, this.size = 44});

  static const _greyscale = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0.2126, 0.7152, 0.0722, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final glyph = Center(
      child: Icon(node.icon, size: size * 0.5, color: state == _NodeState.locked ? Colors.white24 : glyphColor),
    );
    final asset = node.iconAsset;
    if (asset == null) return glyph;

    Widget image = ClipOval(
      child: Image.asset(asset, fit: BoxFit.cover, filterQuality: FilterQuality.medium, errorBuilder: (_, _, _) => glyph),
    );
    if (state == _NodeState.locked) {
      image = Opacity(opacity: 0.4, child: ColorFiltered(colorFilter: _greyscale, child: image));
    } else if (dim) {
      image = Opacity(opacity: 0.75, child: image);
    }
    return image;
  }
}

