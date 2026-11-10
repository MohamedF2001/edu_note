import '../repositories/subject_repository.dart';

class UpdateSubject {
  const UpdateSubject(this._repository);

  final SubjectRepository _repository;

  Future<void> call({required String id, required String name}) =>
      _repository.updateSubject(id: id, name: name);
}
