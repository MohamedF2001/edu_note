import '../entities/student.dart';

abstract class StudentRepository {
  Future<List<Student>> getStudentsByClass(
    String classId, {
    String? searchQuery,
    String? sortBy,
  });
  Future<Student?> getStudentById(String id);
  Future<void> createStudent({
    required String classId,
    required String firstName,
    required String lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? registrationNumber,
    int? orderNumber,
  });
  Future<void> updateStudent({
    required String id,
    required String firstName,
    required String lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? registrationNumber,
    int? orderNumber,
  });
  Future<void> deleteStudent(String id);
  Future<String> generateNextRegistrationNumber(String classId);
}
