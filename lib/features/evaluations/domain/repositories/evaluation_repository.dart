import '../entities/evaluation.dart';
import '../entities/grade.dart';

abstract class EvaluationRepository {
  /// Get all evaluations for a given class-subject association.
  Future<List<Evaluation>> getEvaluationsByClassSubject(String classSubjectId);

  /// Get all evaluations for a given academic period for a class-subject.
  Future<List<Evaluation>> getEvaluationsByPeriod({
    required String classSubjectId,
    required String academicPeriodId,
  });

  /// Get a single evaluation by ID.
  Future<Evaluation?> getEvaluationById(String id);

  /// Create a new evaluation.
  Future<Evaluation> createEvaluation({
    required String classSubjectId,
    required String academicPeriodId,
    required EvaluationType type,
    required DateTime evaluationDate,
    required double maxScore,
    String? title,
  });

  /// Update an existing evaluation.
  Future<void> updateEvaluation({
    required String id,
    required DateTime evaluationDate,
    required double maxScore,
    String? title,
  });

  /// Soft-delete (deactivate) an evaluation.
  Future<void> deleteEvaluation(String id);

  /// Get all grades for a given evaluation.
  Future<List<Grade>> getGradesByEvaluation(String evaluationId);

  /// Get all grades for a given student across all evaluations of a class-subject.
  Future<List<Grade>> getGradesByStudentAndClassSubject({
    required String studentId,
    required String classSubjectId,
  });

  /// Save (upsert) a grade for a student in an evaluation.
  Future<Grade> saveGrade({
    required String schoolId,
    required String evaluationId,
    required String studentId,
    required GradeStatus status,
    double? score,
  });

  /// Batch save grades for all students in an evaluation.
  Future<void> saveGradesBatch({
    required String schoolId,
    required List<Grade> grades,
  });
}
