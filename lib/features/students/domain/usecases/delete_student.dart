import '../repositories/student_repository.dart';

class DeleteStudent {
  const DeleteStudent(this._repository);

  final StudentRepository _repository;

  Future<void> call(String id) => _repository.deleteStudent(id);
}
