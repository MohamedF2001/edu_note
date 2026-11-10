import '../entities/school_class.dart';

abstract class ClassRepository {
  Future<List<SchoolClass>> getClassesBySchool(
    String schoolId, {
    String? academicYearId,
  });
  Future<List<SchoolClass>> getAllClasses({String? academicYearId});
  Future<SchoolClass?> getClassById(String id);
  Future<void> createClass({
    required String schoolId,
    required String academicYearId,
    required String name,
    required String level,
  });
  Future<void> updateClass({
    required String id,
    required String name,
    required String level,
  });
  Future<void> deleteClass(String id);
}
