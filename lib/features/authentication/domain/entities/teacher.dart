class Teacher {
  const Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.profession,
    required this.subjectId,
    required this.canChangeSubject,
    required this.whatsappNumber,
    required this.passwordHash,
    required this.passwordSalt,
    required this.passwordHashIterations,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String profession;
  final String? subjectId;
  final bool canChangeSubject;
  final String whatsappNumber;
  final String passwordHash;
  final String passwordSalt;
  final int passwordHashIterations;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get fullName => '$firstName $lastName';
}
