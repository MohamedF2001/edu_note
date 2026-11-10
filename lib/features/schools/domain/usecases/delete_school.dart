import '../repositories/school_repository.dart';

class DeleteSchool {
  const DeleteSchool(this._repository);

  final SchoolRepository _repository;

  Future<void> call(String id) => _repository.deleteSchool(id);
}
