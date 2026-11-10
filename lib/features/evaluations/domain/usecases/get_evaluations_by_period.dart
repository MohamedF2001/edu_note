import '../entities/evaluation.dart';
import '../repositories/evaluation_repository.dart';

class GetEvaluationsByPeriod {
  const GetEvaluationsByPeriod(this._repository);
  final EvaluationRepository _repository;

  Future<List<Evaluation>> call({
    required String classSubjectId,
    required String academicPeriodId,
  }) =>
      _repository.getEvaluationsByPeriod(
        classSubjectId: classSubjectId,
        academicPeriodId: academicPeriodId,
      );
}
