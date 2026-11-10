import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/evaluation.dart' as domain;
import '../../domain/entities/grade.dart' as domain;
import '../../domain/repositories/evaluation_repository.dart';

class EvaluationRepositoryImpl implements EvaluationRepository {
  EvaluationRepositoryImpl(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  // ────────── Evaluation mapping ──────────

  domain.EvaluationType _typeFromString(String s) {
    switch (s) {
      case 'homework1':
        return domain.EvaluationType.homework1;
      case 'homework2':
        return domain.EvaluationType.homework2;
      default:
        return domain.EvaluationType.interrogation;
    }
  }

  String _typeToString(domain.EvaluationType t) {
    switch (t) {
      case domain.EvaluationType.homework1:
        return 'homework1';
      case domain.EvaluationType.homework2:
        return 'homework2';
      case domain.EvaluationType.interrogation:
        return 'interrogation';
    }
  }

  domain.Evaluation _mapEval(Evaluation row) => domain.Evaluation(
    id: row.id,
    classSubjectId: row.classSubjectId,
    academicPeriodId: row.academicPeriodId,
    type: _typeFromString(row.type),
    evaluationNumber: row.evaluationNumber,
    evaluationDate: row.evaluationDate,
    maxScore: row.maxScore,
    isActive: row.isActive,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
    title: row.title,
  );

  // ────────── Grade mapping ──────────

  domain.GradeStatus _statusFromString(String s) {
    switch (s) {
      case 'absent':
        return domain.GradeStatus.absent;
      case 'recorded':
        return domain.GradeStatus.recorded;
      default:
        return domain.GradeStatus.notRecorded;
    }
  }

  String _statusToString(domain.GradeStatus s) {
    switch (s) {
      case domain.GradeStatus.absent:
        return 'absent';
      case domain.GradeStatus.recorded:
        return 'recorded';
      case domain.GradeStatus.notRecorded:
        return 'not_recorded';
    }
  }

  domain.Grade _mapGrade(Grade row) => domain.Grade(
    id: row.id,
    evaluationId: row.evaluationId,
    studentId: row.studentId,
    status: _statusFromString(row.status),
    score: row.score,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  // ────────── Evaluation queries ──────────

  @override
  Future<List<domain.Evaluation>> getEvaluationsByClassSubject(
    String classSubjectId,
  ) async {
    final rows =
        await (_database.select(_database.evaluations)
              ..where(
                (t) =>
                    t.classSubjectId.equals(classSubjectId) &
                    t.isActive.equals(true),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.evaluationDate),
                (t) => OrderingTerm.asc(t.evaluationNumber),
              ]))
            .get();
    return rows.map(_mapEval).toList();
  }

  @override
  Future<List<domain.Evaluation>> getEvaluationsByPeriod({
    required String classSubjectId,
    required String academicPeriodId,
  }) async {
    final rows =
        await (_database.select(_database.evaluations)
              ..where(
                (t) =>
                    t.classSubjectId.equals(classSubjectId) &
                    t.academicPeriodId.equals(academicPeriodId) &
                    t.isActive.equals(true),
              )
              ..orderBy([
                (t) => OrderingTerm.asc(t.evaluationDate),
                (t) => OrderingTerm.asc(t.evaluationNumber),
              ]))
            .get();
    return rows.map(_mapEval).toList();
  }

