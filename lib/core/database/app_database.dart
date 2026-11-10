import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables/app_tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Teachers,
    Schools,
    AcademicYears,
    AcademicPeriods,
    SchoolClasses,
    Students,
    Subjects,
    ClassSubjects,
    Evaluations,
    Grades,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.addColumn(teachers, teachers.subjectId);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}

QueryExecutor _openConnection() => driftDatabase(name: 'edunote');
