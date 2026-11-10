import '../entities/grade.dart';
import '../repositories/evaluation_repository.dart';

class GetGradesByStudentAndClassSubject {
  const GetGradesByStudentAndClassSubject(this._repository);
  final EvaluationRepository _repository;

  Future<List<Grade>> call({
    required String studentId,
    required String classSubjectId,
  }) =>
      _repository.getGradesByStudentAndClassSubject(
        studentId: studentId,
        classSubjectId: classSubjectId,
      );
}
