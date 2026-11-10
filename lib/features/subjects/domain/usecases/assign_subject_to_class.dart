import '../entities/class_subject.dart';
import '../repositories/subject_repository.dart';

class AssignSubjectToClass {
  const AssignSubjectToClass(this._repository);

  final SubjectRepository _repository;

  Future<ClassSubject> call({
    required String classId,
    required String subjectId,
  }) =>
      _repository.assignSubjectToClass(
        classId: classId,
        subjectId: subjectId,
      );
}
