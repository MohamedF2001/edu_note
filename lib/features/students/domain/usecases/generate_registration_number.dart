import '../repositories/student_repository.dart';

class GenerateRegistrationNumber {
  const GenerateRegistrationNumber(this._repository);

  final StudentRepository _repository;

  Future<String> call(String classId) =>
      _repository.generateNextRegistrationNumber(classId);
}
