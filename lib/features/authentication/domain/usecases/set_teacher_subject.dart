import '../repositories/teacher_repository.dart';

class SetTeacherSubject {
  const SetTeacherSubject(this._repository);

  final TeacherRepository _repository;

  Future<void> call(String subjectName) =>
      _repository.setTeacherSubject(subjectName);
}
