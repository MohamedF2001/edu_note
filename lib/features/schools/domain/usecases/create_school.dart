import '../repositories/school_repository.dart';

class CreateSchool {
  const CreateSchool(this._repository);

  final SchoolRepository _repository;

  Future<void> call({
    required String name,
    required String type,
    required String city,
    String? address,
  }) =>
      _repository.createSchool(
        name: name,
        type: type,
        city: city,
        address: address,
      );
}
