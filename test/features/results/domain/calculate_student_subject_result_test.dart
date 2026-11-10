import 'package:edu_note/features/results/domain/entities/result_input.dart';
import 'package:edu_note/features/results/domain/usecases/calculate_student_subject_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculate = CalculateStudentSubjectResult();

  test(
    'averages multiple interrogations and requires both homework grades',
    () {
      final result = calculate([
        const ResultInput(
          kind: EvaluationKind.interrogation,
          status: ResultInputStatus.recorded,
          score: 12,
          maxScore: 20,
        ),
        const ResultInput(
          kind: EvaluationKind.interrogation,
          status: ResultInputStatus.recorded,
          score: 16,
          maxScore: 20,
        ),
        const ResultInput(
          kind: EvaluationKind.homework1,
          status: ResultInputStatus.recorded,
          score: 13,
          maxScore: 20,
        ),
        const ResultInput(
          kind: EvaluationKind.homework2,
          status: ResultInputStatus.recorded,
          score: 16,
          maxScore: 20,
        ),
      ]);

      expect(result.interrogationMean, 14);
      expect(result.finalMean, closeTo(14.333333, 0.000001));
    },
  );

  test('leaves the final mean incomplete when a homework grade is missing', () {
    final result = calculate([
      const ResultInput(
        kind: EvaluationKind.interrogation,
        status: ResultInputStatus.recorded,
        score: 12,
        maxScore: 20,
      ),
      const ResultInput(
        kind: EvaluationKind.homework1,
        status: ResultInputStatus.recorded,
        score: 10,
        maxScore: 20,
      ),
      const ResultInput(
        kind: EvaluationKind.homework2,
        status: ResultInputStatus.notRecorded,
        maxScore: 20,
      ),
    ]);

    expect(result.interrogationMean, 12);
    expect(result.homework2, isNull);
    expect(result.finalMean, isNull);
  });

  test('keeps zero distinct from absence and normalizes non-20 scales', () {
    final result = calculate([
      const ResultInput(
        kind: EvaluationKind.interrogation,
        status: ResultInputStatus.absent,
        maxScore: 20,
      ),
      const ResultInput(
        kind: EvaluationKind.interrogation,
        status: ResultInputStatus.recorded,
        score: 0,
        maxScore: 20,
      ),
      const ResultInput(
        kind: EvaluationKind.homework1,
        status: ResultInputStatus.recorded,
        score: 8,
        maxScore: 10,
      ),
      const ResultInput(
        kind: EvaluationKind.homework2,
        status: ResultInputStatus.recorded,
        score: 16,
        maxScore: 20,
      ),
    ]);

    expect(result.interrogationMean, 0);
    expect(result.homework1, 16);
    expect(result.finalMean, closeTo(10.666666, 0.000001));
  });

  test(
    'returns no interrogation average when no interrogation is recorded',
    () {
      final result = calculate([
        const ResultInput(
          kind: EvaluationKind.homework1,
          status: ResultInputStatus.recorded,
          score: 10,
          maxScore: 20,
        ),
        const ResultInput(
          kind: EvaluationKind.homework2,
          status: ResultInputStatus.recorded,
          score: 10,
          maxScore: 20,
        ),
      ]);

      expect(result.interrogationMean, isNull);
      expect(result.finalMean, isNull);
    },
  );

  test('rejects a grade outside its evaluation scale', () {
    expect(
      () => calculate([
        const ResultInput(
          kind: EvaluationKind.interrogation,
          status: ResultInputStatus.recorded,
          score: 21,
          maxScore: 20,
        ),
      ]),
      throwsArgumentError,
    );
  });
}
