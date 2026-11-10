import 'package:drift/native.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/features/schools/data/repositories/school_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SchoolRepositoryImpl repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = SchoolRepositoryImpl(db);

    // Register a teacher row for foreign key
    final now = DateTime.now();
    await db.into(db.teachers).insert(
          TeachersCompanion.insert(
            id: 'teacher-1',
            firstName: 'Jean',
            lastName: 'Hounnou',
            profession: 'Professeur de mathématiques',
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

  test('creates and retrieves schools in alphabetical order', () async {
    await repository.createSchool(
      name: 'Lycée Behanzin',
      type: 'Lycée',
      city: 'Porto-Novo',
      address: 'Centre-ville',
    );
    await repository.createSchool(
      name: 'CEG Nokoué',
      type: 'Collège',
      city: 'Cotonou',
    );

    final schools = await repository.getSchools();
    expect(schools.length, 2);
    expect(schools[0].name, 'CEG Nokoué');
    expect(schools[1].name, 'Lycée Behanzin');
  });

  test('retrieves a school by its ID', () async {
    await repository.createSchool(
      name: 'Complexe Scolaire La Rose',
      type: 'Primaire',
      city: 'Abomey-Calavi',
    );

    final schools = await repository.getSchools();
    final createdId = schools.first.id;

    final found = await repository.getSchoolById(createdId);
    expect(found, isNotNull);
    expect(found!.name, 'Complexe Scolaire La Rose');
    expect(found.type, 'Primaire');
    expect(found.city, 'Abomey-Calavi');
  });

  test('updates a school details correctly', () async {
    await repository.createSchool(
      name: 'CEG 1',
      type: 'Collège',
      city: 'Parakou',
    );

    final school = (await repository.getSchools()).first;
    await repository.updateSchool(
      id: school.id,
      name: 'CEG Albarika',
      type: 'Collège',
      city: 'Parakou',
      address: 'Rue 12',
    );

    final updated = await repository.getSchoolById(school.id);
    expect(updated!.name, 'CEG Albarika');
    expect(updated.address, 'Rue 12');
  });

  test('deletes a school successfully', () async {
    await repository.createSchool(
      name: 'École à supprimer',
      type: 'Autre',
      city: 'Ouidah',
    );

    final school = (await repository.getSchools()).first;
    await repository.deleteSchool(school.id);

    final schools = await repository.getSchools();
    expect(schools, isEmpty);
  });
}
