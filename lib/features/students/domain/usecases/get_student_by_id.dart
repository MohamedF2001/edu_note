import '../entities/student.dart';
import '../repositories/student_repository.dart';

class GetStudentById {
  const GetStudentById(this._repository);

  final StudentRepository _repository;

  Future<Student?> call(String id) => _repository.getStudentById(id);
}
