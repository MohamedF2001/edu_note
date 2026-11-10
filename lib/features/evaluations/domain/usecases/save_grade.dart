import '../entities/grade.dart';
import '../repositories/evaluation_repository.dart';

class SaveGrade {
  const SaveGrade(this._repository);
  final EvaluationRepository _repository;

  Future<Grade> call({
    required String schoolId,
    required String evaluationId,
    required String studentId,
    required GradeStatus status,
    double? score,
  }) => _repository.saveGrade(
    schoolId: schoolId,
    evaluationId: evaluationId,
    studentId: studentId,
    status: status,
    score: score,
  );
}
