import '../entities/academic_period.dart';
import '../entities/academic_year.dart';

abstract class AcademicYearRepository {
  Future<List<AcademicYear>> getAcademicYears();
  Future<AcademicYear?> getActiveAcademicYear();
  Future<void> setActiveAcademicYear(String id);
  Future<AcademicYear> createAcademicYear({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  });
  Future<List<AcademicPeriod>> getPeriodsByYear(String academicYearId);
  Future<void> createPeriod({
    required String academicYearId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  });
  Future<AcademicYear> ensureDefaultAcademicYear();
}
