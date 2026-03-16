import 'condition_model.dart';

class PreparedLogData {
  final String petId;
  final String photoUrl;
  final String aiComment;
  final List<ConditionModel> aiConditions;
  final Map<String, dynamic>? parsedAiJson;
  final Map<String, int?> parameterScores;
  final Map<String, String?> parameterNotes;

  const PreparedLogData({
    required this.petId,
    required this.photoUrl,
    required this.aiComment,
    required this.aiConditions,
    this.parsedAiJson,
    this.parameterScores = const {},
    this.parameterNotes = const {},
  });
}
