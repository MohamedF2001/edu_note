import 'package:drift/native.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/features/authentication/data/repositories/teacher_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late TeacherRepositoryImpl repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = TeacherRepositoryImpl(database);
  });

  tearDown(() async {
    await database.close();
  });

  Future<String> registerTeacher() async {
    await repository.registerTeacher(
      firstName: 'Aïcha',
      lastName: 'Kora',
      profession: 'Enseignante',
      subjectName: 'Mathématiques',
      whatsappNumber: '+22997000000',
      password: 'motdepasse-securise',
    );
    return (await repository.getTeacherProfile())!.id;
  }

  test('stores one selected subject on the teacher profile', () async {
    await registerTeacher();

    final teacher = (await repository.getTeacherProfile())!;
    final subject = await (database.select(
      database.subjects,
    )..where((row) => row.id.equals(teacher.subjectId!))).getSingle();

    expect(teacher.subjectId, isNotNull);
    expect(subject.name, 'Mathématiques');
    expect(teacher.canChangeSubject, isTrue);
  });

  test(
    'changing subject before evaluations updates existing classes',
    () async {
      final teacherId = await registerTeacher();
      final oldSubjectId = (await repository.getTeacherProfile())!.subjectId!;
      final now = DateTime.now();
      await database
          .into(database.schools)
          .insert(
            SchoolsCompanion.insert(
              id: 'school-1',
              teacherId: teacherId,
              name: 'CEG Anavié',
              type: 'Collège',
              city: 'Avrankou',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.academicYears)
          .insert(
            AcademicYearsCompanion.insert(
              id: 'year-1',
              teacherId: teacherId,
              label: '2026-2027',
              startDate: DateTime(2026, 10),
              endDate: DateTime(2027, 6),
            ),
          );
      await database
          .into(database.schoolClasses)
          .insert(
            SchoolClassesCompanion.insert(
              id: 'class-1',
              schoolId: 'school-1',
              academicYearId: 'year-1',
              name: '3e A',
              level: '3e',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.classSubjects)
          .insert(
            ClassSubjectsCompanion.insert(
              id: 'class-subject-1',
              classId: 'class-1',
              subjectId: oldSubjectId,
            ),
          );

      await repository.setTeacherSubject('Français');

      final teacher = (await repository.getTeacherProfile())!;
      final classSubject = await (database.select(
        database.classSubjects,
      )..where((row) => row.classId.equals('class-1'))).getSingle();
      final subject = await (database.select(
        database.subjects,
      )..where((row) => row.id.equals(teacher.subjectId!))).getSingle();

      expect(subject.name, 'Français');
      expect(classSubject.subjectId, teacher.subjectId);
      expect(teacher.canChangeSubject, isTrue);
    },
  );

  test('locks subject changes after an evaluation exists', () async {
    final teacherId = await registerTeacher();
    final subjectId = (await repository.getTeacherProfile())!.subjectId!;
    final now = DateTime.now();
    await database
        .into(database.schools)
        .insert(
          SchoolsCompanion.insert(
            id: 'school-1',
            teacherId: teacherId,
            name: 'CEG Anavié',
            type: 'Collège',
            city: 'Avrankou',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.academicYears)
        .insert(
          AcademicYearsCompanion.insert(
            id: 'year-1',
            teacherId: teacherId,
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
    await database
        .into(database.schoolClasses)
        .insert(
          SchoolClassesCompanion.insert(
            id: 'class-1',
            schoolId: 'school-1',
            academicYearId: 'year-1',
            name: '3e A',
            level: '3e',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.classSubjects)
        .insert(
          ClassSubjectsCompanion.insert(
            id: 'class-subject-1',
            classId: 'class-1',
            subjectId: subjectId,
          ),
        );
    await database
        .into(database.evaluations)
        .insert(
          EvaluationsCompanion.insert(
            id: 'evaluation-1',
            classSubjectId: 'class-subject-1',
            academicPeriodId: 'period-1',
            type: 'interrogation',
            evaluationNumber: 1,
            evaluationDate: now,
            maxScore: 20,
            createdAt: now,
            updatedAt: now,
          ),
        );

    final teacher = (await repository.getTeacherProfile())!;
    expect(teacher.canChangeSubject, isFalse);
    await expectLater(
      repository.setTeacherSubject('Français'),
      throwsA(isA<StateError>()),
    );
    expect((await repository.getTeacherProfile())!.subjectId, subjectId);
  });
}
