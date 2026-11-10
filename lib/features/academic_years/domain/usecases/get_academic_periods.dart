import '../entities/academic_period.dart';
import '../repositories/academic_year_repository.dart';

class GetAcademicPeriods {
  const GetAcademicPeriods(this._repository);

  final AcademicYearRepository _repository;

  Future<List<AcademicPeriod>> call(String academicYearId) =>
      _repository.getPeriodsByYear(academicYearId);
}
