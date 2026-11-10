import '../entities/class_subject.dart';
import '../entities/subject.dart';

abstract class SubjectRepository {
  Future<List<Subject>> getSubjects();
  Future<Subject?> getSubjectById(String id);
  Future<Subject> createSubject(String name);
  Future<void> updateSubject({required String id, required String name});
  Future<void> deleteSubject(String id);
  Future<List<ClassSubject>> getSubjectsByClass(String classId);
  Future<ClassSubject> assignSubjectToClass({
    required String classId,
    required String subjectId,
  });
  Future<void> removeSubjectFromClass(String classSubjectId);
  Future<void> ensureDefaultSubjects();
}
