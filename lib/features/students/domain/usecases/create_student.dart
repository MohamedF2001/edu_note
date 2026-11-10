import '../repositories/student_repository.dart';

class CreateStudent {
  const CreateStudent(this._repository);

  final StudentRepository _repository;

  Future<void> call({
    required String classId,
    required String firstName,
    required String lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? registrationNumber,
    int? orderNumber,
  }) =>
      _repository.createStudent(
        classId: classId,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        registrationNumber: registrationNumber,
        orderNumber: orderNumber,
      );
}
