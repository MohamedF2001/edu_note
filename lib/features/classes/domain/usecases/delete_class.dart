import '../repositories/class_repository.dart';

class DeleteClass {
  const DeleteClass(this._repository);

  final ClassRepository _repository;

  Future<void> call(String id) => _repository.deleteClass(id);
}
