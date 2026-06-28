import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../game/story_engine.dart';
import '../../models/story_models.dart';
import '../../states/player_state.dart';
import '../widgets/etched_container.dart';

class ChronicleScreen extends StatelessWidget {
  const ChronicleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storyEngine = Get.find<StoryEngine>();

    return Obx(() {
      // Loading state
      if (storyEngine.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: VitruvianColors.sepiaUmber),
        );
      }

      final node = storyEngine.currentNode.value;

      // No node loaded (error / empty state)
      if (node == null) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.menu_book_outlined,
                  size: 64, color: VitruvianColors.sepiaUmber),
              const SizedBox(height: 16),
              Text(
                'THE CHRONICLE AWAITS...',
                style: VitruvianTypography.serifTitle(
                  fontSize: 18,
                  color: VitruvianColors.agedBone,
                ),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Scrollable Narrative Manuscript Body
          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Chapter / Node title
                  Text(
                    node.title,
                    style: VitruvianTypography.serifTitle(
                      fontSize: 13,
                      color: const Color(0xFF6A5E52),
                    ).copyWith(letterSpacing: 2.0),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Dynamic paragraphs
                  ...node.paragraphs.map((paragraph) => Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: Text(
                          paragraph,
                          style: VitruvianTypography.serifBody(
                            fontSize: 16,
                            height: 1.65,
                            color: const Color(0xFFDCD4C8),
                          ),
                        ),
                      )),

                  // Ambient note (if present)
                  if (node.ambientNote != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      node.ambientNote!,
                      style: VitruvianTypography.serifBody(
                        fontSize: 13,
                        color: const Color(0xFF5A5248),
                      ).copyWith(fontStyle: FontStyle.italic),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Loot callout (if present)
                  if (node.lootCallout != null) ...[
                    _LootCalloutWidget(
                      nodeId: node.id,
                      lootText: node.lootCallout!,
                      storyEngine: storyEngine,
                    ),
                    const SizedBox(height: 24),
                  ],

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Docked Bottom Choice Panel
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF0E0C0A),
              border:
                  Border(top: BorderSide(color: Color(0xFF262018), width: 1.0)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: node.choices.map((choice) {
                return _ChoiceButton(
                  choice: choice,
                  storyEngine: storyEngine,
                );
              }).toList(),
            ),
          ),
        ],
      );
    });
  }
}

class _ChoiceButton extends StatelessWidget {
  final Choice choice;
  final StoryEngine storyEngine;

  const _ChoiceButton({
    required this.choice,
    required this.storyEngine,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGated = choice.requiredAttribute != null;
    final bool canPass = storyEngine.canPassGate(choice);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: () {
          if (isGated && !canPass) {
            final playerState = Get.find<PlayerState>();
            final attrName = choice.requiredAttribute ?? 'attribute';
            final currentVal = playerState.attributes.value
                .getAttributeValue(attrName);
            Get.snackbar(
              'INSUFFICIENT ${attrName.toUpperCase()}',
              'This action requires at least ${choice.attributeRequirement} $attrName. Current: $currentVal.',
              backgroundColor: VitruvianColors.rustBlood,
              colorText: Colors.white,
              borderRadius: 0,
              margin: const EdgeInsets.all(12),
            );
            return;
          }
          storyEngine.makeChoice(choice);
        },
        child: EtchedContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          borderColor:
              canPass ? const Color(0xFF332E26) : const Color(0xFF1C1A16),
          backgroundColor:
              canPass ? const Color(0xFF161412) : const Color(0xFF100E0C),
          child: Row(
            children: [
              if (choice.numeral != null) ...[
                Text(
                  choice.numeral!,
                  style: VitruvianTypography.serifTitle(
                    fontSize: 16,
                    color: canPass
                        ? const Color(0xFF888078)
                        : const Color(0xFF44403C),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  choice.text,
                  style: VitruvianTypography.serifBody(
                    fontSize: 16,
                    color: canPass
                        ? const Color(0xFFE4DCD0)
                        : const Color(0xFF55504C),
                  ),
                ),
              ),
              if (isGated && !canPass)
                const Icon(Icons.lock_outline,
                    size: 16, color: Color(0xFF44403C)),
              if (choice.nextChapterId != null)
                const Icon(Icons.arrow_forward,
                    size: 16, color: Color(0xFF6A5E52)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LootCalloutWidget extends StatefulWidget {
  final String nodeId;
  final String lootText;
  final StoryEngine storyEngine;

  const _LootCalloutWidget({
    required this.nodeId,
    required this.lootText,
    required this.storyEngine,
  });

  @override
  State<_LootCalloutWidget> createState() => _LootCalloutWidgetState();
}

class _LootCalloutWidgetState extends State<_LootCalloutWidget> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isClaimed = widget.storyEngine.claimedLootNodeIds.contains(widget.nodeId);

      if (isClaimed) {
        return EtchedContainer(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderColor: const Color(0xFF242018),
          backgroundColor: const Color(0xFF080706),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Color(0xFF6A5E52), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.lootText,
                  style: VitruvianTypography.monospaceData(
                    fontSize: 13,
                    color: const Color(0xFF6A5E52),
                  ).copyWith(decoration: TextDecoration.lineThrough),
                ),
              ),
              Text(
                'CLAIMED',
                style: VitruvianTypography.monospaceData(
                  fontSize: 11,
                  color: const Color(0xFF6A5E52),
                ),
              ),
            ],
          ),
        );
      }

      return MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: () => _pickUp(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: _isHovered ? const Color(0xFF1A1610) : const Color(0xFF0C0A08),
              border: Border.all(
                color: _isHovered ? VitruvianColors.goldLeaf : const Color(0xFF383024),
                width: 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: _isHovered ? VitruvianColors.goldLeaf : const Color(0xFFC0A070),
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.lootText,
                    style: VitruvianTypography.monospaceData(
                      fontSize: 13,
                      color: _isHovered ? VitruvianColors.goldLeaf : const Color(0xFFC0A070),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHovered ? 1.0 : 0.7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _isHovered ? VitruvianColors.goldLeaf : const Color(0xFF262018),
                      border: Border.all(color: VitruvianColors.goldLeaf),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.pan_tool_alt_outlined,
                          size: 13,
                          color: _isHovered ? const Color(0xFF0C0A08) : VitruvianColors.goldLeaf,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'PICK UP',
                          style: VitruvianTypography.monospaceData(
                            fontSize: 11,
                            color: _isHovered ? const Color(0xFF0C0A08) : VitruvianColors.goldLeaf,
                          ).copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  void _pickUp() {
    widget.storyEngine.claimLoot(widget.nodeId, widget.lootText);
    String itemName = widget.lootText
        .replaceAll('Loot Uncovered:', '')
        .replaceAll('Acquired:', '')
        .trim();
    Get.snackbar(
      'LOOT ACQUIRED',
      '$itemName has been added to your inventory.',
      backgroundColor: VitruvianColors.goldLeaf,
      colorText: const Color(0xFF0C0A08),
      icon: const Icon(Icons.check_circle, color: Color(0xFF0C0A08)),
      duration: const Duration(seconds: 3),
      borderRadius: 0,
      margin: const EdgeInsets.all(12),
    );
  }
}
