class User {
  final String id;
  final String? name;
  final String email;
  final DateTime? dateOfBirth;

  const User({
    required this.id,
    required this.email,
    this.name,
    this.dateOfBirth,
  });
}
