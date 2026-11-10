import 'package:drift/native.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/features/academic_years/data/repositories/academic_year_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AcademicYearRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AcademicYearRepositoryImpl(db);

    // Register teacher for foreign key
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
  });

  tearDown(() async {
    await db.close();
  });

  test('creates default academic year with two semesters automatically', () async {
    final year = await repository.ensureDefaultAcademicYear();
    expect(year.isActive, isTrue);

    final periods = await repository.getPeriodsByYear(year.id);
    expect(periods.length, 2);
    expect(periods[0].name, 'Premier semestre');
    expect(periods[1].name, 'Deuxième semestre');
  });

  test('sets active academic year uniquely', () async {
    final year1 = await repository.createAcademicYear(
      label: '2026-2027',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2027, 6, 30),
      isActive: true,
    );
    final year2 = await repository.createAcademicYear(
      label: '2027-2028',
      startDate: DateTime(2027, 10, 1),
      endDate: DateTime(2028, 6, 30),
      isActive: false,
    );

    expect((await repository.getActiveAcademicYear())?.id, year1.id);

    await repository.setActiveAcademicYear(year2.id);

    expect((await repository.getActiveAcademicYear())?.id, year2.id);
    final reloadedYear1 =
        (await repository.getAcademicYears()).firstWhere((y) => y.id == year1.id);
    expect(reloadedYear1.isActive, isFalse);
  });
}
