// lib/features/auth/data/models/user_model.dart
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Modelo alinhado com a tabela `public.users`.
/// Colunas: id, name, email, birth_date, created_at, city, Notify_birthday,
///          instagram_url, tiktok_url, spotify_url, updated_at
class UserModel {
  final String id;
  final String? name;
  final String email;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final String? city;
  final bool notifyBirthday;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.birthDate,
    this.createdAt,
    this.city,
    this.notifyBirthday = false,
    this.updatedAt,
  });

  // ---------- factories ----------
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    final s = v is String ? v : v.toString();
    return DateTime.tryParse(s);
  }

  /// Constrói directamente de uma row devolvida por `supabase.from('users')...`
  factory UserModel.fromUsersRow(Map<String, dynamic> row) {
    return UserModel(
      id: row['id'] as String,
      name: row['name'] as String?,
      email: row['email'] as String,
      birthDate: _parseDate(row['birth_date']),
      createdAt: _parseDate(row['created_at']),
      city: row['city'] as String?,
      notifyBirthday:
          (row['Notify_birthday'] as bool?) ??
          false, // <- coluna com N maiúsculo
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  /// Útil quando só tens o user do Auth e queres um modelo mínimo.
  factory UserModel.fromSupabaseUser(supa.User u) {
    return UserModel(id: u.id, email: u.email ?? '');
  }

  // ---------- serialização ----------
  /// Map para INSERT inicial (não inclui created_at/updated_at: deixa o DB preencher).
  Map<String, dynamic> toUsersInsert() => {
    'id': id,
    'email': email,
    if (name != null) 'name': name,
    if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
    if (city != null) 'city': city,
    'Notify_birthday': notifyBirthday,
  };

  /// Map para UPDATE/UPSERT incremental (patch).
  Map<String, dynamic> toUsersPatch() => {
    'email': email, // email é obrigatório
    if (name != null) 'name': name,
    if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
    if (city != null) 'city': city,
    'Notify_birthday': notifyBirthday,
  };

  // ---------- util ----------
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    DateTime? birthDate,
    DateTime? createdAt,
    String? city,
    bool? notifyBirthday,
    String? instagramUrl,
    String? tiktokUrl,
    String? spotifyUrl,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      notifyBirthday: notifyBirthday ?? this.notifyBirthday,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
