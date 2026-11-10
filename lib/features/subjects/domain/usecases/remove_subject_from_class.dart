import '../repositories/subject_repository.dart';

class RemoveSubjectFromClass {
  const RemoveSubjectFromClass(this._repository);

  final SubjectRepository _repository;

  Future<void> call(String classSubjectId) =>
      _repository.removeSubjectFromClass(classSubjectId);
}
