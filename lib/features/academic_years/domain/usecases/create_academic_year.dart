import '../entities/academic_year.dart';
import '../repositories/academic_year_repository.dart';

class CreateAcademicYear {
  const CreateAcademicYear(this._repository);

  final AcademicYearRepository _repository;

  Future<AcademicYear> call({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  }) =>
      _repository.createAcademicYear(
        label: label,
        startDate: startDate,
        endDate: endDate,
        isActive: isActive,
      );
}
