import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/entities/student.dart' as domain;
import '../../domain/repositories/student_repository.dart';

class StudentRepositoryImpl implements StudentRepository {
  StudentRepositoryImpl(this._database);

  final AppDatabase _database;
  static const _uuid = Uuid();

  @override
  Future<List<domain.Student>> getStudentsByClass(
    String classId, {
    String? searchQuery,
    String? sortBy,
  }) async {
    final query = _database.select(_database.students)
      ..where((t) => t.classId.equals(classId));

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim().toLowerCase()}%';
      query.where(
        (t) =>
            t.firstName.lower().like(q) |
            t.lastName.lower().like(q) |
            t.registrationNumber.lower().like(q),
      );
    }

    if (sortBy == 'orderNumber') {
      query.orderBy([
        (t) => OrderingTerm.asc(t.orderNumber),
        (t) => OrderingTerm.asc(t.lastName),
      ]);
    } else {
      query.orderBy([
        (t) => OrderingTerm.asc(t.lastName),
        (t) => OrderingTerm.asc(t.firstName),
      ]);
    }

    final rows = await query.get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<domain.Student?> getStudentById(String id) async {
    final row = await (_database.select(_database.students)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row != null ? _mapToDomain(row) : null;
  }

  @override
  Future<void> createStudent({
    required String classId,
    required String firstName,
    required String lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? registrationNumber,
    int? orderNumber,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();

    // Si le numéro d'ordre n'est pas fourni, le calculer automatiquement
    int? calculatedOrder = orderNumber;
    if (calculatedOrder == null) {
      final existing = await (_database.select(_database.students)
            ..where((t) => t.classId.equals(classId)))
          .get();
      calculatedOrder = existing.length + 1;
    }

    await _database.into(_database.students).insert(
          StudentsCompanion.insert(
            id: id,
            classId: classId,
            firstName: firstName.trim(),
            lastName: lastName.trim(),
            gender: Value(gender?.trim()),
            dateOfBirth: Value(dateOfBirth),
            registrationNumber: Value(registrationNumber?.trim()),
            orderNumber: Value(calculatedOrder),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  @override
  Future<void> updateStudent({
    required String id,
    required String firstName,
    required String lastName,
    String? gender,
    DateTime? dateOfBirth,
    String? registrationNumber,
    int? orderNumber,
  }) async {
    await (_database.update(_database.students)..where((t) => t.id.equals(id)))
        .write(
      StudentsCompanion(
        firstName: Value(firstName.trim()),
        lastName: Value(lastName.trim()),
        gender: Value(gender?.trim()),
        dateOfBirth: Value(dateOfBirth),
        registrationNumber: Value(registrationNumber?.trim()),
        orderNumber: Value(orderNumber),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> deleteStudent(String id) async {
    await _database.transaction(() async {
      await (_database.delete(_database.students)..where((t) => t.id.equals(id)))
          .go();
    });
  }

  @override
  Future<String> generateNextRegistrationNumber(String classId) async {
    final existing = await (_database.select(_database.students)
          ..where((t) => t.classId.equals(classId)))
        .get();
    final nextNumber = existing.length + 1;
    final year = DateTime.now().year;
    return 'MAT-$year-${nextNumber.toString().padLeft(3, '0')}';
  }

  domain.Student _mapToDomain(Student row) {
    return domain.Student(
      id: row.id,
      classId: row.classId,
      firstName: row.firstName,
      lastName: row.lastName,
      gender: row.gender,
      dateOfBirth: row.dateOfBirth,
      registrationNumber: row.registrationNumber,
      orderNumber: row.orderNumber,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
