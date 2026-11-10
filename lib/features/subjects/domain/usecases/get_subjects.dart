import '../entities/subject.dart';
import '../repositories/subject_repository.dart';

class GetSubjects {
  const GetSubjects(this._repository);

  final SubjectRepository _repository;

  Future<List<Subject>> call() => _repository.getSubjects();
}
