import '../entities/school.dart';
import '../repositories/school_repository.dart';

class GetSchools {
  const GetSchools(this._repository);

  final SchoolRepository _repository;

  Stream<List<School>> watch() => _repository.watchSchools();

  Future<List<School>> call() => _repository.getSchools();
}
