import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../models/talent_node.dart';
import '../widgets/etched_container.dart';

class TalentsScreen extends StatefulWidget {
  const TalentsScreen({super.key});

  @override
  State<TalentsScreen> createState() => _TalentsScreenState();
}

class _TalentsScreenState extends State<TalentsScreen> {
  final List<TalentNode> constellation = [
    const TalentNode(
      id: 't1',
      title: 'Hyper-Vascularity',
      clinicalDescription: 'Increases Bleed resistance by +15% and accelerates coagulation.',
      constellationPosition: Offset(150, 280),
      isUnlocked: true,
    ),
    const TalentNode(
      id: 't2',
      title: 'Cranium Calcification',
      clinicalDescription: 'Reinforces skull density to mitigate physical trauma.',
      constellationPosition: Offset(90, 160),
      requiredParentIds: ['t1'],
    ),
    const TalentNode(
      id: 't3',
      title: 'Hermetic Synapses',
      clinicalDescription: 'Expands neural pathways, granting +4 INT.',
      constellationPosition: Offset(220, 140),
      requiredParentIds: ['t1'],
    ),
    const TalentNode(
      id: 't4',
      title: 'Vitruvian Awakening',
      clinicalDescription: 'Unlock diegetic mastery over bodily mutations.',
      constellationPosition: Offset(160, 40),
      requiredParentIds: ['t2', 't3'],
    ),
  ];

  TalentNode? selectedNode;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text(
            'ANATOMICAL GROWTH CONSTELLATION',
            style: VitruvianTypography.serifTitle(fontSize: 16),
          ),
        ),
        const Divider(),

        // Constellation Map Canvas
        Expanded(
          child: EtchedContainer(
            margin: const EdgeInsets.all(12),
            child: CustomPaint(
              painter: _ConstellationPainter(constellation),
              child: Stack(
                children: constellation.map((node) {
                  return Positioned(
                    left: node.constellationPosition.dx - 20,
                    top: node.constellationPosition.dy - 20,
                    child: GestureDetector(
                      onTap: () => setState(() => selectedNode = node),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: node.isUnlocked
                              ? VitruvianColors.sepiaUmber
                              : VitruvianColors.voidBlack,
                          border: Border.all(
                            color: selectedNode?.id == node.id
                                ? Colors.cyanAccent
                                : VitruvianColors.agedBone,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          node.isUnlocked ? Icons.auto_awesome : Icons.lock_outline,
                          size: 18,
                          color: node.isUnlocked ? VitruvianColors.voidBlack : Colors.white30,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        // Node Intel Panel
        if (selectedNode != null)
          EtchedContainer(
            margin: const EdgeInsets.all(12),
            borderColor: VitruvianColors.sepiaUmber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(selectedNode!.title.toUpperCase(),
                        style: VitruvianTypography.serifTitle(fontSize: 16)),
                    Text(
                      selectedNode!.isUnlocked ? 'MUTATION ACTIVE' : 'LOCKED',
                      style: VitruvianTypography.monospaceData(
                        fontSize: 11,
                        color: selectedNode!.isUnlocked ? Colors.cyanAccent : Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(selectedNode!.clinicalDescription,
                    style: VitruvianTypography.serifBody(fontSize: 14)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ConstellationPainter extends CustomPainter {
  final List<TalentNode> nodes;

  _ConstellationPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = VitruvianColors.etchedHairline
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final node in nodes) {
      for (final parentId in node.requiredParentIds) {
        final parent = nodes.firstWhere((n) => n.id == parentId);
        canvas.drawLine(node.constellationPosition, parent.constellationPosition, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
