import 'package:flutter/material.dart';

class TalentNode {
  final String id;
  final String title;
  final String clinicalDescription;
  final Offset constellationPosition;
  final bool isUnlocked;
  final List<String> requiredParentIds;

  const TalentNode({
    required this.id,
    required this.title,
    required this.clinicalDescription,
    required this.constellationPosition,
    this.isUnlocked = false,
    this.requiredParentIds = const [],
  });
}
