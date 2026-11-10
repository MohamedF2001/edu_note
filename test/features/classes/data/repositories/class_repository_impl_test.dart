import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/features/classes/data/repositories/class_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ClassRepositoryImpl repository;
  const schoolId = 'school-1';
  const academicYearId = 'year-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = ClassRepositoryImpl(db);

    final now = DateTime.now();
    await db
        .into(db.teachers)
        .insert(
          TeachersCompanion.insert(
            id: 'teacher-1',
            firstName: 'Jean',
            lastName: 'Hounnou',
            profession: 'Professeur',
            whatsappNumber: '+22997000000',
            passwordHash: 'dummy_hash',
            passwordSalt: 'dummy_salt',
            passwordHashIterations: 10000,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.schools)
        .insert(
          SchoolsCompanion.insert(
            id: schoolId,
            teacherId: 'teacher-1',
            name: 'CEG Porto-Novo',
            type: 'Collège',
            city: 'Porto-Novo',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db
        .into(db.academicYears)
        .insert(
          AcademicYearsCompanion.insert(
            id: academicYearId,
            teacherId: 'teacher-1',
            label: '2026-2027',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2027, 6, 30),
            isActive: const Value(true),
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('creates, lists and gets a class by id', () async {
    await repository.createClass(
      schoolId: schoolId,
      academicYearId: academicYearId,
      name: '6e A',
      level: '6e',
    );
    await repository.createClass(
      schoolId: schoolId,
      academicYearId: academicYearId,
      name: '3e C',
      level: '3e',
    );

    final classes = await repository.getClassesBySchool(schoolId);
    expect(classes.length, 2);
    expect(classes[0].name, '3e C');
    expect(classes[1].name, '6e A');

    final found = await repository.getClassById(classes[0].id);
    expect(found, isNotNull);
    expect(found!.name, '3e C');
    expect(found.level, '3e');
  });

  test('rejects duplicate class name in same school and year', () async {
    await repository.createClass(
      schoolId: schoolId,
      academicYearId: academicYearId,
      name: '5e B',
      level: '5e',
    );

    expect(
      () => repository.createClass(
        schoolId: schoolId,
        academicYearId: academicYearId,
        name: '5e B',
        level: '5e',
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('allows the same class name in different schools', () async {
    const otherSchoolId = 'school-2';
    final now = DateTime.now();
    await db
        .into(db.schools)
        .insert(
          SchoolsCompanion.insert(
            id: otherSchoolId,
            teacherId: 'teacher-1',
            name: 'CEG Anavié',
            type: 'Collège',
            city: 'Avrankou',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await repository.createClass(
      schoolId: schoolId,
      academicYearId: academicYearId,
      name: '3e A',
      level: '3e',
    );
    await repository.createClass(
      schoolId: otherSchoolId,
      academicYearId: academicYearId,
      name: '3e A',
      level: '3e',
    );

    final firstSchoolClasses = await repository.getClassesBySchool(schoolId);
    final secondSchoolClasses = await repository.getClassesBySchool(
      otherSchoolId,
    );

    expect(firstSchoolClasses, hasLength(1));
    expect(secondSchoolClasses, hasLength(1));
    expect(firstSchoolClasses.single.name, secondSchoolClasses.single.name);
    expect(firstSchoolClasses.single.id, isNot(secondSchoolClasses.single.id));
  });

  test('updates class details and deletes class', () async {
    await repository.createClass(
      schoolId: schoolId,
      academicYearId: academicYearId,
      name: '4e A',
      level: '4e',
    );

    final item = (await repository.getClassesBySchool(schoolId)).first;
    await repository.updateClass(id: item.id, name: '4e M1', level: '4e');

    final updated = await repository.getClassById(item.id);
    expect(updated!.name, '4e M1');

    await repository.deleteClass(item.id);
    final emptyList = await repository.getClassesBySchool(schoolId);
    expect(emptyList, isEmpty);
  });
}
