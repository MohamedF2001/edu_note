import '../repositories/subject_repository.dart';

class DeleteSubject {
  const DeleteSubject(this._repository);

  final SubjectRepository _repository;

  Future<void> call(String id) => _repository.deleteSubject(id);
}
