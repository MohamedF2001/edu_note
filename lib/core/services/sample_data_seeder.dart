import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';

import '../database/app_database.dart';
import '../../features/authentication/data/utils/password_hasher.dart';

class SampleDataSeeder {
  SampleDataSeeder(this._db);

  final AppDatabase _db;

  /// Loads sample data from assets/data/sample_data.txt or a given raw json string
  Future<void> seedFromAsset({String assetPath = 'assets/data/sample_data.txt'}) async {
    final raw = await rootBundle.loadString(assetPath);
    await seedFromJson(raw);
  }

  Future<void> seedFromJson(String jsonString) async {
    final Map<String, dynamic> data = jsonDecode(jsonString);

    await _db.transaction(() async {
      // 1. Insert Teacher first (without subjectId because Subjects references Teachers)
      final teacherData = data['teacher'] as Map<String, dynamic>;
      final teacherId = teacherData['id'] as String;
      final subjectName = teacherData['subjectName'] as String;
      final normalizedSubject = subjectName.trim().toLowerCase();

      final salt = PasswordHasher.generateSalt();
      const passwordIterations = PasswordHasher.currentIterations;
      final hash = PasswordHasher.hashPassword(
        teacherData['password'] as String,
        salt,
        iterations: passwordIterations,
      );

      await _db.into(_db.teachers).insertOnConflictUpdate(
            TeachersCompanion.insert(
              id: teacherId,
              firstName: teacherData['firstName'] as String,
              lastName: teacherData['lastName'] as String,
              profession: teacherData['profession'] as String,
              whatsappNumber: teacherData['whatsappNumber'] as String,
              subjectId: const Value.absent(),
              passwordHash: hash,
              passwordSalt: salt,
              passwordHashIterations: passwordIterations,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );

      // 2. Ensure Subject exists (belongs to teacherId)
      var subject = await (_db.select(_db.subjects)
            ..where((tbl) => tbl.teacherId.equals(teacherId) & tbl.normalizedName.equals(normalizedSubject)))
          .getSingleOrNull();

      if (subject == null) {
        const subjectId = 'subject-maths';
        await _db.into(_db.subjects).insertOnConflictUpdate(
              SubjectsCompanion.insert(
                id: subjectId,
                teacherId: teacherId,
                name: subjectName,
                normalizedName: normalizedSubject,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );
        subject = await (_db.select(_db.subjects)
              ..where((tbl) => tbl.id.equals(subjectId)))
            .getSingle();
      }

      // Link subjectId back to Teacher
      await (_db.update(_db.teachers)..where((t) => t.id.equals(teacherId)))
          .write(TeachersCompanion(subjectId: Value(subject.id)));

      // Set has seen onboarding
      await _db.into(_db.appSettings).insertOnConflictUpdate(
            AppSettingsCompanion.insert(
              key: 'has_seen_onboarding',
              value: 'true',
            ),
          );

      // 3. Academic Year & Periods
      final yearData = data['academicYear'] as Map<String, dynamic>;
      final yearId = yearData['id'] as String;
      await _db.into(_db.academicYears).insertOnConflictUpdate(
            AcademicYearsCompanion.insert(
              id: yearId,
              teacherId: teacherId,
              label: yearData['label'] as String,
              startDate: DateTime.parse(yearData['startDate'] as String),
              endDate: DateTime.parse(yearData['endDate'] as String),
              isActive: const Value(true),
            ),
          );

      final periodsData = data['periods'] as List<dynamic>;
      for (final p in periodsData) {
        final periodMap = p as Map<String, dynamic>;
        await _db.into(_db.academicPeriods).insertOnConflictUpdate(
              AcademicPeriodsCompanion.insert(
                id: periodMap['id'] as String,
                academicYearId: yearId,
                name: periodMap['name'] as String,
                startDate: DateTime.parse(periodMap['startDate'] as String),
                endDate: DateTime.parse(periodMap['endDate'] as String),
              ),
            );
      }

      // 4. Schools, Classes, Students, Evaluations, Grades
      final schoolsData = data['schools'] as List<dynamic>;
      for (final s in schoolsData) {
        final sMap = s as Map<String, dynamic>;
        final schoolId = sMap['id'] as String;

        await _db.into(_db.schools).insertOnConflictUpdate(
              SchoolsCompanion.insert(
                id: schoolId,
                teacherId: teacherId,
                name: sMap['name'] as String,
                type: sMap['type'] as String,
                city: sMap['city'] as String,
                address: Value(sMap['address'] as String?),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              ),
            );

        final classesData = sMap['classes'] as List<dynamic>;
        for (final c in classesData) {
          final cMap = c as Map<String, dynamic>;
          final classId = cMap['id'] as String;

          await _db.into(_db.schoolClasses).insertOnConflictUpdate(
                SchoolClassesCompanion.insert(
                  id: classId,
                  schoolId: schoolId,
                  academicYearId: yearId,
                  name: cMap['name'] as String,
                  level: cMap['level'] as String,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

          // ClassSubject link
          final classSubjectId = 'cs-$classId-${subject.id}';
          await _db.into(_db.classSubjects).insertOnConflictUpdate(
                ClassSubjectsCompanion.insert(
                  id: classSubjectId,
                  classId: classId,
                  subjectId: subject.id,
                ),
              );

          // Students
          final studentsData = cMap['students'] as List<dynamic>;
          for (final st in studentsData) {
            final stMap = st as Map<String, dynamic>;
            await _db.into(_db.students).insertOnConflictUpdate(
                  StudentsCompanion.insert(
                    id: stMap['id'] as String,
                    classId: classId,
                    firstName: stMap['firstName'] as String,
                    lastName: stMap['lastName'] as String,
                    gender: Value(stMap['gender'] as String?),
                    dateOfBirth: Value(
                      DateTime.tryParse(stMap['dateOfBirth'] as String? ?? ''),
                    ),
                    registrationNumber: Value(stMap['registrationNumber'] as String?),
                    orderNumber: Value(stMap['orderNumber'] as int?),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
          }

          // Evaluations
          final defaultPeriodId = periodsData.first['id'] as String;
          final evalsData = cMap['evaluations'] as List<dynamic>;
          for (final ev in evalsData) {
            final evMap = ev as Map<String, dynamic>;
            final evalId = evMap['id'] as String;

            await _db.into(_db.evaluations).insertOnConflictUpdate(
                  EvaluationsCompanion.insert(
                    id: evalId,
                    classSubjectId: classSubjectId,
                    academicPeriodId: defaultPeriodId,
                    type: evMap['type'] as String,
                    evaluationNumber: evMap['number'] as int,
                    title: Value(evMap['title'] as String?),
                    evaluationDate: DateTime.parse(evMap['date'] as String),
                    maxScore: (evMap['maxScore'] as num).toDouble(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
          }

          // Grades
          final gradesData = cMap['grades'] as List<dynamic>;
          for (final gr in gradesData) {
            final grMap = gr as Map<String, dynamic>;
            final evalId = grMap['evaluationId'] as String;
            final studentId = grMap['studentId'] as String;
            final gradeId = 'gr-$evalId-$studentId';

            await _db.into(_db.grades).insertOnConflictUpdate(
                  GradesCompanion.insert(
                    id: gradeId,
                    evaluationId: evalId,
                    studentId: studentId,
                    score: Value(grMap['score'] != null ? (grMap['score'] as num).toDouble() : null),
                    status: grMap['status'] as String,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                );
          }
        }
      }
    });
  }
}
