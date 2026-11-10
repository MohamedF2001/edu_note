import '../repositories/evaluation_repository.dart';

class DeleteEvaluation {
  const DeleteEvaluation(this._repository);
  final EvaluationRepository _repository;

  Future<void> call(String id) => _repository.deleteEvaluation(id);
}
