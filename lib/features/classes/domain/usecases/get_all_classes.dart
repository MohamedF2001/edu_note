import '../entities/school_class.dart';
import '../repositories/class_repository.dart';

class GetAllClasses {
  const GetAllClasses(this._repository);

  final ClassRepository _repository;

  Future<List<SchoolClass>> call({String? academicYearId}) =>
      _repository.getAllClasses(academicYearId: academicYearId);
}
