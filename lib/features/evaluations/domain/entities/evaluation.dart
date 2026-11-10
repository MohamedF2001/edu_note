enum EvaluationType { interrogation, homework1, homework2 }

class Evaluation {
  const Evaluation({
    required this.id,
    required this.classSubjectId,
    required this.academicPeriodId,
    required this.type,
    required this.evaluationNumber,
    required this.evaluationDate,
    required this.maxScore,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.title,
  });

  final String id;
  final String classSubjectId;
  final String academicPeriodId;
  final EvaluationType type;
  final int evaluationNumber;
  final DateTime evaluationDate;
  final double maxScore;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? title;

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    switch (type) {
      case EvaluationType.interrogation:
        return 'Interro. $evaluationNumber';
      case EvaluationType.homework1:
        return 'Devoir 1';
      case EvaluationType.homework2:
        return 'Devoir 2';
    }
  }

  String get typeLabel {
    switch (type) {
      case EvaluationType.interrogation:
        return 'Interrogation';
      case EvaluationType.homework1:
        return 'Devoir 1';
      case EvaluationType.homework2:
        return 'Devoir 2';
    }
  }
}
