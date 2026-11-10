import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/academic_period.dart' as domain;
import '../../domain/entities/academic_year.dart' as domain;
import '../../domain/repositories/academic_year_repository.dart';

class AcademicYearRepositoryImpl implements AcademicYearRepository {
  AcademicYearRepositoryImpl(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  @override
  Future<List<domain.AcademicYear>> getAcademicYears() async {
    final rows = await (_database.select(_database.academicYears)
          ..orderBy([(t) => OrderingTerm.desc(t.startDate)]))
        .get();
    return rows.map(_mapYearToDomain).toList();
  }

  @override
  Future<domain.AcademicYear?> getActiveAcademicYear() async {
    final row = await (_database.select(_database.academicYears)
          ..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
    return row != null ? _mapYearToDomain(row) : null;
  }

  @override
  Future<void> setActiveAcademicYear(String id) async {
    await _database.transaction(() async {
      await _database.update(_database.academicYears).write(
            const AcademicYearsCompanion(isActive: Value(false)),
          );
      await (_database.update(_database.academicYears)
            ..where((t) => t.id.equals(id)))
          .write(
        const AcademicYearsCompanion(isActive: Value(true)),
      );
    });
  }

  @override
  Future<domain.AcademicYear> createAcademicYear({
    required String label,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = false,
  }) async {
    final teacher =
        await (_database.select(_database.teachers)).getSingleOrNull();
    if (teacher == null) {
      throw StateError('Aucun profil enseignant trouvé.');
    }

    final id = _uuid.v4();

    await _database.transaction(() async {
      if (isActive) {
        await _database.update(_database.academicYears).write(
              const AcademicYearsCompanion(isActive: Value(false)),
            );
      }

      await _database.into(_database.academicYears).insert(
            AcademicYearsCompanion.insert(
              id: id,
              teacherId: teacher.id,
              label: label.trim(),
              startDate: startDate,
              endDate: endDate,
              isActive: Value(isActive),
            ),
          );

      // Par défaut, créer les deux semestres officiels
      final midDate = startDate.add(endDate.difference(startDate) ~/ 2);
      await _database.into(_database.academicPeriods).insert(
            AcademicPeriodsCompanion.insert(
              id: _uuid.v4(),
              academicYearId: id,
              name: 'Premier semestre',
              startDate: startDate,
              endDate: midDate,
            ),
          );
      await _database.into(_database.academicPeriods).insert(
            AcademicPeriodsCompanion.insert(
              id: _uuid.v4(),
              academicYearId: id,
              name: 'Deuxième semestre',
              startDate: midDate.add(const Duration(days: 1)),
              endDate: endDate,
            ),
          );
    });

    final created = await (_database.select(_database.academicYears)
          ..where((t) => t.id.equals(id)))
        .getSingle();
    return _mapYearToDomain(created);
  }

  @override
  Future<List<domain.AcademicPeriod>> getPeriodsByYear(
    String academicYearId,
  ) async {
    final rows = await (_database.select(_database.academicPeriods)
          ..where((t) => t.academicYearId.equals(academicYearId))
          ..orderBy([(t) => OrderingTerm.asc(t.startDate)]))
        .get();
    return rows.map(_mapPeriodToDomain).toList();
  }

  @override
  Future<void> createPeriod({
    required String academicYearId,
    required String name,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _database.into(_database.academicPeriods).insert(
          AcademicPeriodsCompanion.insert(
            id: _uuid.v4(),
            academicYearId: academicYearId,
            name: name.trim(),
            startDate: startDate,
            endDate: endDate,
          ),
        );
  }

  @override
  Future<domain.AcademicYear> ensureDefaultAcademicYear() async {
    final active = await getActiveAcademicYear();
    if (active != null) return active;

    final all = await getAcademicYears();
    if (all.isNotEmpty) {
      final first = all.first;
      await setActiveAcademicYear(first.id);
      return (await getActiveAcademicYear())!;
    }

    final now = DateTime.now();
    final startYear = now.month >= 8 ? now.year : now.year - 1;
    final endYear = startYear + 1;
    return createAcademicYear(
      label: '$startYear-$endYear',
      startDate: DateTime(startYear, 10, 1),
      endDate: DateTime(endYear, 6, 30),
      isActive: true,
    );
  }

  domain.AcademicYear _mapYearToDomain(AcademicYear row) {
    return domain.AcademicYear(
      id: row.id,
      teacherId: row.teacherId,
      label: row.label,
      startDate: row.startDate,
      endDate: row.endDate,
      isActive: row.isActive,
    );
  }

  domain.AcademicPeriod _mapPeriodToDomain(AcademicPeriod row) {
    return domain.AcademicPeriod(
      id: row.id,
      academicYearId: row.academicYearId,
      name: row.name,
      startDate: row.startDate,
      endDate: row.endDate,
    );
  }
}
