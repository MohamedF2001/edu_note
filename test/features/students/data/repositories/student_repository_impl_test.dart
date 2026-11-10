import 'package:drift/native.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/features/students/data/repositories/student_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late StudentRepositoryImpl repository;
  const classId = 'class-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = StudentRepositoryImpl(db);

    final now = DateTime.now();
    await db.into(db.teachers).insert(
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

    await db.into(db.schools).insert(
          SchoolsCompanion.insert(
            id: 'school-1',
            teacherId: 'teacher-1',
            name: 'CEG Porto-Novo',
            type: 'Collège',
            city: 'Porto-Novo',
            createdAt: now,
            updatedAt: now,
          ),
        );

    await db.into(db.academicYears).insert(
          AcademicYearsCompanion.insert(
            id: 'year-1',
            teacherId: 'teacher-1',
            label: '2026-2027',
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2027, 6, 30),
          ),
        );

    await db.into(db.schoolClasses).insert(
          SchoolClassesCompanion.insert(
            id: classId,
            schoolId: 'school-1',
            academicYearId: 'year-1',
            name: '6e A',
            level: '6e',
            createdAt: now,
            updatedAt: now,
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  test('creates students and retrieves them sorted by last name', () async {
    await repository.createStudent(
      classId: classId,
      firstName: 'Paul',
      lastName: 'ZINSOU',
      gender: 'M',
    );
    await repository.createStudent(
      classId: classId,
      firstName: 'Aïcha',
      lastName: 'ADAM',
      gender: 'F',
    );

    final students = await repository.getStudentsByClass(classId);
    expect(students.length, 2);
    expect(students[0].lastName, 'ADAM');
    expect(students[1].lastName, 'ZINSOU');
    expect(students[0].orderNumber, 2); // ADAM was added second
    expect(students[1].orderNumber, 1); // ZINSOU was added first
  });

  test('filters students by search query matching name or matricule', () async {
    await repository.createStudent(
      classId: classId,
      firstName: 'Koffi',
      lastName: 'MENSAH',
      registrationNumber: 'MAT-2026-001',
    );
    await repository.createStudent(
      classId: classId,
      firstName: 'Marie',
      lastName: 'DOSSOU',
      registrationNumber: 'MAT-2026-002',
    );

    final result1 = await repository.getStudentsByClass(
      classId,
      searchQuery: 'dossou',
    );
    expect(result1.length, 1);
    expect(result1.first.firstName, 'Marie');

    final result2 = await repository.getStudentsByClass(
      classId,
      searchQuery: '001',
    );
    expect(result2.length, 1);
    expect(result2.first.lastName, 'MENSAH');
  });

  test('generates unique sequential registration numbers', () async {
    final num1 = await repository.generateNextRegistrationNumber(classId);
    expect(num1, contains('MAT-'));
    expect(num1, endsWith('001'));

    await repository.createStudent(
      classId: classId,
      firstName: 'Premier',
      lastName: 'ELEVE',
      registrationNumber: num1,
    );

    final num2 = await repository.generateNextRegistrationNumber(classId);
    expect(num2, endsWith('002'));
  });

  test('updates and deletes student', () async {
    await repository.createStudent(
      classId: classId,
      firstName: 'Alain',
      lastName: 'BIO',
    );

    final student = (await repository.getStudentsByClass(classId)).first;
    await repository.updateStudent(
      id: student.id,
      firstName: 'Alain-Pierre',
      lastName: 'BIO',
      gender: 'M',
      dateOfBirth: DateTime(2012, 5, 14),
    );

    final updated = await repository.getStudentById(student.id);
    expect(updated!.firstName, 'Alain-Pierre');
    expect(updated.dateOfBirth, DateTime(2012, 5, 14));

    await repository.deleteStudent(student.id);
    final emptyList = await repository.getStudentsByClass(classId);
    expect(emptyList, isEmpty);
  });
}
