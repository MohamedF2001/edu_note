import '../repositories/teacher_repository.dart';

class RegisterTeacher {
  const RegisterTeacher(this._repository);

  final TeacherRepository _repository;

  Future<void> call({
    required String firstName,
    required String lastName,
    required String profession,
    required String subjectName,
    required String whatsappNumber,
    required String password,
  }) {
    return _repository.registerTeacher(
      firstName: firstName,
      lastName: lastName,
      profession: profession,
      subjectName: subjectName,
      whatsappNumber: whatsappNumber,
      password: password,
    );
  }
}
