import '../entities/evaluation.dart';
import '../repositories/evaluation_repository.dart';

class CreateEvaluation {
  const CreateEvaluation(this._repository);
  final EvaluationRepository _repository;

  Future<Evaluation> call({
    required String classSubjectId,
    required String academicPeriodId,
    required EvaluationType type,
    required DateTime evaluationDate,
    required double maxScore,
    String? title,
  }) =>
      _repository.createEvaluation(
        classSubjectId: classSubjectId,
        academicPeriodId: academicPeriodId,
        type: type,
        evaluationDate: evaluationDate,
        maxScore: maxScore,
        title: title,
      );
}
