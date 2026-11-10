import '../repositories/academic_year_repository.dart';

class SetActiveAcademicYear {
  const SetActiveAcademicYear(this._repository);

  final AcademicYearRepository _repository;

  Future<void> call(String id) => _repository.setActiveAcademicYear(id);
}
