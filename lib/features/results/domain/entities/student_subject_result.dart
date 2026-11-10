class StudentSubjectResult {
  const StudentSubjectResult({
    required this.interrogationMean,
    required this.homework1,
    required this.homework2,
    required this.finalMean,
  });

  final double? interrogationMean;
  final double? homework1;
  final double? homework2;
  final double? finalMean;

  bool get isComplete => finalMean != null;
}
