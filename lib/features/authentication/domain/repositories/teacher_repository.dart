import '../entities/teacher.dart';

abstract class TeacherRepository {
  Future<Teacher?> getTeacherProfile();
  Future<void> registerTeacher({
    required String firstName,
    required String lastName,
    required String profession,
    required String subjectName,
    required String whatsappNumber,
    required String password,
  });
  Future<bool> authenticateTeacher(String password);
  Future<void> setTeacherSubject(String subjectName);
}
