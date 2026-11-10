import '../entities/school.dart';
import '../repositories/school_repository.dart';

class GetSchoolById {
  const GetSchoolById(this._repository);

  final SchoolRepository _repository;

  Future<School?> call(String id) => _repository.getSchoolById(id);
}
