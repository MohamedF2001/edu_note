import '../entities/student.dart';
import '../repositories/student_repository.dart';

class GetStudentsByClass {
  const GetStudentsByClass(this._repository);

  final StudentRepository _repository;

  Future<List<Student>> call(
    String classId, {
    String? searchQuery,
    String? sortBy,
  }) =>
      _repository.getStudentsByClass(
        classId,
        searchQuery: searchQuery,
        sortBy: sortBy,
      );
}
