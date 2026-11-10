import '../entities/grade.dart';
import '../repositories/evaluation_repository.dart';

class SaveGradesBatch {
  const SaveGradesBatch(this._repository);
  final EvaluationRepository _repository;

  Future<void> call({required String schoolId, required List<Grade> grades}) =>
      _repository.saveGradesBatch(schoolId: schoolId, grades: grades);
}
