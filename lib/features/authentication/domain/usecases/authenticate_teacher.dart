import '../repositories/teacher_repository.dart';

class AuthenticateTeacher {
  const AuthenticateTeacher(this._repository);

  final TeacherRepository _repository;

  Future<bool> call(String password) {
    return _repository.authenticateTeacher(password);
  }
}
