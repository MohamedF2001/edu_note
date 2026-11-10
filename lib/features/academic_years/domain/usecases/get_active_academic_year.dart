import '../entities/academic_year.dart';
import '../repositories/academic_year_repository.dart';

class GetActiveAcademicYear {
  const GetActiveAcademicYear(this._repository);

  final AcademicYearRepository _repository;

  Future<AcademicYear?> call() => _repository.getActiveAcademicYear();
}
