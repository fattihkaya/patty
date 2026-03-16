import 'dart:convert';

import 'condition_model.dart';

class LogModel {
  static const List<String> healthParameterKeys = [
    'fur_luster',
    'skin_hygiene',
    'eye_clarity',
    'nasal_discharge',
    'ear_posture',
    'weight_index',
    'posture_alignment',
    'facial_relaxation',
    'energy_vibe',
    'stress_level',
  ];

  final String id;
  final String petId;
  final String photoUrl;
  final String aiComment;
  final DateTime createdAt;
  final String? moodLabel;
  final int? moodScore;
  final int? energyScore;
  final String? summaryTr;
  final String? careTipTr;
  final double? confidence;
  final String? petVoiceTr;

  // 10 granular health parameters (scores only; notes are stored inside [notesMap]).
  final int? furLusterScore;
  final int? skinHygieneScore;
  final int? eyeClarityScore;
  final int? nasalDischargeScore;
  final int? earPostureScore;
  final int? weightIndexScore;
  final int? postureAlignmentScore;
  final int? facialRelaxationScore;
  final int? energyVibeScore;
  final int? stressLevelScore;

  /// Map of parameter -> note (e.g. { "fur_luster": "..." }).
  final Map<String, String>? notesMap;

  /// Optional trend cache for last 7 data points per parameter.
  final Map<String, List<double>>? trendSeries;

  final String? healthNote;
  final List<ConditionModel> aiConditions;
  final List<ConditionModel> confirmedConditions;

  const LogModel({
    required this.id,
    required this.petId,
    required this.photoUrl,
    required this.aiComment,
    required this.createdAt,
    this.moodLabel,
    this.moodScore,
    this.energyScore,
    this.summaryTr,
    this.careTipTr,
    this.confidence,
    this.petVoiceTr,
    this.furLusterScore,
    this.skinHygieneScore,
    this.eyeClarityScore,
    this.nasalDischargeScore,
    this.earPostureScore,
    this.weightIndexScore,
    this.postureAlignmentScore,
    this.facialRelaxationScore,
    this.energyVibeScore,
    this.stressLevelScore,
    this.notesMap,
    this.trendSeries,
    this.healthNote,
    this.aiConditions = const [],
    this.confirmedConditions = const [],
  });

  factory LogModel.fromJson(Map<String, dynamic> json) {
    final rawComment = json['ai_comment'] ?? '';
    Map<String, dynamic>? parsed;
    if (rawComment is String) {
      try {
        parsed = jsonDecode(rawComment) as Map<String, dynamic>?;
      } catch (_) {
        parsed = null;
      }
    }

    return LogModel(
      id: json['id'],
      petId: json['pet_id'],
      photoUrl: json['photo_url'],
      aiComment: rawComment,
      createdAt: DateTime.parse(json['created_at']).toLocal(),
      moodLabel: parsed?['mood_label'] as String?,
      moodScore: (parsed?['mood_score'] as num?)?.round(),
      energyScore: (parsed?['energy_score'] as num?)?.round(),
      summaryTr: parsed?['summary_tr'] as String?,
      careTipTr: parsed?['care_tip_tr'] as String?,
      confidence: (parsed?['confidence'] as num?)?.toDouble(),
      petVoiceTr: parsed?['pet_voice_tr'] as String?,
      furLusterScore: (parsed?['fur_luster_score'] as num?)?.round(),
      skinHygieneScore: (parsed?['skin_hygiene_score'] as num?)?.round(),
      eyeClarityScore: (parsed?['eye_clarity_score'] as num?)?.round(),
      nasalDischargeScore: (parsed?['nasal_discharge_score'] as num?)?.round(),
      earPostureScore: (parsed?['ear_posture_score'] as num?)?.round(),
      weightIndexScore: (parsed?['weight_index_score'] as num?)?.round(),
      postureAlignmentScore:
          (parsed?['posture_alignment_score'] as num?)?.round(),
      facialRelaxationScore:
          (parsed?['facial_relaxation_score'] as num?)?.round(),
      energyVibeScore: (parsed?['energy_vibe_score'] as num?)?.round(),
      stressLevelScore: (parsed?['stress_level_score'] as num?)?.round(),
      notesMap: _parseNotes(parsed?['notes']) ?? _legacyNotes(parsed),
      trendSeries: _parseTrendSeries(json['trend_series']),
      healthNote: json['health_note'] as String?,
      aiConditions: ConditionModel.listFromJson(json['ai_conditions']),
      confirmedConditions:
          ConditionModel.listFromJson(json['confirmed_conditions']),
    );
  }

