import '../entities/school.dart';

abstract class SchoolRepository {
  Stream<List<School>> watchSchools();
  Future<List<School>> getSchools();
  Future<School?> getSchoolById(String id);
  Future<void> createSchool({
    required String name,
    required String type,
    required String city,
    String? address,
  });
  Future<void> updateSchool({
    required String id,
    required String name,
    required String type,
    required String city,
    String? address,
  });
  Future<void> deleteSchool(String id);
}
