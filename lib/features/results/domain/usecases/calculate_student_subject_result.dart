import '../entities/result_input.dart';
import '../entities/student_subject_result.dart';

class CalculateStudentSubjectResult {
  const CalculateStudentSubjectResult();

  StudentSubjectResult call(Iterable<ResultInput> inputs) {
    final interrogations = <double>[];
    double? homework1;
    double? homework2;

    for (final input in inputs) {
      if (!input.maxScore.isFinite || input.maxScore <= 0) {
        throw ArgumentError.value(
          input.maxScore,
          'maxScore',
          'Must be positive.',
        );
      }

      if (input.status != ResultInputStatus.recorded) continue;
      final score = input.score;
      if (score == null ||
          !score.isFinite ||
          score < 0 ||
          score > input.maxScore) {
        throw ArgumentError.value(
          score,
          'score',
          'Must be within the evaluation scale.',
        );
      }

      final normalized = score / input.maxScore * 20;
      switch (input.kind) {
        case EvaluationKind.interrogation:
          interrogations.add(normalized);
        case EvaluationKind.homework1:
          homework1 = normalized;
        case EvaluationKind.homework2:
          homework2 = normalized;
      }
    }

    final interrogationMean = interrogations.isEmpty
        ? null
        : interrogations.reduce((sum, value) => sum + value) /
              interrogations.length;
    final finalMean =
        interrogationMean == null || homework1 == null || homework2 == null
        ? null
        : (interrogationMean + homework1 + homework2) / 3;

    return StudentSubjectResult(
      interrogationMean: interrogationMean,
      homework1: homework1,
      homework2: homework2,
      finalMean: finalMean,
    );
  }
}
