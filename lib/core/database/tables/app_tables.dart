import 'package:drift/drift.dart';

class Teachers extends Table {
  TextColumn get id => text()();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get profession => text()();
  TextColumn get subjectId => text().nullable().references(Subjects, #id)();
  TextColumn get whatsappNumber => text()();
  TextColumn get passwordHash => text()();
  TextColumn get passwordSalt => text()();
  IntColumn get passwordHashIterations => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Schools extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId =>
      text().references(Teachers, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get city => text()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class AcademicYears extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId =>
      text().references(Teachers, #id, onDelete: KeyAction.cascade)();
  TextColumn get label => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {teacherId, label},
  ];
}

class AcademicPeriods extends Table {
  TextColumn get id => text()();
  TextColumn get academicYearId =>
      text().references(AcademicYears, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {academicYearId, name},
  ];
}

class SchoolClasses extends Table {
  TextColumn get id => text()();
  TextColumn get schoolId =>
      text().references(Schools, #id, onDelete: KeyAction.cascade)();
  TextColumn get academicYearId =>
      text().references(AcademicYears, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get level => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {schoolId, academicYearId, name},
  ];
}

class Students extends Table {
  TextColumn get id => text()();
  TextColumn get classId =>
      text().references(SchoolClasses, #id, onDelete: KeyAction.cascade)();
  TextColumn get firstName => text()();
  TextColumn get lastName => text()();
  TextColumn get gender => text().nullable()();
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get registrationNumber => text().nullable()();
  IntColumn get orderNumber => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Subjects extends Table {
  TextColumn get id => text()();
  TextColumn get teacherId =>
      text().references(Teachers, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get normalizedName => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {teacherId, normalizedName},
  ];
}

class ClassSubjects extends Table {
  TextColumn get id => text()();
  TextColumn get classId =>
      text().references(SchoolClasses, #id, onDelete: KeyAction.cascade)();
  TextColumn get subjectId =>
      text().references(Subjects, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {classId, subjectId},
  ];
}

class Evaluations extends Table {
  TextColumn get id => text()();
  TextColumn get classSubjectId =>
      text().references(ClassSubjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get academicPeriodId =>
      text().references(AcademicPeriods, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()();
  IntColumn get evaluationNumber => integer()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get evaluationDate => dateTime()();
  RealColumn get maxScore => real().customConstraint('CHECK (max_score > 0)')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class Grades extends Table {
  TextColumn get id => text()();
  TextColumn get evaluationId =>
      text().references(Evaluations, #id, onDelete: KeyAction.cascade)();
  TextColumn get studentId =>
      text().references(Students, #id, onDelete: KeyAction.cascade)();
  RealColumn get score => real().nullable()();
  TextColumn get status => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {evaluationId, studentId},
  ];
}

class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
