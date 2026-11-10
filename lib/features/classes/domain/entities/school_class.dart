class SchoolClass {
  const SchoolClass({
    required this.id,
    required this.schoolId,
    required this.academicYearId,
    required this.name,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String academicYearId;
  final String name;
  final String level;
  final DateTime createdAt;
  final DateTime updatedAt;
}
