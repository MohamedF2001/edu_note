import '../entities/school_class.dart';
import '../repositories/class_repository.dart';

class GetClassesBySchool {
  const GetClassesBySchool(this._repository);

  final ClassRepository _repository;

  Future<List<SchoolClass>> call(
    String schoolId, {
    String? academicYearId,
  }) =>
      _repository.getClassesBySchool(
        schoolId,
        academicYearId: academicYearId,
      );
}
