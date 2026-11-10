import '../entities/school_class.dart';
import '../repositories/class_repository.dart';

class GetClassById {
  const GetClassById(this._repository);

  final ClassRepository _repository;

  Future<SchoolClass?> call(String id) => _repository.getClassById(id);
}
