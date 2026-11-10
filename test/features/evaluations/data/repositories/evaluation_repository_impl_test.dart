import 'package:drift/native.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/features/evaluations/data/repositories/evaluation_repository_impl.dart';
import 'package:edu_note/features/evaluations/domain/entities/grade.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late EvaluationRepositoryImpl repository;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = EvaluationRepositoryImpl(database);
    final now = DateTime.now();

    await database
        .into(database.teachers)
        .insert(
          TeachersCompanion.insert(
            id: 'teacher-1',
            firstName: 'Aïcha',
            lastName: 'Kora',
            profession: 'Enseignante',
            whatsappNumber: '+22997000000',
            passwordHash: 'hash',
            passwordSalt: 'salt',
            passwordHashIterations: 10000,
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (final school in [
      ('school-1', 'Lycée Béhanzin'),
      ('school-2', 'CEG Anavié'),
    ]) {
      await database
          .into(database.schools)
          .insert(
            SchoolsCompanion.insert(
              id: school.$1,
              teacherId: 'teacher-1',
              name: school.$2,
              type: 'Collège',
              city: 'Porto-Novo',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await database
        .into(database.academicYears)
        .insert(
          AcademicYearsCompanion.insert(
            id: 'year-1',
            teacherId: 'teacher-1',
            label: '2026-2027',
            startDate: DateTime(2026, 10),
            endDate: DateTime(2027, 6),
          ),
        );
    await database
        .into(database.academicPeriods)
        .insert(
          AcademicPeriodsCompanion.insert(
            id: 'period-1',
            academicYearId: 'year-1',
            name: 'Premier semestre',
            startDate: DateTime(2026, 10),
            endDate: DateTime(2027, 1),
          ),
        );
    for (final schoolId in ['school-1', 'school-2']) {
      await database
          .into(database.schoolClasses)
          .insert(
            SchoolClassesCompanion.insert(
              id: 'class-$schoolId',
              schoolId: schoolId,
              academicYearId: 'year-1',
              name: '3e A',
              level: '3e',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await database
        .into(database.subjects)
        .insert(
          SubjectsCompanion.insert(
            id: 'subject-1',
            teacherId: 'teacher-1',
            name: 'Mathématiques',
            normalizedName: 'mathématiques',
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (final schoolId in ['school-1', 'school-2']) {
      await database
          .into(database.classSubjects)
          .insert(
            ClassSubjectsCompanion.insert(
              id: 'class-subject-$schoolId',
              classId: 'class-$schoolId',
              subjectId: 'subject-1',
            ),
          );
      await database
          .into(database.students)
          .insert(
            StudentsCompanion.insert(
              id: 'student-$schoolId',
              classId: 'class-$schoolId',
              firstName: 'Jean',
              lastName: 'Dupont',
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
    await database
        .into(database.evaluations)
        .insert(
          EvaluationsCompanion.insert(
            id: 'evaluation-1',
            classSubjectId: 'class-subject-school-1',
            academicPeriodId: 'period-1',
            type: 'interrogation',
            evaluationNumber: 1,
            evaluationDate: now,
            maxScore: 20,
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  test('rejects a grade for a student from another school', () async {
    await expectLater(
      repository.saveGrade(
        schoolId: 'school-1',
        evaluationId: 'evaluation-1',
        studentId: 'student-school-2',
        status: GradeStatus.recorded,
        score: 12,
      ),
      throwsA(isA<ArgumentError>()),
    );

    expect(await database.select(database.grades).get(), isEmpty);
  });
}
