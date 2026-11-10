import '../entities/grade.dart';
import '../repositories/evaluation_repository.dart';

class GetGradesByEvaluation {
  const GetGradesByEvaluation(this._repository);
  final EvaluationRepository _repository;

  Future<List<Grade>> call(String evaluationId) =>
      _repository.getGradesByEvaluation(evaluationId);
}
