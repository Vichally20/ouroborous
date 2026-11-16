// Data models for the JSON-driven story engine.
// Each chapter is stored as a separate JSON file in assets/story/.
// Conditions and effects use the language in lib/game/story_logic.dart.

import '../game/story_logic.dart';

class Choice {
  final String id;
  final String text;
  final String? numeral;
  final String? nextNodeId;
  final String? nextChapterId;
  final String? triggerEvent;
  final String? victoryNodeId;

  /// Where a lost fight goes instead of the defeat screen's checkpoint reload.
  final String? defeatNodeId;
  final String? unlockLocationId;
  final String? unlockCityId;
  final String? requiredAttribute;
  final int? attributeRequirement;

  /// Shown only while this condition holds (`showIf` / `"if"` in JSON).
  final String? showIf;

  /// Shown but locked until this condition holds; [needsLabel] says what it needs.
  final String? needs;
  final String? needsLabel;

  /// Gone once picked.
  final bool once;

  /// Picking any choice in a group (in this scene) removes the others.
  final String? group;

  final List<StoryEffectEntry> effects;

  /// One line shown at the top of the next scene, saying what just happened.
  final String? result;

  /// A test made when the choice is picked. On failure, [failEffects] apply
  /// instead of [effects], [failResult] is shown, and [failNextNodeId] (if set) is followed.
  final String? check;
  final List<StoryEffectEntry> failEffects;
  final String? failResult;
  final String? failNextNodeId;

  const Choice({
    required this.id,
    required this.text,
    this.numeral,
    this.nextNodeId,
    this.nextChapterId,
    this.triggerEvent,
    this.victoryNodeId,
    this.defeatNodeId,
    this.unlockLocationId,
    this.unlockCityId,
    this.requiredAttribute,
    this.attributeRequirement,
    this.showIf,
    this.needs,
    this.needsLabel,
    this.once = false,
    this.group,
    this.effects = const [],
    this.result,
    this.check,
    this.failEffects = const [],
    this.failResult,
    this.failNextNodeId,
  });

  /// Every condition this choice carries, for validating chapter files.
  Iterable<String> get conditions => [
        ?showIf,
        ?needs,
        ?check,
        for (final e in [...effects, ...failEffects]) ?e.condition,
      ];

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      id: json['id'] as String,
      text: json['text'] as String,
      numeral: json['numeral'] as String?,
      nextNodeId: json['nextNodeId'] as String?,
      nextChapterId: json['nextChapterId'] as String?,
      triggerEvent: json['triggerEvent'] as String?,
      victoryNodeId: json['victoryNodeId'] as String?,
      defeatNodeId: json['defeatNodeId'] as String?,
      unlockLocationId: json['unlockLocationId'] as String? ?? json['unlock_location'] as String?,
      unlockCityId: json['unlockCityId'] as String? ?? json['unlock_city'] as String?,
      requiredAttribute: json['requiredAttribute'] as String?,
      attributeRequirement: json['attributeRequirement'] as int?,
      showIf: json['if'] as String? ?? json['showIf'] as String?,
      needs: json['needs'] as String?,
      needsLabel: json['needsLabel'] as String?,
      once: json['once'] as bool? ?? false,
      group: json['group'] as String?,
      effects: StoryEffectEntry.listFromJson(json['effects']),
      result: json['result'] as String?,
      check: json['check'] as String?,
      failEffects: StoryEffectEntry.listFromJson(json['failEffects']),
      failResult: json['failResult'] as String?,
      failNextNodeId: json['failNextNodeId'] as String?,
    );
  }
}

/// A paragraph, optionally shown only when [showIf] holds.
class StoryParagraph {
  final String text;
  final String? showIf;
  const StoryParagraph(this.text, [this.showIf]);

  /// Reads `"text"` or `{"if": "ran_at_once", "text": "..."}`.
  factory StoryParagraph.fromJson(Object json) => json is String
      ? StoryParagraph(json)
      : StoryParagraph((json as Map)['text'] as String, json['if'] as String?);
}

class StoryNode {
  final String id;
  final String title;
  final List<StoryParagraph> paragraphs;
  final List<Choice> choices;
  final String? lootCallout;
  final String? ambientNote;

  /// Applied the first time the scene is entered.
  final List<StoryEffectEntry> onEnter;

  const StoryNode({
    required this.id,
    required this.title,
    required this.paragraphs,
    required this.choices,
    this.lootCallout,
    this.ambientNote,
    this.onEnter = const [],
  });

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'] as String,
      title: json['title'] as String,
      paragraphs: [for (final p in json['paragraphs'] as List) StoryParagraph.fromJson(p as Object)],
      choices: (json['choices'] as List? ?? const [])
          .map((c) => Choice.fromJson(c as Map<String, dynamic>))
          .toList(),
      lootCallout: json['lootCallout'] as String?,
      ambientNote: json['ambientNote'] as String?,
      onEnter: StoryEffectEntry.listFromJson(json['onEnter']),
    );
  }
}

class Chapter {
  final String id;
  final String title;
  final String startNodeId;
  final Map<String, StoryNode> nodes;

  const Chapter({
    required this.id,
    required this.title,
    required this.startNodeId,
    required this.nodes,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    final nodesMap = <String, StoryNode>{};
    final nodesJson = json['nodes'] as Map<String, dynamic>;
    for (final entry in nodesJson.entries) {
      nodesMap[entry.key] =
          StoryNode.fromJson(entry.value as Map<String, dynamic>);
    }

    return Chapter(
      id: json['id'] as String,
      title: json['title'] as String,
      startNodeId: json['startNodeId'] as String,
      nodes: nodesMap,
    );
  }
}
