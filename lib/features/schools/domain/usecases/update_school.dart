import '../repositories/school_repository.dart';

class UpdateSchool {
  const UpdateSchool(this._repository);

  final SchoolRepository _repository;

  Future<void> call({
    required String id,
    required String name,
    required String type,
    required String city,
    String? address,
  }) =>
      _repository.updateSchool(
        id: id,
        name: name,
        type: type,
        city: city,
        address: address,
      );
}
