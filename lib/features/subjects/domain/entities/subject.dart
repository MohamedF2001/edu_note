class Subject {
  const Subject({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.normalizedName,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String name;
  final String normalizedName;
  final DateTime createdAt;
  final DateTime updatedAt;
}
