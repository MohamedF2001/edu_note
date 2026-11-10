import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/class_subject.dart' as domain;
import '../../domain/entities/subject.dart' as domain;
import '../../domain/repositories/subject_repository.dart';

class SubjectRepositoryImpl implements SubjectRepository {
  SubjectRepositoryImpl(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  String _normalize(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  @override
  Future<List<domain.Subject>> getSubjects() async {
    final rows = await (_database.select(
      _database.subjects,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<domain.Subject?> getSubjectById(String id) async {
    final row = await (_database.select(
      _database.subjects,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<domain.Subject> createSubject(String name) async {
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    if (teacher == null) {
      throw StateError('Aucun profil enseignant trouvé.');
    }

    final trimmedName = name.trim();
    final normalized = _normalize(trimmedName);

    final existing =
        await (_database.select(_database.subjects)..where(
              (t) =>
                  t.teacherId.equals(teacher.id) &
                  t.normalizedName.equals(normalized),
            ))
            .getSingleOrNull();

    if (existing != null) {
      return _mapToDomain(existing);
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database
        .into(_database.subjects)
        .insert(
          SubjectsCompanion.insert(
            id: id,
            teacherId: teacher.id,
            name: trimmedName,
            normalizedName: normalized,
            createdAt: now,
            updatedAt: now,
          ),
        );

    final created = await (_database.select(
      _database.subjects,
    )..where((t) => t.id.equals(id))).getSingle();
    return _mapToDomain(created);
  }

  @override
  Future<void> updateSubject({required String id, required String name}) async {
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    if (teacher?.subjectId == id) {
      final evaluations = _database.select(_database.evaluations).join([
        innerJoin(
          _database.classSubjects,
          _database.classSubjects.id.equalsExp(
            _database.evaluations.classSubjectId,
          ),
        ),
      ])..where(_database.classSubjects.subjectId.equals(id));
      if ((await evaluations.get()).isNotEmpty) {
        throw StateError(
          'La matière ne peut pas être modifiée après la création d’évaluations.',
        );
      }
    }

    final trimmedName = name.trim();
    final normalized = _normalize(trimmedName);

    await (_database.update(
      _database.subjects,
    )..where((t) => t.id.equals(id))).write(
      SubjectsCompanion(
        name: Value(trimmedName),
        normalizedName: Value(normalized),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteSubject(String id) async {
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    if (teacher?.subjectId == id) {
      throw StateError(
        'La matière unique du profil ne peut pas être supprimée.',
      );
    }
    final assignments = await (_database.select(
      _database.classSubjects,
    )..where((row) => row.subjectId.equals(id))).get();
    for (final assignment in assignments) {
      final evaluations = await (_database.select(
        _database.evaluations,
      )..where((row) => row.classSubjectId.equals(assignment.id))).get();
      if (evaluations.isNotEmpty) {
        throw StateError(
          'Cette matière est liée à des évaluations et à leurs notes. Elle ne peut pas être supprimée.',
        );
      }
    }
    await _database.transaction(() async {
      await (_database.delete(
        _database.subjects,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<List<domain.ClassSubject>> getSubjectsByClass(String classId) async {
    final query =
        _database.select(_database.classSubjects).join([
            innerJoin(
              _database.subjects,
              _database.subjects.id.equalsExp(
                _database.classSubjects.subjectId,
              ),
            ),
          ])
          ..where(_database.classSubjects.classId.equals(classId))
          ..orderBy([OrderingTerm.asc(_database.subjects.name)]);

    final rows = await query.get();
    return rows.map((row) {
      final classSub = row.readTable(_database.classSubjects);
      final sub = row.readTable(_database.subjects);
      return domain.ClassSubject(
        id: classSub.id,
        classId: classSub.classId,
        subjectId: classSub.subjectId,
        subjectName: sub.name,
      );
    }).toList();
  }

  @override
  Future<domain.ClassSubject> assignSubjectToClass({
    required String classId,
    required String subjectId,
  }) async {
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    if (teacher == null || teacher.subjectId != subjectId) {
      throw StateError(
        'Une classe utilise uniquement la matière définie dans le profil enseignant.',
      );
    }

    final otherAssignment =
        await (_database.select(_database.classSubjects)..where(
              (row) =>
                  row.classId.equals(classId) &
                  row.subjectId.isNotValue(subjectId),
            ))
            .getSingleOrNull();
    if (otherAssignment != null) {
      throw StateError(
        'Cette classe possède déjà une association historique avec une autre matière.',
      );
    }

    final existing =
        await (_database.select(_database.classSubjects)..where(
              (t) => t.classId.equals(classId) & t.subjectId.equals(subjectId),
            ))
            .getSingleOrNull();

    if (existing != null) {
      final sub = await (_database.select(
        _database.subjects,
      )..where((t) => t.id.equals(subjectId))).getSingle();
      return domain.ClassSubject(
        id: existing.id,
        classId: existing.classId,
        subjectId: existing.subjectId,
        subjectName: sub.name,
      );
    }

    final id = _uuid.v4();
    await _database
        .into(_database.classSubjects)
        .insert(
          ClassSubjectsCompanion.insert(
            id: id,
            classId: classId,
            subjectId: subjectId,
          ),
        );

    final sub = await (_database.select(
      _database.subjects,
    )..where((t) => t.id.equals(subjectId))).getSingle();

    return domain.ClassSubject(
      id: id,
      classId: classId,
      subjectId: subjectId,
      subjectName: sub.name,
    );
  }

  @override
  Future<void> removeSubjectFromClass(String classSubjectId) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.classSubjects,
      )..where((t) => t.id.equals(classSubjectId))).go();
    });
  }

  @override
  Future<void> ensureDefaultSubjects() async {
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    if (teacher == null) return;

    final existing = await (_database.select(
      _database.subjects,
    )..where((t) => t.teacherId.equals(teacher.id))).get();

    if (existing.isNotEmpty) return;

    const defaults = [
      'Mathématiques',
      'Français',
      'PCT (Physique-Chimie-Technologie)',
      'SVT (Sciences de la Vie et de la Terre)',
      'Anglais',
      'Histoire-Géographie',
      'Éducation Physique et Sportive (EPS)',
      'Philosophie',
    ];

    for (final name in defaults) {
      await createSubject(name);
    }
  }

  domain.Subject _mapToDomain(Subject row) {
    return domain.Subject(
      id: row.id,
      teacherId: row.teacherId,
      name: row.name,
      normalizedName: row.normalizedName,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
