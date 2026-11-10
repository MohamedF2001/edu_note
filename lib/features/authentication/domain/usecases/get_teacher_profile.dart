import '../entities/teacher.dart';
import '../repositories/teacher_repository.dart';

class GetTeacherProfile {
  const GetTeacherProfile(this._repository);

  final TeacherRepository _repository;

  Future<Teacher?> call() {
    return _repository.getTeacherProfile();
  }
}
