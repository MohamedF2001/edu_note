class School {
  const School({
    required this.id,
    required this.teacherId,
    required this.name,
    required this.type,
    required this.city,
    this.address,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String teacherId;
  final String name;
  final String type;
  final String city;
  final String? address;
  final DateTime createdAt;
  final DateTime updatedAt;
}
