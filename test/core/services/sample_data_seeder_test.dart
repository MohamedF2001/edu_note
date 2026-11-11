import 'dart:io';
import 'package:drift/native.dart';
import 'package:edu_note/core/database/app_database.dart';
import 'package:edu_note/core/services/sample_data_seeder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late SampleDataSeeder seeder;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    seeder = SampleDataSeeder(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('seeds 3 schools, 9 classes, 135 students, and evaluations with grades from sample_data.txt', () async {
    final file = File('sample_data.txt');
    expect(file.existsSync(), isTrue);

    final rawJson = await file.readAsString();
    await seeder.seedFromJson(rawJson);

    // Verify Teacher & Subject
    final teachers = await database.select(database.teachers).get();
    expect(teachers.length, equals(1));
    expect(teachers.first.profession, equals('Professeur de Mathématiques'));

    final subjects = await database.select(database.subjects).get();
    expect(subjects.any((s) => s.name == 'Mathématiques'), isTrue);

    // Verify 3 Schools
    final schools = await database.select(database.schools).get();
    expect(schools.length, equals(3));
    final schoolNames = schools.map((s) => s.name).toSet();
    expect(schoolNames, containsAll(['Lycée Béhanzin', 'CEG Anavié', 'CEG Le Nokoué']));

    // Verify 9 Classes (3 per school)
    final classes = await database.select(database.schoolClasses).get();
    expect(classes.length, equals(9));

    for (final school in schools) {
      final schoolClasses = classes.where((c) => c.schoolId == school.id).toList();
      expect(schoolClasses.length, equals(3));
    }

    // Verify 135 Students (15 per class)
    final students = await database.select(database.students).get();
    expect(students.length, equals(135));

    for (final c in classes) {
      final classStudents = students.where((s) => s.classId == c.id).toList();
      expect(classStudents.length, equals(15));
    }

    // Verify Evaluations (4 per class: 2 interros, 2 devoirs -> 36 evals)
    final evals = await database.select(database.evaluations).get();
    expect(evals.length, equals(36));

    // Verify Grades (15 * 36 = 540 grades)
    final grades = await database.select(database.grades).get();
    expect(grades.length, equals(540));

    final recordedGrades = grades.where((g) => g.status == 'renseignée').toList();
    final absentGrades = grades.where((g) => g.status == 'absent').toList();
    expect(recordedGrades.length, equals(540));
    expect(absentGrades.isEmpty, isTrue);

    for (final rg in recordedGrades) {
      expect(rg.score, isNotNull);
      expect(rg.score! >= 0 && rg.score! <= 20, isTrue);
    }
  });
}
