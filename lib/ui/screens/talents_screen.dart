import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';

class NodeBonus {
  final String label;
  final String value;
  const NodeBonus(this.label, this.value);
}

class TalentNodeItem {
  final String id;
  final String title;
  final String rank;
  final String lore;
  final List<NodeBonus> bonuses;
  final Offset pos;
  final List<String> parentIds;
  final bool isActive;
  final IconData icon;

  const TalentNodeItem({
    required this.id,
    required this.title,
    required this.rank,
    required this.lore,
    required this.bonuses,
    required this.pos,
    this.parentIds = const [],
    this.isActive = false,
    required this.icon,
  });
}

class TalentsScreen extends StatefulWidget {
  const TalentsScreen({super.key});

  @override
  State<TalentsScreen> createState() => _TalentsScreenState();
}

class _TalentsScreenState extends State<TalentsScreen> {
  late final List<TalentNodeItem> constellation;
  TalentNodeItem? selectedNode;

  @override
  void initState() {
    super.initState();
    constellation = [
      // TIER 1: The Root
      const TalentNodeItem(
        id: 'root',
        title: 'Iron Fundamentals',
        rank: 'TIER I : ROOT',
        lore: 'Unlocks Heavy Armor and standard One-Handed Weapons/Shields.',
        bonuses: [
          NodeBonus('Base Strength', '+10%'),
          NodeBonus('Heavy Armor & Shields', 'UNLOCKED'),
        ],
        pos: Offset(170, 45),
        isActive: true,
        icon: Icons.shield,
      ),

      // TIER 2: The Core Branches (1 branches out to 3)
      const TalentNodeItem(
        id: 'branchA',
        title: 'Juggernaut',
        rank: 'TIER II : BRANCH A',
        lore: 'An immovable bulwark of martial iron.',
        bonuses: [
          NodeBonus('Physical Resistance', '+15%'),
          NodeBonus('Movement Speed', '-5%'),
        ],
        parentIds: ['root'],
        pos: Offset(55, 145),
        isActive: true,
        icon: Icons.security,
      ),
      const TalentNodeItem(
        id: 'branchB',
        title: 'Berserker',
        rank: 'TIER II : BRANCH B',
        lore: 'Unrelenting fury born of sacrificial bloodshed.',
        bonuses: [
          NodeBonus('Attack Damage', '+15%'),
          NodeBonus('Damage Taken', '+5%'),
        ],
        parentIds: ['root'],
        pos: Offset(170, 145),
        isActive: true,
        icon: Icons.local_fire_department,
      ),
      const TalentNodeItem(
        id: 'branchC',
        title: 'Duelist',
        rank: 'TIER II : BRANCH C',
        lore: 'Exclusive Perk: Only class capable of wielding Two-Handed Weapons, dealing Double (x2) Damage per strike.',
        bonuses: [
          NodeBonus('Critical Hit Chance', '+10%'),
          NodeBonus('Evasion Rating', '+10%'),
          NodeBonus('Two-Handed Mastery', 'x2 Dmg'),
        ],
        parentIds: ['root'],
        pos: Offset(285, 145),
        isActive: true,
        icon: Icons.sports_martial_arts,
      ),

      // TIER 3: The Intersections & Edges
      const TalentNodeItem(
        id: 'nodeA1',
        title: 'Shield Wall',
        rank: 'TIER III : NODE A1',
        lore: 'Perk: Blocks restore physical stamina.',
        bonuses: [
          NodeBonus('Block Chance', '+20%'),
          NodeBonus('Stamina on Block', 'ACTIVE'),
        ],
        parentIds: ['branchA'],
        pos: Offset(35, 255),
        isActive: true,
        icon: Icons.shield_outlined,
      ),
      const TalentNodeItem(
        id: 'nodeA2',
        title: 'Vanguard\'s Retribution',
        rank: 'TIER III : NODE A2',
        lore: 'Perk: Blocking triggers a devastating, unblockable sweeping counterattack.',
        bonuses: [
          NodeBonus('Counterattack Sweep', 'UNBLOCKABLE'),
          NodeBonus('Retribution Force', 'ACTIVE'),
        ],
        parentIds: ['branchA', 'branchB'], // Intersects Branch A + Branch B
        pos: Offset(120, 255),
        isActive: true,
        icon: Icons.hardware,
      ),
      const TalentNodeItem(
        id: 'nodeC1',
        title: 'Flurry of Death',
        rank: 'TIER III : NODE C1',
        lore: 'Perk: Critical hits trigger rapid strikes instantly applying Bleed +3.',
        bonuses: [
          NodeBonus('Bleed Application', '+3 Stacks'),
          NodeBonus('Critical Rapid Strike', 'ACTIVE'),
        ],
        parentIds: ['branchB', 'branchC'], // Intersects Branch B + Branch C
        pos: Offset(220, 255),
        isActive: false,
        icon: Icons.storm,
      ),
      const TalentNodeItem(
        id: 'nodeC2',
        title: 'Expose Weakness',
        rank: 'TIER III : NODE C2',
        lore: 'Perk: Attacks pierce directly through armor plating.',
        bonuses: [
          NodeBonus('Physical Armor Ignore', '25%'),
          NodeBonus('Armor Penetration', 'ACTIVE'),
        ],
        parentIds: ['branchC'],
        pos: Offset(305, 255),
        isActive: false,
        icon: Icons.gps_fixed,
      ),

      // TIER 4: The Capstone
      const TalentNodeItem(
        id: 'capstone',
        title: 'Execute',
        rank: 'TIER IV : CAPSTONE',
        lore: 'Perk: Deliver a final blow to bleeding/countered foes dealing x3 Dmg.\nSynergy: Duelist Two-Handed (x2) + Execute (x3) creates an absolute nuke of an attack.',
        bonuses: [
          NodeBonus('Execute Final Blow', 'x3.0 Dmg'),
          NodeBonus('2H Nuke Synergy', 'x6.0 TOTAL'),
        ],
        parentIds: ['nodeA2', 'nodeC1'], // Intersects Node A2 + Node C1
        pos: Offset(170, 365),
        isActive: false,
        icon: Icons.auto_awesome,
      ),
    ];

    // Default select Execute capstone to showcase the synergy
    selectedNode = constellation[8];
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFFC8B458); // Highlighted golden/green

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // HEADER TITLE
          Text(
            'TALENT GROWTH',
            style: VitruvianTypography.serifTitle(
              fontSize: 18,
              color: VitruvianColors.agedBone,
            ).copyWith(letterSpacing: 2.0),
          ),
          const SizedBox(height: 12),

