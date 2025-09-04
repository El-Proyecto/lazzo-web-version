class User {
  final String id;
  final String? name;
  final String username;
  final String phoneNumber;
  final DateTime? dateOfBirth;

  const User({
    required this.id,
    required this.phoneNumber,
    required this.username,
    this.name,
    this.dateOfBirth,
  });
}
