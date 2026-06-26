import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/player_state.dart';
import '../widgets/etched_container.dart';

class ChronicleChoice {
  final String text;
  final String? requiredAttribute; // e.g. 'STR'
  final int? attributeRequirement; // e.g. 12
  final String nextEventTitle;
  final String nextEventBody;

  const ChronicleChoice({
    required this.text,
    this.requiredAttribute,
    this.attributeRequirement,
    required this.nextEventTitle,
    required this.nextEventBody,
  });
}

class ChronicleScreen extends StatefulWidget {
  final PlayerState playerState;

  const ChronicleScreen({super.key, required this.playerState});

  @override
  State<ChronicleScreen> createState() => _ChronicleScreenState();
}

class _ChronicleScreenState extends State<ChronicleScreen> {
  String currentTitle = 'THE GREAT AMPHITHEATER GATES';
  String currentBody =
      'Rain drips down the etched bronze relief of the amphitheater doors. The smell of formaldehyde and old blood hangs heavily in the fog. A rusted iron bar seals the entryway from within.';

  final List<ChronicleChoice> currentChoices = [
    const ChronicleChoice(
      text: '[STR 12] Force the rusted iron bar open with bare hands.',
      requiredAttribute: 'STR',
      attributeRequirement: 12,
      nextEventTitle: 'THE ANATOMICAL HALL',
      nextEventBody:
          'Muscles straining against rusted iron, the bar snaps with a deafening crack. You step into the vaulted amphitheater.',
    ),
    const ChronicleChoice(
      text: 'Search the perimeter for a clinical scribe service entrance.',
      nextEventTitle: 'THE SCRIBE COBBLESTONES',
      nextEventBody:
          'You slip into the narrow alleyway behind the theater, finding a wooden hatch unlocked.',
    ),
  ];

  void _makeChoice(ChronicleChoice choice) {
    if (choice.requiredAttribute != null) {
      final canPass = widget.playerState.attributes
          .checkAttribute(choice.requiredAttribute!, choice.attributeRequirement!);
      if (!canPass) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Requirement Failed: Requires ${choice.requiredAttribute} ${choice.attributeRequirement}.'),
            backgroundColor: VitruvianColors.rustBlood,
          ),
        );
        return;
      }
    }

    setState(() {
      currentTitle = choice.nextEventTitle;
      currentBody = choice.nextEventBody;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('THE CHRONICLE [LIVING MANUSCRIPT]',
              style: VitruvianTypography.monospaceData(color: Colors.grey)),
          const SizedBox(height: 12),

          EtchedContainer(
            padding: const EdgeInsets.all(20),
            borderColor: VitruvianColors.sepiaUmber,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(currentTitle, style: VitruvianTypography.serifTitle(fontSize: 22)),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Divider(color: VitruvianColors.sepiaUmber),
                ),
                Text(
                  currentBody,
                  style: VitruvianTypography.serifBody(fontSize: 18, height: 1.6),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Text('AVAILABLE NARRATIVE BRANCHES:',
              style: VitruvianTypography.monospaceData(fontSize: 12)),
          const SizedBox(height: 8),

          ...currentChoices.map((choice) {
            bool isGated = choice.requiredAttribute != null;
            bool canPass = true;
            if (isGated) {
              canPass = widget.playerState.attributes
                  .checkAttribute(choice.requiredAttribute!, choice.attributeRequirement!);
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: InkWell(
                onTap: () => _makeChoice(choice),
                child: EtchedContainer(
                  borderColor: !canPass
                      ? VitruvianColors.rustBlood
                      : VitruvianColors.agedBone,
                  backgroundColor: !canPass ? const Color(0xFF1A0A0A) : const Color(0xFF12110F),
                  child: Row(
                    children: [
                      Icon(
                        !canPass ? Icons.block : Icons.history_edu,
                        color: !canPass ? VitruvianColors.rustBlood : VitruvianColors.sepiaUmber,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          choice.text,
                          style: VitruvianTypography.serifBody(
                            fontSize: 15,
                            color: !canPass ? Colors.white38 : VitruvianColors.agedBone,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
