// Helper class to combine task template with user assignments
class TaskDisplayData {
  final String name;
  final String? description;
  final int frequencyDays;
  final int points;
  final bool isActive;
  final String? notes;

  TaskDisplayData({
    required this.name,
    this.description,
    required this.frequencyDays,
    required this.points,
    this.isActive = true,
    this.notes,
  });
}
