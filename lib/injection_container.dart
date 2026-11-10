import 'package:get_it/get_it.dart';

import 'core/database/app_database.dart';
import 'features/academic_years/data/repositories/academic_year_repository_impl.dart';
import 'features/academic_years/domain/repositories/academic_year_repository.dart';
import 'features/academic_years/domain/usecases/create_academic_year.dart';
import 'features/academic_years/domain/usecases/get_academic_periods.dart';
import 'features/academic_years/domain/usecases/get_academic_years.dart';
import 'features/academic_years/domain/usecases/get_active_academic_year.dart';
import 'features/academic_years/domain/usecases/set_active_academic_year.dart';
import 'features/authentication/data/repositories/teacher_repository_impl.dart';
import 'features/authentication/domain/repositories/teacher_repository.dart';
import 'features/authentication/domain/usecases/authenticate_teacher.dart';
import 'features/authentication/domain/usecases/get_teacher_profile.dart';
import 'features/authentication/domain/usecases/register_teacher.dart';
import 'features/authentication/domain/usecases/set_teacher_subject.dart';
import 'features/classes/data/repositories/class_repository_impl.dart';
import 'features/classes/domain/repositories/class_repository.dart';
import 'features/classes/domain/usecases/create_class.dart';
import 'features/classes/domain/usecases/delete_class.dart';
import 'features/classes/domain/usecases/get_all_classes.dart';
import 'features/classes/domain/usecases/get_class_by_id.dart';
import 'features/classes/domain/usecases/get_classes_by_school.dart';
import 'features/classes/domain/usecases/update_class.dart';
import 'features/evaluations/data/repositories/evaluation_repository_impl.dart';
import 'features/evaluations/domain/repositories/evaluation_repository.dart';
import 'features/evaluations/domain/usecases/create_evaluation.dart';
import 'features/evaluations/domain/usecases/delete_evaluation.dart';
import 'features/evaluations/domain/usecases/get_evaluations_by_class_subject.dart';
import 'features/evaluations/domain/usecases/get_evaluations_by_period.dart';
import 'features/evaluations/domain/usecases/get_grades_by_evaluation.dart';
import 'features/evaluations/domain/usecases/get_grades_by_student_and_class_subject.dart';
import 'features/evaluations/domain/usecases/save_grade.dart';
import 'features/evaluations/domain/usecases/save_grades_batch.dart';
import 'features/schools/data/repositories/school_repository_impl.dart';
import 'features/schools/domain/repositories/school_repository.dart';
import 'features/schools/domain/usecases/create_school.dart';
import 'features/schools/domain/usecases/delete_school.dart';
import 'features/schools/domain/usecases/get_school_by_id.dart';
import 'features/schools/domain/usecases/get_schools.dart';
import 'features/schools/domain/usecases/update_school.dart';
import 'features/students/data/repositories/student_repository_impl.dart';
import 'features/students/domain/repositories/student_repository.dart';
import 'features/students/domain/usecases/create_student.dart';
import 'features/students/domain/usecases/delete_student.dart';
import 'features/students/domain/usecases/generate_registration_number.dart';
import 'features/students/domain/usecases/get_student_by_id.dart';
import 'features/students/domain/usecases/get_students_by_class.dart';
import 'features/students/domain/usecases/update_student.dart';
import 'features/subjects/data/repositories/subject_repository_impl.dart';
import 'features/subjects/domain/repositories/subject_repository.dart';
import 'features/subjects/domain/usecases/assign_subject_to_class.dart';
import 'features/subjects/domain/usecases/create_subject.dart';
import 'features/subjects/domain/usecases/delete_subject.dart';
import 'features/subjects/domain/usecases/ensure_default_subjects.dart';
import 'features/subjects/domain/usecases/get_subject_by_id.dart';
import 'features/subjects/domain/usecases/get_subjects.dart';
import 'features/subjects/domain/usecases/get_subjects_by_class.dart';
import 'features/subjects/domain/usecases/remove_subject_from_class.dart';
import 'features/subjects/domain/usecases/update_subject.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies({AppDatabase? database}) async {
  if (database != null) {
    if (getIt.isRegistered<AppDatabase>()) {
      await getIt.unregister<AppDatabase>();
    }
    getIt.registerSingleton<AppDatabase>(database);
  } else if (!getIt.isRegistered<AppDatabase>()) {
    getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
  }

  // Repositories
  if (!getIt.isRegistered<TeacherRepository>()) {
    getIt.registerLazySingleton<TeacherRepository>(
      () => TeacherRepositoryImpl(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<SchoolRepository>()) {
    getIt.registerLazySingleton<SchoolRepository>(
      () => SchoolRepositoryImpl(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<AcademicYearRepository>()) {
    getIt.registerLazySingleton<AcademicYearRepository>(
      () => AcademicYearRepositoryImpl(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<ClassRepository>()) {
    getIt.registerLazySingleton<ClassRepository>(
      () => ClassRepositoryImpl(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<StudentRepository>()) {
    getIt.registerLazySingleton<StudentRepository>(
      () => StudentRepositoryImpl(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<SubjectRepository>()) {
    getIt.registerLazySingleton<SubjectRepository>(
      () => SubjectRepositoryImpl(getIt<AppDatabase>()),
    );
  }
  if (!getIt.isRegistered<EvaluationRepository>()) {
    getIt.registerLazySingleton<EvaluationRepository>(
      () => EvaluationRepositoryImpl(getIt<AppDatabase>()),
    );
  }

  // Use Cases - Authentication
  if (!getIt.isRegistered<RegisterTeacher>()) {
    getIt.registerLazySingleton(
      () => RegisterTeacher(getIt<TeacherRepository>()),
    );
  }
  if (!getIt.isRegistered<GetTeacherProfile>()) {
    getIt.registerLazySingleton(
      () => GetTeacherProfile(getIt<TeacherRepository>()),
    );
  }
  if (!getIt.isRegistered<AuthenticateTeacher>()) {
    getIt.registerLazySingleton(
      () => AuthenticateTeacher(getIt<TeacherRepository>()),
    );
  }
  if (!getIt.isRegistered<SetTeacherSubject>()) {
    getIt.registerLazySingleton(
      () => SetTeacherSubject(getIt<TeacherRepository>()),
    );
  }

  // Use Cases - Schools
  if (!getIt.isRegistered<GetSchools>()) {
    getIt.registerLazySingleton(() => GetSchools(getIt<SchoolRepository>()));
  }
  if (!getIt.isRegistered<GetSchoolById>()) {
    getIt.registerLazySingleton(() => GetSchoolById(getIt<SchoolRepository>()));
  }
  if (!getIt.isRegistered<CreateSchool>()) {
    getIt.registerLazySingleton(() => CreateSchool(getIt<SchoolRepository>()));
  }
  if (!getIt.isRegistered<UpdateSchool>()) {
    getIt.registerLazySingleton(() => UpdateSchool(getIt<SchoolRepository>()));
  }
  if (!getIt.isRegistered<DeleteSchool>()) {
    getIt.registerLazySingleton(() => DeleteSchool(getIt<SchoolRepository>()));
  }

  // Use Cases - Academic Years
  if (!getIt.isRegistered<GetAcademicYears>()) {
    getIt.registerLazySingleton(
      () => GetAcademicYears(getIt<AcademicYearRepository>()),
    );
  }
  if (!getIt.isRegistered<GetActiveAcademicYear>()) {
    getIt.registerLazySingleton(
      () => GetActiveAcademicYear(getIt<AcademicYearRepository>()),
    );
  }
  if (!getIt.isRegistered<SetActiveAcademicYear>()) {
    getIt.registerLazySingleton(
      () => SetActiveAcademicYear(getIt<AcademicYearRepository>()),
    );
  }
  if (!getIt.isRegistered<CreateAcademicYear>()) {
    getIt.registerLazySingleton(
      () => CreateAcademicYear(getIt<AcademicYearRepository>()),
    );
  }
  if (!getIt.isRegistered<GetAcademicPeriods>()) {
    getIt.registerLazySingleton(
      () => GetAcademicPeriods(getIt<AcademicYearRepository>()),
    );
  }

  // Use Cases - Classes
  if (!getIt.isRegistered<GetClassesBySchool>()) {
    getIt.registerLazySingleton(
      () => GetClassesBySchool(getIt<ClassRepository>()),
    );
  }
  if (!getIt.isRegistered<GetAllClasses>()) {
    getIt.registerLazySingleton(() => GetAllClasses(getIt<ClassRepository>()));
  }
  if (!getIt.isRegistered<GetClassById>()) {
    getIt.registerLazySingleton(() => GetClassById(getIt<ClassRepository>()));
  }
  if (!getIt.isRegistered<CreateClass>()) {
    getIt.registerLazySingleton(() => CreateClass(getIt<ClassRepository>()));
  }
  if (!getIt.isRegistered<UpdateClass>()) {
    getIt.registerLazySingleton(() => UpdateClass(getIt<ClassRepository>()));
  }
  if (!getIt.isRegistered<DeleteClass>()) {
    getIt.registerLazySingleton(() => DeleteClass(getIt<ClassRepository>()));
  }

  // Use Cases - Students
  if (!getIt.isRegistered<GetStudentsByClass>()) {
    getIt.registerLazySingleton(
      () => GetStudentsByClass(getIt<StudentRepository>()),
    );
  }
  if (!getIt.isRegistered<GetStudentById>()) {
    getIt.registerLazySingleton(
      () => GetStudentById(getIt<StudentRepository>()),
    );
  }
  if (!getIt.isRegistered<CreateStudent>()) {
    getIt.registerLazySingleton(
      () => CreateStudent(getIt<StudentRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdateStudent>()) {
    getIt.registerLazySingleton(
      () => UpdateStudent(getIt<StudentRepository>()),
    );
  }
  if (!getIt.isRegistered<DeleteStudent>()) {
    getIt.registerLazySingleton(
      () => DeleteStudent(getIt<StudentRepository>()),
    );
  }
  if (!getIt.isRegistered<GenerateRegistrationNumber>()) {
    getIt.registerLazySingleton(
      () => GenerateRegistrationNumber(getIt<StudentRepository>()),
    );
  }

  // Use Cases - Subjects
  if (!getIt.isRegistered<GetSubjects>()) {
    getIt.registerLazySingleton(() => GetSubjects(getIt<SubjectRepository>()));
  }
  if (!getIt.isRegistered<GetSubjectById>()) {
    getIt.registerLazySingleton(
      () => GetSubjectById(getIt<SubjectRepository>()),
    );
  }
  if (!getIt.isRegistered<CreateSubject>()) {
    getIt.registerLazySingleton(
      () => CreateSubject(getIt<SubjectRepository>()),
    );
  }
  if (!getIt.isRegistered<UpdateSubject>()) {
    getIt.registerLazySingleton(
      () => UpdateSubject(getIt<SubjectRepository>()),
    );
  }
  if (!getIt.isRegistered<DeleteSubject>()) {
    getIt.registerLazySingleton(
      () => DeleteSubject(getIt<SubjectRepository>()),
    );
  }
  if (!getIt.isRegistered<GetSubjectsByClass>()) {
    getIt.registerLazySingleton(
      () => GetSubjectsByClass(getIt<SubjectRepository>()),
    );
  }
  if (!getIt.isRegistered<AssignSubjectToClass>()) {
    getIt.registerLazySingleton(
      () => AssignSubjectToClass(getIt<SubjectRepository>()),
    );
  }
  if (!getIt.isRegistered<RemoveSubjectFromClass>()) {
    getIt.registerLazySingleton(
      () => RemoveSubjectFromClass(getIt<SubjectRepository>()),
    );
  }
  if (!getIt.isRegistered<EnsureDefaultSubjects>()) {
    getIt.registerLazySingleton(
      () => EnsureDefaultSubjects(getIt<SubjectRepository>()),
    );
  }

  // Use Cases - Evaluations & Grades
  if (!getIt.isRegistered<GetEvaluationsByClassSubject>()) {
    getIt.registerLazySingleton(
      () => GetEvaluationsByClassSubject(getIt<EvaluationRepository>()),
    );
  }
  if (!getIt.isRegistered<GetEvaluationsByPeriod>()) {
    getIt.registerLazySingleton(
      () => GetEvaluationsByPeriod(getIt<EvaluationRepository>()),
    );
  }
  if (!getIt.isRegistered<CreateEvaluation>()) {
    getIt.registerLazySingleton(
      () => CreateEvaluation(getIt<EvaluationRepository>()),
    );
  }
  if (!getIt.isRegistered<DeleteEvaluation>()) {
    getIt.registerLazySingleton(
      () => DeleteEvaluation(getIt<EvaluationRepository>()),
    );
  }
  if (!getIt.isRegistered<GetGradesByEvaluation>()) {
    getIt.registerLazySingleton(
      () => GetGradesByEvaluation(getIt<EvaluationRepository>()),
    );
  }
  if (!getIt.isRegistered<SaveGrade>()) {
    getIt.registerLazySingleton(() => SaveGrade(getIt<EvaluationRepository>()));
  }
  if (!getIt.isRegistered<SaveGradesBatch>()) {
    getIt.registerLazySingleton(
      () => SaveGradesBatch(getIt<EvaluationRepository>()),
    );
  }
  if (!getIt.isRegistered<GetGradesByStudentAndClassSubject>()) {
    getIt.registerLazySingleton(
      () => GetGradesByStudentAndClassSubject(getIt<EvaluationRepository>()),
    );
  }
}
