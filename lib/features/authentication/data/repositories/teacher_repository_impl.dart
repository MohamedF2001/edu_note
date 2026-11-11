import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart' hide Teacher;
import '../../domain/entities/teacher.dart';
import '../../domain/repositories/teacher_repository.dart';
import '../utils/password_hasher.dart';

class TeacherRepositoryImpl implements TeacherRepository {
  TeacherRepositoryImpl(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  @override
  Future<Teacher?> getTeacherProfile() async {
    final row = await (_database.select(_database.teachers)).getSingleOrNull();
    if (row == null) return null;
    final historicalRows = _database.select(_database.evaluations).join([
      innerJoin(
        _database.classSubjects,
        _database.classSubjects.id.equalsExp(
          _database.evaluations.classSubjectId,
        ),
      ),
      innerJoin(
        _database.schoolClasses,
        _database.schoolClasses.id.equalsExp(_database.classSubjects.classId),
      ),
      innerJoin(
        _database.schools,
        _database.schools.id.equalsExp(_database.schoolClasses.schoolId),
      ),
    ])..where(_database.schools.teacherId.equals(row.id));
    final historical = await historicalRows.get();
    final historicalSubjectIds = historical
        .map((item) => item.readTable(_database.classSubjects).subjectId)
        .toSet();
    return Teacher(
      id: row.id,
      firstName: row.firstName,
      lastName: row.lastName,
      profession: row.profession,
      subjectId: row.subjectId,
      canChangeSubject:
          historical.isEmpty ||
          (row.subjectId == null && historicalSubjectIds.length == 1),
      whatsappNumber: row.whatsappNumber,
      passwordHash: row.passwordHash,
      passwordSalt: row.passwordSalt,
      passwordHashIterations: row.passwordHashIterations,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  @override
  Future<void> registerTeacher({
    required String firstName,
    required String lastName,
    required String profession,
    required String subjectName,
    required String whatsappNumber,
    required String password,
  }) async {
    final salt = PasswordHasher.generateSalt();
    const iterations = PasswordHasher.currentIterations;
    final hash = PasswordHasher.hashPassword(
      password,
      salt,
      iterations: iterations,
    );
    final now = DateTime.now();
    final id = _uuid.v4();

    final trimmedSubject = subjectName.trim();
    if (trimmedSubject.isEmpty) {
      throw ArgumentError.value(subjectName, 'subjectName', 'Requis');
    }

    await _database.transaction(() async {
      await _database
          .into(_database.teachers)
          .insert(
            TeachersCompanion.insert(
              id: id,
              firstName: firstName,
              lastName: lastName,
              profession: profession,
              subjectId: const Value.absent(),
              whatsappNumber: whatsappNumber,
              passwordHash: hash,
              passwordSalt: salt,
              passwordHashIterations: iterations,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final normalizedSubject = trimmedSubject.toLowerCase().replaceAll(
        RegExp(r'\s+'),
        ' ',
      );
      final subjectId = _uuid.v4();
      await _database
          .into(_database.subjects)
          .insert(
            SubjectsCompanion.insert(
              id: subjectId,
              teacherId: id,
              name: trimmedSubject,
              normalizedName: normalizedSubject,
              createdAt: now,
              updatedAt: now,
            ),
          );
      await (_database.update(_database.teachers)
            ..where((teacher) => teacher.id.equals(id)))
          .write(TeachersCompanion(subjectId: Value(subjectId)));
    });
  }

  @override
  Future<bool> authenticateTeacher(String password) async {
    final teacher = await getTeacherProfile();
    if (teacher == null) return false;
    final verifiedIterations = teacher.passwordHashIterations;
    var needsRehash =
        verifiedIterations != PasswordHasher.currentIterations;
    var valid = PasswordHasher.verifyPassword(
      password,
      teacher.passwordSalt,
      teacher.passwordHash,
      iterations: verifiedIterations,
    );
    // Older sample data imports stored the current hash with incorrect
    // iteration metadata. Accept that demo-only format and repair it below.
    if (!valid && teacher.id == 'teacher-demo') {
      valid = PasswordHasher.verifyPassword(
        password,
        teacher.passwordSalt,
        teacher.passwordHash,
        iterations: PasswordHasher.currentIterations,
      );
      if (valid) needsRehash = true;
    }
    if (valid && needsRehash) {
      final salt = PasswordHasher.generateSalt();
      await (_database.update(
        _database.teachers,
      )..where((row) => row.id.equals(teacher.id))).write(
        TeachersCompanion(
          passwordSalt: Value(salt),
          passwordHash: Value(PasswordHasher.hashPassword(password, salt)),
          passwordHashIterations: Value(PasswordHasher.currentIterations),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    return valid;
  }

  @override
  Future<void> setTeacherSubject(String subjectName) async {
    final teacher = await (_database.select(_database.teachers))
        .getSingleOrNull();
    if (teacher == null) throw StateError('Aucun profil enseignant trouvé.');

    final normalized = subjectName.trim().toLowerCase().replaceAll(
      RegExp(r'\s+'),
      ' ',
    );
    if (normalized.isEmpty) {
      throw ArgumentError.value(subjectName, 'subjectName', 'Requis');
    }

    final historicalRows = _database.select(_database.evaluations).join([
      innerJoin(
        _database.classSubjects,
        _database.classSubjects.id.equalsExp(
          _database.evaluations.classSubjectId,
        ),
      ),
      innerJoin(
        _database.schoolClasses,
        _database.schoolClasses.id.equalsExp(_database.classSubjects.classId),
      ),
      innerJoin(
        _database.schools,
        _database.schools.id.equalsExp(_database.schoolClasses.schoolId),
      ),
    ])..where(_database.schools.teacherId.equals(teacher.id));
    final historical = await historicalRows.get();
    final historicalSubjectIds = historical
        .map((item) => item.readTable(_database.classSubjects).subjectId)
        .toSet();

    final existingSubject =
        await (_database.select(_database.subjects)..where(
              (subject) =>
                  subject.teacherId.equals(teacher.id) &
                  subject.normalizedName.equals(normalized),
            ))
            .getSingleOrNull();

    if (historicalSubjectIds.length > 1) {
      throw StateError(
        'Les anciennes évaluations utilisent plusieurs matières. Leur historique doit être résolu avant de définir la matière unique.',
      );
    }
    if (historicalSubjectIds.isNotEmpty &&
        (existingSubject == null ||
            !historicalSubjectIds.contains(existingSubject.id))) {
      throw StateError(
        'La matière ne peut pas être changée après la création d’évaluations.',
      );
    }

    await _database.transaction(() async {
      var subjectId = existingSubject?.id;
      if (subjectId == null) {
        subjectId = _uuid.v4();
        final now = DateTime.now();
        await _database
            .into(_database.subjects)
            .insert(
              SubjectsCompanion.insert(
                id: subjectId,
                teacherId: teacher.id,
                name: subjectName.trim(),
                normalizedName: normalized,
                createdAt: now,
                updatedAt: now,
              ),
            );
      }
      await (_database.update(_database.teachers)
            ..where((row) => row.id.equals(teacher.id)))
          .write(TeachersCompanion(subjectId: Value(subjectId)));

      if (historicalSubjectIds.isEmpty) {
        final classRows = _database.select(_database.schoolClasses).join([
          innerJoin(
            _database.schools,
            _database.schools.id.equalsExp(_database.schoolClasses.schoolId),
          ),
        ])..where(_database.schools.teacherId.equals(teacher.id));
        for (final row in await classRows.get()) {
          final schoolClass = row.readTable(_database.schoolClasses);
          await (_database.delete(
            _database.classSubjects,
          )..where((item) => item.classId.equals(schoolClass.id))).go();
          await _database
              .into(_database.classSubjects)
              .insert(
                ClassSubjectsCompanion.insert(
                  id: _uuid.v4(),
                  classId: schoolClass.id,
                  subjectId: subjectId,
                ),
              );
        }
      }
    });
  }
}
