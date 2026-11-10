import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/school_class.dart' as domain;
import '../../domain/repositories/class_repository.dart';

class ClassRepositoryImpl implements ClassRepository {
  ClassRepositoryImpl(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  @override
  Future<List<domain.SchoolClass>> getClassesBySchool(
    String schoolId, {
    String? academicYearId,
  }) async {
    final query = _database.select(_database.schoolClasses)
      ..where((t) => t.schoolId.equals(schoolId));

    if (academicYearId != null) {
      query.where((t) => t.academicYearId.equals(academicYearId));
    }

    query.orderBy([(t) => OrderingTerm.asc(t.name)]);

    final rows = await query.get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<List<domain.SchoolClass>> getAllClasses({
    String? academicYearId,
  }) async {
    final query = _database.select(_database.schoolClasses);

    if (academicYearId != null) {
      query.where((t) => t.academicYearId.equals(academicYearId));
    }

    query.orderBy([(t) => OrderingTerm.asc(t.name)]);

    final rows = await query.get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<domain.SchoolClass?> getClassById(String id) async {
    final row = await (_database.select(
      _database.schoolClasses,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> createClass({
    required String schoolId,
    required String academicYearId,
    required String name,
    required String level,
  }) async {
    final trimmedName = name.trim();
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    final school = await (_database.select(
      _database.schools,
    )..where((row) => row.id.equals(schoolId))).getSingleOrNull();
    final academicYear = await (_database.select(
      _database.academicYears,
    )..where((row) => row.id.equals(academicYearId))).getSingleOrNull();
    if (teacher == null ||
        school?.teacherId != teacher.id ||
        academicYear?.teacherId != teacher.id) {
      throw ArgumentError(
        'L’établissement et l’année doivent appartenir au profil enseignant actif.',
      );
    }

    final existing =
        await (_database.select(_database.schoolClasses)..where(
              (t) =>
                  t.schoolId.equals(schoolId) &
                  t.academicYearId.equals(academicYearId) &
                  t.name.equals(trimmedName),
            ))
            .getSingleOrNull();

    if (existing != null) {
      throw ArgumentError(
        'Une classe portant le nom "$trimmedName" existe déjà dans cet établissement pour cette année scolaire.',
      );
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database.transaction(() async {
      await _database
          .into(_database.schoolClasses)
          .insert(
            SchoolClassesCompanion.insert(
              id: id,
              schoolId: schoolId,
              academicYearId: academicYearId,
              name: trimmedName,
              level: level.trim(),
              createdAt: now,
              updatedAt: now,
            ),
          );
      final subjectId = teacher.subjectId;
      if (subjectId != null) {
        await _database
            .into(_database.classSubjects)
            .insert(
              ClassSubjectsCompanion.insert(
                id: _uuid.v4(),
                classId: id,
                subjectId: subjectId,
              ),
            );
      }
    });
  }

  @override
  Future<void> updateClass({
    required String id,
    required String name,
    required String level,
  }) async {
    final trimmedName = name.trim();
    await (_database.update(
      _database.schoolClasses,
    )..where((t) => t.id.equals(id))).write(
      SchoolClassesCompanion(
        name: Value(trimmedName),
        level: Value(level.trim()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteClass(String id) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.schoolClasses,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  domain.SchoolClass _mapToDomain(SchoolClassesData row) {
    return domain.SchoolClass(
      id: row.id,
      schoolId: row.schoolId,
      academicYearId: row.academicYearId,
      name: row.name,
      level: row.level,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