  @override
  Future<domain.Evaluation?> getEvaluationById(String id) async {
    final row = await (_database.select(
      _database.evaluations,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row != null ? _mapEval(row) : null;
  }

  @override
  Future<domain.Evaluation> createEvaluation({
    required String classSubjectId,
    required String academicPeriodId,
    required domain.EvaluationType type,
    required DateTime evaluationDate,
    required double maxScore,
    String? title,
  }) async {
    final classSubject = await (_database.select(
      _database.classSubjects,
    )..where((row) => row.id.equals(classSubjectId))).getSingleOrNull();
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    final classRow = classSubject == null
        ? null
        : await (_database.select(_database.schoolClasses)
                ..where((row) => row.id.equals(classSubject.classId)))
              .getSingleOrNull();
    final school = classRow == null
        ? null
        : await (_database.select(_database.schools)
                ..where((row) => row.id.equals(classRow.schoolId)))
              .getSingleOrNull();
    final period = await (_database.select(
      _database.academicPeriods,
    )..where((row) => row.id.equals(academicPeriodId))).getSingleOrNull();
    if (classSubject == null ||
        teacher == null ||
        classRow == null ||
        school?.teacherId != teacher.id ||
        teacher.subjectId != classSubject.subjectId ||
        period == null ||
        period.academicYearId != classRow.academicYearId) {
      throw ArgumentError(
        'La classe, la matière ou la période ne correspond pas au profil actif.',
      );
    }

    // Compute the next evaluation number for interrogations
    int evalNumber = 1;
    if (type == domain.EvaluationType.interrogation) {
      final existing =
          await (_database.select(_database.evaluations)..where(
                (t) =>
                    t.classSubjectId.equals(classSubjectId) &
                    t.academicPeriodId.equals(academicPeriodId) &
                    t.type.equals('interrogation') &
                    t.isActive.equals(true),
              ))
              .get();
      evalNumber = existing.length + 1;
    } else {
      final duplicateHomework =
          await (_database.select(_database.evaluations)..where(
                (row) =>
                    row.classSubjectId.equals(classSubjectId) &
                    row.academicPeriodId.equals(academicPeriodId) &
                    row.type.equals(_typeToString(type)) &
                    row.isActive.equals(true),
              ))
              .getSingleOrNull();
      if (duplicateHomework != null) {
        throw StateError(
          '${type == domain.EvaluationType.homework1 ? 'Devoir 1' : 'Devoir 2'} existe déjà pour cette classe et cette période.',
        );
      }
    }

    final id = _uuid.v4();
    final now = DateTime.now();

    await _database
        .into(_database.evaluations)
        .insert(
          EvaluationsCompanion.insert(
            id: id,
            classSubjectId: classSubjectId,
            academicPeriodId: academicPeriodId,
            type: _typeToString(type),
            evaluationNumber: evalNumber,
            evaluationDate: evaluationDate,
            maxScore: maxScore,
            title: Value(title),
            createdAt: now,
            updatedAt: now,
          ),
        );

    final created = await (_database.select(
      _database.evaluations,
    )..where((t) => t.id.equals(id))).getSingle();
    return _mapEval(created);
  }

  @override
  Future<void> updateEvaluation({
    required String id,
    required DateTime evaluationDate,
    required double maxScore,
    String? title,
  }) async {
    await (_database.update(
      _database.evaluations,
    )..where((t) => t.id.equals(id))).write(
      EvaluationsCompanion(
        evaluationDate: Value(evaluationDate),
        maxScore: Value(maxScore),
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteEvaluation(String id) async {
    // Soft delete: set isActive = false
    await (_database.update(
      _database.evaluations,
    )..where((t) => t.id.equals(id))).write(
      EvaluationsCompanion(
        isActive: const Value(false),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // ────────── Grade queries ──────────

  @override
  Future<List<domain.Grade>> getGradesByEvaluation(String evaluationId) async {
    final rows =
        await (_database.select(_database.grades)
              ..where((t) => t.evaluationId.equals(evaluationId))
              ..orderBy([(t) => OrderingTerm.asc(t.studentId)]))
            .get();
    return rows.map(_mapGrade).toList();
  }

  @override
  Future<List<domain.Grade>> getGradesByStudentAndClassSubject({
    required String studentId,
    required String classSubjectId,
  }) async {
    // JOIN grades ← evaluations where classSubjectId matches
    final query =
        _database.select(_database.grades).join([
          innerJoin(
            _database.evaluations,
            _database.evaluations.id.equalsExp(_database.grades.evaluationId),
          ),
        ])..where(
          _database.grades.studentId.equals(studentId) &
              _database.evaluations.classSubjectId.equals(classSubjectId) &
              _database.evaluations.isActive.equals(true),
        );

    final rows = await query.get();
    return rows.map((r) => _mapGrade(r.readTable(_database.grades))).toList();
  }

  @override
  Future<domain.Grade> saveGrade({
    required String schoolId,
    required String evaluationId,
    required String studentId,
    required domain.GradeStatus status,
    double? score,
  }) async {
    final evaluation = await (_database.select(
      _database.evaluations,
    )..where((row) => row.id.equals(evaluationId))).getSingleOrNull();
    if (evaluation == null || !evaluation.isActive) {
      throw ArgumentError.value(
        evaluationId,
        'evaluationId',
        'Évaluation introuvable.',
      );
    }

    final classSubject =
        await (_database.select(_database.classSubjects)
              ..where((row) => row.id.equals(evaluation.classSubjectId)))
            .getSingleOrNull();
    final schoolClass = classSubject == null
        ? null
        : await (_database.select(_database.schoolClasses)
                ..where((row) => row.id.equals(classSubject.classId)))
              .getSingleOrNull();
    final school = schoolClass == null
        ? null
        : await (_database.select(_database.schools)
                ..where((row) => row.id.equals(schoolClass.schoolId)))
              .getSingleOrNull();
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    final student = await (_database.select(
      _database.students,
    )..where((row) => row.id.equals(studentId))).getSingleOrNull();
    if (classSubject == null ||
        student == null ||
        schoolClass == null ||
        school?.id != schoolId ||
        school?.teacherId != teacher?.id ||
        student.classId != classSubject.classId) {
      throw ArgumentError.value(
        studentId,
        'studentId',
        'Cet élève n’appartient pas à la classe de cette évaluation.',
      );
    }

    if (status == domain.GradeStatus.recorded) {
      if (score == null || score < 0 || score > evaluation.maxScore) {
        throw ArgumentError.value(
          score,
          'score',
          'La note doit être comprise entre 0 et ${evaluation.maxScore}.',
        );
      }
    } else if (score != null) {
      throw ArgumentError.value(
        score,
        'score',
        'Une absence ou une note non renseignée ne peut pas avoir de score.',
      );
    }

    final existing =
        await (_database.select(_database.grades)..where(
              (t) =>
                  t.evaluationId.equals(evaluationId) &
                  t.studentId.equals(studentId),
            ))
            .getSingleOrNull();

    final now = DateTime.now();
    final statusStr = _statusToString(status);

    if (existing != null) {
      await (_database.update(
        _database.grades,
      )..where((t) => t.id.equals(existing.id))).write(
        GradesCompanion(
          status: Value(statusStr),
          score: Value(score),
          updatedAt: Value(now),
        ),
      );

      final updated = await (_database.select(
        _database.grades,
      )..where((t) => t.id.equals(existing.id))).getSingle();
      return _mapGrade(updated);
    } else {
      final id = _uuid.v4();
      await _database
          .into(_database.grades)
          .insert(
            GradesCompanion.insert(
              id: id,
              evaluationId: evaluationId,
              studentId: studentId,
              status: statusStr,
              score: Value(score),
              createdAt: now,
              updatedAt: now,
            ),
          );

      final created = await (_database.select(
        _database.grades,
      )..where((t) => t.id.equals(id))).getSingle();
      return _mapGrade(created);
    }
  }

  @override
  Future<void> saveGradesBatch({
    required String schoolId,
    required List<domain.Grade> grades,
  }) async {
    await _database.transaction(() async {
      for (final grade in grades) {
        await saveGrade(
          schoolId: schoolId,
          evaluationId: grade.evaluationId,
          studentId: grade.studentId,
          status: grade.status,
          score: grade.score,
        );
      }
    });
  }
}
