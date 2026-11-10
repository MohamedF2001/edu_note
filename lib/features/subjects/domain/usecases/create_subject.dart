import '../entities/subject.dart';
import '../repositories/subject_repository.dart';

class CreateSubject {
  const CreateSubject(this._repository);

  final SubjectRepository _repository;

  Future<Subject> call(String name) => _repository.createSubject(name);
}
