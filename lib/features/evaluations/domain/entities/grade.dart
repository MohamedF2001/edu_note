enum GradeStatus { recorded, absent, notRecorded }

class Grade {
  const Grade({
    required this.id,
    required this.evaluationId,
    required this.studentId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.score,
  });

  final String id;
  final String evaluationId;
  final String studentId;
  final GradeStatus status;
  final double? score;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get hasScore => status == GradeStatus.recorded && score != null;
}
