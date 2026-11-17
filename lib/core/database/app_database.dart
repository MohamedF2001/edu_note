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

  /// Deletes user data and marks initial setup as complete.
  Future<void> clearLocalData() async {
    await transaction(() async {
      // A teacher points to their current subject, so clear that reference
      // before removing subjects. The remaining tables are deleted from leaf
      // to parent to satisfy foreign key constraints.
      await update(teachers).write(const TeachersCompanion(subjectId: Value(null)));
      await delete(grades).go();
      await delete(evaluations).go();
      await delete(classSubjects).go();
      await delete(students).go();
      await delete(schoolClasses).go();
      await delete(academicPeriods).go();
      await delete(academicYears).go();
      await delete(schools).go();
      await delete(subjects).go();
      await delete(teachers).go();
      await delete(appSettings).go();
      // Treat a full reset as an explicit choice to remove the demo dataset.
      // Keeping the onboarding completion flag also prevents auto-seeding it
      // again the next time the app starts.
      await into(appSettings).insert(
        AppSettingsCompanion.insert(
          key: 'has_seen_onboarding',
          value: 'true',
        ),
      );
    });
  }
}

QueryExecutor _openConnection() => driftDatabase(name: 'edunote');
