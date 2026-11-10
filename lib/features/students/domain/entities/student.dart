class Student {
  const Student({
    required this.id,
    required this.classId,
    required this.firstName,
    required this.lastName,
    this.gender,
    this.dateOfBirth,
    this.registrationNumber,
    this.orderNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String classId;
  final String firstName;
  final String lastName;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? registrationNumber;
  final int? orderNumber;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$lastName $firstName'.trim();
}
