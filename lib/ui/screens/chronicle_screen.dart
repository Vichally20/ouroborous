import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/typography.dart';
import '../../game/story_engine.dart';
import '../../models/story_models.dart';
import '../../states/player_state.dart';
import '../widgets/etched_container.dart';
import '../widgets/toast.dart';

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

      final choices = storyEngine.visibleChoices(node);
      return Column(
        children: [
          // Scrollable manuscript: the scene, then its choices underneath (so a scene
          // with many choices never squeezes its own text off the screen). A new scene,
          // or a new outcome within one, opens scrolled to the top.
          Expanded(
            child: SingleChildScrollView(
              key: ValueKey('${node.id}|${storyEngine.lastResult.value}|${storyEngine.visitedNodeIds.length}'),
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

                  // What the last choice did
                  if (storyEngine.lastResult.value != null) ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: const BoxDecoration(
                        border: Border(left: BorderSide(color: VitruvianColors.goldLeaf, width: 2)),
                        color: Color(0xFF14110D),
                      ),
                      child: Text(
                        storyEngine.lastResult.value!,
                        style: VitruvianTypography.serifBody(fontSize: 15, color: VitruvianColors.goldLeaf)
                            .copyWith(fontStyle: FontStyle.italic, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Dynamic paragraphs (only those whose conditions hold)
                  ...storyEngine.visibleParagraphs(node).map((paragraph) => Padding(
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

                  // Choices
                  if (choices.isNotEmpty) ...[
                    Row(
                      children: [
                        Expanded(child: Container(height: 1, color: const Color(0xFF262018))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('WHAT DO YOU DO?',
                              style: VitruvianTypography.monospaceData(fontSize: 10, color: const Color(0xFF6A5E52))
                                  .copyWith(letterSpacing: 2)),
                        ),
                        Expanded(child: Container(height: 1, color: const Color(0xFF262018))),
                      ],
                    ),
                    const SizedBox(height: 14),
                    for (final (i, choice) in choices.indexed)
                      _ChoiceButton(
                        choice: choice,
                        numeral: choice.numeral ?? '${_roman(i + 1)}.',
                        storyEngine: storyEngine,
                      ),
                  ],
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      );
    });
  }
}

String _roman(int n) => const ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X'].elementAtOrNull(n - 1) ?? '$n';

class _ChoiceButton extends StatelessWidget {
  final Choice choice;
  final String numeral;
  final StoryEngine storyEngine;

  const _ChoiceButton({
    required this.choice,
    required this.numeral,
    required this.storyEngine,
  });

  @override
  Widget build(BuildContext context) {
    final bool canPass = !storyEngine.isLocked(choice);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: () {
          if (!canPass) {
            if (choice.requiredAttribute != null && !storyEngine.canPassGate(choice)) {
              final playerState = Get.find<PlayerState>();
              final attrName = choice.requiredAttribute!;
              final currentVal = playerState.attributes.value.getAttributeValue(attrName);
              showToast('INSUFFICIENT ${attrName.toUpperCase()}', 'This action requires at least ${choice.attributeRequirement} $attrName. Current: $currentVal.', tone: ToastTone.danger);
            } else {
              showToast('NOT YET', 'Needs ${choice.needsLabel ?? 'something you lack'}.', tone: ToastTone.danger);
            }
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
              ...[
                Text(
                  numeral,
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
                  storyEngine.render(choice.text),
                  style: VitruvianTypography.serifBody(
                    fontSize: 16,
                    color: canPass
                        ? const Color(0xFFE4DCD0)
                        : const Color(0xFF55504C),
                  ),
                ),
              ),
              if (!canPass) ...[
                if (choice.needsLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Text(choice.needsLabel!.toUpperCase(),
                        style: VitruvianTypography.monospaceData(fontSize: 10, color: const Color(0xFF6A5E52))),
                  ),
                const Icon(Icons.lock_outline, size: 16, color: Color(0xFF44403C)),
              ],
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
    showToast('LOOT ACQUIRED', '$itemName has been added to your inventory.', tone: ToastTone.loot, duration: const Duration(seconds: 3));
  }
}
