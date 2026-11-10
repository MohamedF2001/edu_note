class AcademicPeriod {
  const AcademicPeriod({
    required this.id,
    required this.academicYearId,
    required this.name,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String academicYearId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
}
