import '../entities/evaluation.dart';
import '../repositories/evaluation_repository.dart';

class GetEvaluationsByClassSubject {
  const GetEvaluationsByClassSubject(this._repository);
  final EvaluationRepository _repository;

  Future<List<Evaluation>> call(String classSubjectId) =>
      _repository.getEvaluationsByClassSubject(classSubjectId);
}
