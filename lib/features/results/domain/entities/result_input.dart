enum ResultInputStatus { recorded, absent, notRecorded }

enum EvaluationKind { interrogation, homework1, homework2 }

class ResultInput {
  const ResultInput({
    required this.kind,
    required this.status,
    required this.maxScore,
    this.score,
  });

  final EvaluationKind kind;
  final ResultInputStatus status;
  final double maxScore;
  final double? score;
}
