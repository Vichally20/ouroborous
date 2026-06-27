import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../states/combat_state.dart';
import '../../states/player_state.dart';
import '../widgets/etched_container.dart';

class ChronicleChoice {
  final String numeral;
  final String text;
  final String? requiredAttribute;
  final int? attributeRequirement;
  final String nextEventTitle;
  final String nextEventBody;

  const ChronicleChoice({
    required this.numeral,
    required this.text,
    this.requiredAttribute,
    this.attributeRequirement,
    required this.nextEventTitle,
    required this.nextEventBody,
  });
}

class ChronicleScreen extends StatefulWidget {
  const ChronicleScreen({super.key});

  @override
  State<ChronicleScreen> createState() => _ChronicleScreenState();
}

class _ChronicleScreenState extends State<ChronicleScreen> {
  final List<String> paragraphs = [
    'The heavy oak door groans under your weight, revealing a chamber thick with the scent of damp earth and dried blood. Motes of dust dance in the pale light filtering through a fractured grating high above.',
    'A monolithic altar of black stone dominates the center of the room, its surface stained with the desperate prayers of those who came before. The air here feels heavy, oppressive, as if the very walls are pressing inward.',
    'From the deep shadows beyond the altar, a low, rhythmic clicking begins to echo. It sounds like skeletal joints snapping into formation.',
  ];

  final List<ChronicleChoice> currentChoices = [
    const ChronicleChoice(
      numeral: 'I.',
      text: 'Enter the breach',
      nextEventTitle: 'THE BREACHED CRYPT',
      nextEventBody:
          'Drawing your weapon, you step past the monolithic altar into the darkness beyond. The clicking ceases immediately.',
    ),
    const ChronicleChoice(
      numeral: 'II.',
      text: 'Retreat to the shadows',
      nextEventTitle: 'THE ALCOVE RECESS',
      nextEventBody:
          'You press your spine against the damp masonry, melting into the shadows as a towering anatomical monstrosity shambles past.',
    ),
    const ChronicleChoice(
      numeral: 'III.',
      text: 'Search the altar (Requires: 15 Insight)',
      requiredAttribute: 'INSIGHT',
      attributeRequirement: 15,
      nextEventTitle: 'THE SACRIFICIAL ARCHIVE',
      nextEventBody:
          'Your heightened hermetic insight reveals a hidden catch beneath the black stone. A drawer slides out containing ancient manuscripts.',
    ),
  ];

  void _makeChoice(ChronicleChoice choice, PlayerState playerState) {
    if (choice.requiredAttribute != null) {
      final canPass = playerState.attributes.value
          .checkAttribute(choice.requiredAttribute!, choice.attributeRequirement!);
      if (!canPass) {
        Get.snackbar(
          'INSUFFICIENT INSIGHT',
          'This action requires at least ${choice.attributeRequirement} Insight.',
          backgroundColor: VitruvianColors.rustBlood,
          colorText: Colors.white,
          borderRadius: 0,
          margin: const EdgeInsets.all(12),
        );
        return;
      }
    }

    if (choice.numeral == 'I.') {
      Get.find<CombatController>().startCombat();
      return;
    }

    Get.snackbar(
      'CHRONICLE UPDATED',
      'Traversed to: ${choice.nextEventTitle}',
      backgroundColor: const Color(0xFF201B15),
      colorText: VitruvianColors.agedBone,
      borderRadius: 0,
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerState = Get.find<PlayerState>();

    return Obx(() {
      final attr = playerState.attributes.value;

      return Column(
        children: [
          // Scrollable Narrative Manuscript Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    paragraphs[0],
                    style: VitruvianTypography.serifBody(
                      fontSize: 16,
                      height: 1.65,
                      color: const Color(0xFFDCD4C8),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    paragraphs[1],
                    style: VitruvianTypography.serifBody(
                      fontSize: 16,
                      height: 1.65,
                      color: const Color(0xFFDCD4C8),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Loot Uncovered Callout Box
                  EtchedContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderColor: const Color(0xFF383024),
                    backgroundColor: const Color(0xFF0C0A08),
                    child: Text(
                      'Loot Uncovered: Rusted Falchion',
                      style: VitruvianTypography.monospaceData(
                        fontSize: 13,
                        color: const Color(0xFFC0A070),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    paragraphs[2],
                    style: VitruvianTypography.serifBody(
                      fontSize: 16,
                      height: 1.65,
                      color: const Color(0xFFDCD4C8),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Docked Bottom Choice Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0E0C0A),
              border: Border(top: BorderSide(color: Color(0xFF262018), width: 1.0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: currentChoices.map((choice) {
                bool isGated = choice.requiredAttribute != null;
                bool canPass = true;
                if (isGated) {
                  canPass = attr.checkAttribute(
                      choice.requiredAttribute!, choice.attributeRequirement!);
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: InkWell(
                    onTap: () => _makeChoice(choice, playerState),
                    child: EtchedContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      borderColor: canPass ? const Color(0xFF332E26) : const Color(0xFF1C1A16),
                      backgroundColor: canPass ? const Color(0xFF161412) : const Color(0xFF100E0C),
                      child: Row(
                        children: [
                          Text(
                            choice.numeral,
                            style: VitruvianTypography.serifTitle(
                              fontSize: 16,
                              color: canPass ? const Color(0xFF888078) : const Color(0xFF44403C),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              choice.text,
                              style: VitruvianTypography.serifBody(
                                fontSize: 16,
                                color: canPass ? const Color(0xFFE4DCD0) : const Color(0xFF55504C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }
}
