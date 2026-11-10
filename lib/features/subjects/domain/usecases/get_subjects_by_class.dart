import '../entities/class_subject.dart';
import '../repositories/subject_repository.dart';

class GetSubjectsByClass {
  const GetSubjectsByClass(this._repository);

  final SubjectRepository _repository;

  Future<List<ClassSubject>> call(String classId) =>
      _repository.getSubjectsByClass(classId);
}
