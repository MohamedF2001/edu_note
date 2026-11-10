class AcademicYear {
  const AcademicYear({
    required this.id,
    required this.teacherId,
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  final String id;
  final String teacherId;
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
}
