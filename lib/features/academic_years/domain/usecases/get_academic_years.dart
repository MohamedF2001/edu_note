import '../entities/academic_year.dart';
import '../repositories/academic_year_repository.dart';

class GetAcademicYears {
  const GetAcademicYears(this._repository);

  final AcademicYearRepository _repository;

  Future<List<AcademicYear>> call() => _repository.getAcademicYears();
}
