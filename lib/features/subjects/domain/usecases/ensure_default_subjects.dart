import '../repositories/subject_repository.dart';

class EnsureDefaultSubjects {
  const EnsureDefaultSubjects(this._repository);

  final SubjectRepository _repository;

  Future<void> call() => _repository.ensureDefaultSubjects();
}