          // TALENT TREE CONTAINER
          Container(
            height: 430,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(
              color: Color(0xFF0C0A08),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Oversized Background Helmeted Skull Image shifted to the right
                Positioned(
                  left: 60,
                  top: -50,
                  bottom: -50,
                  right: -140,
                  child: Opacity(
                    opacity: 0.35,
                    child: Image.asset(
                      'assets/images/skull.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Dark atmospheric gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          const Color(0xFF0C0A08), // Solid dark on left
                          const Color(0xFF0C0A08).withValues(alpha: 0.45),
                          const Color(0xFF0C0A08).withValues(alpha: 0.8),
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ),

                // Constellation Canvas & Nodes
                Center(
                  child: SizedBox(
                    width: 340,
                    height: 420,
                    child: CustomPaint(
                      painter: _ConstellationPainter(constellation),
                      child: Stack(
                        children: constellation.map((node) {
                          final isSelected = selectedNode?.id == node.id;
                          return Positioned(
                            left: node.pos.dx - 24,
                            top: node.pos.dy - 24,
                            child: GestureDetector(
                              onTap: () => setState(() => selectedNode = node),
                              behavior: HitTestBehavior.opaque,
                              child: Column(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: node.isActive
                                          ? const Color(0xFF1E1C16)
                                          : const Color(0xFF100E0A),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.white
                                            : (node.isActive
                                                ? activeColor
                                                : const Color(0xFF3A3228)),
                                        width: isSelected
                                            ? 2.5
                                            : (node.isActive ? 2.0 : 1.2),
                                      ),
                                      boxShadow: node.isActive
                                          ? [
                                              BoxShadow(
                                                color: activeColor.withValues(alpha: 0.35),
                                                blurRadius: 10,
                                                spreadRadius: 1,
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      node.icon,
                                      size: 22,
                                      color: node.isActive
                                          ? activeColor
                                          : Colors.white24,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    node.title.toUpperCase(),
                                    style: VitruvianTypography.monospaceData(
                                      fontSize: 8,
                                      color: isSelected
                                          ? Colors.white
                                          : (node.isActive
                                              ? const Color(0xFFE0C8B0)
                                              : Colors.white30),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // NODE INTEL PANEL (CURRENT FOCUS)
          if (selectedNode != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF151310),
                border: Border.all(color: const Color(0xFF3A2C20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'CURRENT FOCUS:\n${selectedNode!.title.toUpperCase()}',
                          style: VitruvianTypography.serifTitle(
                            fontSize: 16,
                            color: const Color(0xFFE0C8B0),
                          ).copyWith(letterSpacing: 1.2),
                        ),
                      ),
                      Text(
                        selectedNode!.rank,
                        style: VitruvianTypography.serifTitle(
                          fontSize: 15,
                          color: const Color(0xFF8A7A68),
                        ).copyWith(letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedNode!.lore,
                    style: VitruvianTypography.serifBody(
                      fontSize: 14,
                      color: const Color(0xFF8A7A68),
                    ).copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF2A2218), thickness: 1),
                  const SizedBox(height: 8),

                  ...selectedNode!.bonuses.map((bonus) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Text(
                            bonus.label.toUpperCase(),
                            style: VitruvianTypography.monospaceData(
                              fontSize: 12,
                              color: VitruvianColors.agedBone,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                final dotCount = (constraints.maxWidth / 5).floor();
                                return Text(
                                  '.' * dotCount,
                                  style: const TextStyle(
                                    color: Color(0xFF2A2218),
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.clip,
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            bonus.value,
                            style: VitruvianTypography.monospaceData(
                              fontSize: 13,
                              color: activeColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<TalentNodeItem> nodes;

  _ConstellationPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final activePaint = Paint()
      ..color = const Color(0xFFC8B458) // Highlighted golden/green
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final inactivePaint = Paint()
      ..color = const Color(0xFF4A4032) // Dim grey/tan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      for (final parentId in node.parentIds) {
        final parent = nodes.firstWhere((n) => n.id == parentId);
        if (node.isActive && parent.isActive) {
          canvas.drawLine(node.pos, parent.pos, activePaint);
        } else {
          _drawDottedLine(canvas, parent.pos, node.pos, inactivePaint);
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
