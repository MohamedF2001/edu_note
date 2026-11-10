import '../entities/subject.dart';
import '../repositories/subject_repository.dart';

class GetSubjectById {
  const GetSubjectById(this._repository);

  final SubjectRepository _repository;

  Future<Subject?> call(String id) => _repository.getSubjectById(id);
}
