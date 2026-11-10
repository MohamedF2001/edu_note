import '../repositories/class_repository.dart';

class CreateClass {
  const CreateClass(this._repository);

  final ClassRepository _repository;

  Future<void> call({
    required String schoolId,
    required String academicYearId,
    required String name,
    required String level,
  }) =>
      _repository.createClass(
        schoolId: schoolId,
        academicYearId: academicYearId,
        name: name,
        level: level,
      );
}
