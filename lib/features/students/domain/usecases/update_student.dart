import '../repositories/student_repository.dart';

class UpdateStudent {
  const UpdateStudent(this._repository);

  final StudentRepository _repository;

  Future<void> call({
    required String id,
    required String firstName,
    required String lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? registrationNumber,
    int? orderNumber,
  }) =>
      _repository.updateStudent(
        id: id,
        firstName: firstName,
        lastName: lastName,
        gender: gender,
        dateOfBirth: dateOfBirth,
        registrationNumber: registrationNumber,
        orderNumber: orderNumber,
      );
}