  static Map<String, String>? _legacyNotes(Map<String, dynamic>? parsed) {
    if (parsed == null) return null;
    final map = <String, String>{};

    void tryAdd(String key, String? value) {
      if (value != null && value.trim().isNotEmpty) {
        map[key] = value.trim();
      }
    }

    tryAdd('fur_luster', parsed['coat_notes_tr'] as String?);
    tryAdd('eye_clarity', parsed['eye_notes_tr'] as String?);
    tryAdd('weight_index', parsed['body_notes_tr'] as String?);
    tryAdd('stress_level', parsed['stress_trigger_tr'] as String?);

    return map.isEmpty ? null : map;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pet_id': petId,
      'photo_url': photoUrl,
      'ai_comment': aiComment,
      'created_at': createdAt.toIso8601String(),
      'health_note': healthNote,
      'ai_conditions': aiConditions.map((c) => c.toJson()).toList(),
      'confirmed_conditions':
          confirmedConditions.map((c) => c.toJson()).toList(),
      'notes': notesMap,
      'trend_series': trendSeries,
    };
  }

  static Map<String, String>? _parseNotes(dynamic raw) {
    if (raw is Map) {
      return raw.map((key, value) {
        final k = key?.toString();
        return MapEntry(
          k ?? '',
          value?.toString() ?? '',
        );
      })..removeWhere((key, value) => key.isEmpty);
    }
    return null;
  }

  static Map<String, List<double>>? _parseTrendSeries(dynamic raw) {
    if (raw is Map) {
      final result = <String, List<double>>{};
      raw.forEach((key, value) {
        final stringKey = key?.toString();
        if (stringKey == null) return;
        if (value is List) {
          result[stringKey] = value
              .whereType<num>()
              .map((e) => e.toDouble())
              .toList(growable: false);
        }
      });
      return result.isEmpty ? null : result;
    }
    return null;
  }

  String? noteFor(String parameterKey) => notesMap?[parameterKey];
  Map<String, int?> get parameterScores => {
        'fur_luster': furLusterScore,
        'skin_hygiene': skinHygieneScore,
        'eye_clarity': eyeClarityScore,
        'nasal_discharge': nasalDischargeScore,
        'ear_posture': earPostureScore,
        'weight_index': weightIndexScore,
        'posture_alignment': postureAlignmentScore,
        'facial_relaxation': facialRelaxationScore,
        'energy_vibe': energyVibeScore,
        'stress_level': stressLevelScore,
      };

  int? scoreFor(String parameterKey) => parameterScores[parameterKey];

  LogModel copyWith({
    Map<String, List<double>>? trendSeries,
  }) {
    return LogModel(
      id: id,
      petId: petId,
      photoUrl: photoUrl,
      aiComment: aiComment,
      createdAt: createdAt,
      moodLabel: moodLabel,
      moodScore: moodScore,
      energyScore: energyScore,
      summaryTr: summaryTr,
      careTipTr: careTipTr,
      confidence: confidence,
      petVoiceTr: petVoiceTr,
      furLusterScore: furLusterScore,
      skinHygieneScore: skinHygieneScore,
      eyeClarityScore: eyeClarityScore,
      nasalDischargeScore: nasalDischargeScore,
      earPostureScore: earPostureScore,
      weightIndexScore: weightIndexScore,
      postureAlignmentScore: postureAlignmentScore,
      facialRelaxationScore: facialRelaxationScore,
      energyVibeScore: energyVibeScore,
      stressLevelScore: stressLevelScore,
      notesMap: notesMap,
      trendSeries: trendSeries ?? this.trendSeries,
      healthNote: healthNote,
      aiConditions: aiConditions,
      confirmedConditions: confirmedConditions,
    );
  }
}
