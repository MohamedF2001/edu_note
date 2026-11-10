import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/school.dart' as domain;
import '../../domain/repositories/school_repository.dart';

class SchoolRepositoryImpl implements SchoolRepository {
  SchoolRepositoryImpl(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  @override
  Stream<List<domain.School>> watchSchools() {
    return (_database.select(_database.schools)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(_mapToDomain).toList());
  }

  @override
  Future<List<domain.School>> getSchools() async {
    final rows = await (_database.select(_database.schools)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<domain.School?> getSchoolById(String id) async {
    final row = await (_database.select(_database.schools)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> createSchool({
    required String name,
    required String type,
    required String city,
    String? address,
  }) async {
    final teacher =
        await (_database.select(_database.teachers)).getSingleOrNull();
    if (teacher == null) {
      throw StateError(
        'Aucun profil enseignant trouvé pour créer un établissement.',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database.into(_database.schools).insert(
          SchoolsCompanion.insert(
            id: id,
            teacherId: teacher.id,
            name: name.trim(),
            type: type.trim(),
            city: city.trim(),
            address: Value(address?.trim()),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> updateSchool({
    required String id,
    required String name,
    required String type,
    required String city,
    String? address,
  }) async {
    await (_database.update(_database.schools)..where((t) => t.id.equals(id)))
        .write(
      SchoolsCompanion(
        name: Value(name.trim()),
        type: Value(type.trim()),
        city: Value(city.trim()),
        address: Value(address?.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteSchool(String id) async {
    await _database.transaction(() async {
      await (_database.delete(_database.schools)..where((t) => t.id.equals(id)))
          .go();
    });
  }

  domain.School _mapToDomain(School row) {
    return domain.School(
      id: row.id,
      teacherId: row.teacherId,
      name: row.name,
      type: row.type,
      city: row.city,
      address: row.address,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
