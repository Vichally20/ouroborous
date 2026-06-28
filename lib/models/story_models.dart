// Data models for the JSON-driven story engine.
// Each chapter is stored as a separate JSON file in assets/story/.

class Choice {
  final String id;
  final String text;
  final String? numeral;
  final String? nextNodeId;
  final String? nextChapterId;
  final String? triggerEvent;
  final String? victoryNodeId;
  final String? unlockLocationId;
  final String? unlockCityId;
  final String? requiredAttribute;
  final int? attributeRequirement;

  const Choice({
    required this.id,
    required this.text,
    this.numeral,
    this.nextNodeId,
    this.nextChapterId,
    this.triggerEvent,
    this.victoryNodeId,
    this.unlockLocationId,
    this.unlockCityId,
    this.requiredAttribute,
    this.attributeRequirement,
  });

  factory Choice.fromJson(Map<String, dynamic> json) {
    return Choice(
      id: json['id'] as String,
      text: json['text'] as String,
      numeral: json['numeral'] as String?,
      nextNodeId: json['nextNodeId'] as String?,
      nextChapterId: json['nextChapterId'] as String?,
      triggerEvent: json['triggerEvent'] as String?,
      victoryNodeId: json['victoryNodeId'] as String?,
      unlockLocationId: json['unlockLocationId'] as String? ?? json['unlock_location'] as String?,
      unlockCityId: json['unlockCityId'] as String? ?? json['unlock_city'] as String?,
      requiredAttribute: json['requiredAttribute'] as String?,
      attributeRequirement: json['attributeRequirement'] as int?,
    );
  }
}

class StoryNode {
  final String id;
  final String title;
  final List<String> paragraphs;
  final List<Choice> choices;
  final String? lootCallout;
  final String? ambientNote;

  const StoryNode({
    required this.id,
    required this.title,
    required this.paragraphs,
    required this.choices,
    this.lootCallout,
    this.ambientNote,
  });

  factory StoryNode.fromJson(Map<String, dynamic> json) {
    return StoryNode(
      id: json['id'] as String,
      title: json['title'] as String,
      paragraphs: List<String>.from(json['paragraphs'] as List),
      choices: (json['choices'] as List)
          .map((c) => Choice.fromJson(c as Map<String, dynamic>))
          .toList(),
      lootCallout: json['lootCallout'] as String?,
      ambientNote: json['ambientNote'] as String?,
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
