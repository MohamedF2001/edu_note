import '../repositories/class_repository.dart';

class UpdateClass {
  const UpdateClass(this._repository);

  final ClassRepository _repository;

  Future<void> call({
    required String id,
    required String name,
    required String level,
  }) =>
      _repository.updateClass(
        id: id,
        name: name,
        level: level,
      );
}
