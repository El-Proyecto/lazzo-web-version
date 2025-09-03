// lib/features/auth/data/models/user_model.dart
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Modelo alinhado com a tabela `public.users`.
/// Colunas: id, name, phone, birth_date, created_at, city, Notify_birthday,
///          instagram_url, tiktok_url, spotify_url, updated_at
class UserModel {
  final String id;
  final String? name;
  final String? phone;
  final DateTime? birthDate;
  final DateTime? createdAt;
  final String? city;
  final bool notifyBirthday;
  final String? instagramUrl;
  final String? tiktokUrl;
  final String? spotifyUrl;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    this.name,
    this.phone,
    this.birthDate,
    this.createdAt,
    this.city,
    this.notifyBirthday = false,
    this.instagramUrl,
    this.tiktokUrl,
    this.spotifyUrl,
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
      phone: row['phone'] as String?,
      birthDate: _parseDate(row['birth_date']),
      createdAt: _parseDate(row['created_at']),
      city: row['city'] as String?,
      notifyBirthday: (row['Notify_birthday'] as bool?) ?? false, // <- coluna com N maiúsculo
      instagramUrl: row['instagram_url'] as String?,
      tiktokUrl: row['tiktok_url'] as String?,
      spotifyUrl: row['spotify_url'] as String?,
      updatedAt: _parseDate(row['updated_at']),
    );
  }

  /// Útil quando só tens o user do Auth e queres um modelo mínimo.
  factory UserModel.fromSupabaseUser(supa.User u) {
    return UserModel(
      id: u.id,
      phone: u.phone,
    );
  }

  // ---------- serialização ----------
  /// Map para INSERT inicial (não inclui created_at/updated_at: deixa o DB preencher).
  Map<String, dynamic> toUsersInsert() => {
        'id': id,
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
        if (city != null) 'city': city,
        'Notify_birthday': notifyBirthday,
        if (instagramUrl != null) 'instagram_url': instagramUrl,
        if (tiktokUrl != null) 'tiktok_url': tiktokUrl,
        if (spotifyUrl != null) 'spotify_url': spotifyUrl,
      };

  /// Map para UPDATE/UPSERT incremental (patch).
  Map<String, dynamic> toUsersPatch() => {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (birthDate != null) 'birth_date': birthDate!.toIso8601String(),
        if (city != null) 'city': city,
        'Notify_birthday': notifyBirthday,
        if (instagramUrl != null) 'instagram_url': instagramUrl,
        if (tiktokUrl != null) 'tiktok_url': tiktokUrl,
        if (spotifyUrl != null) 'spotify_url': spotifyUrl,
      };

  // ---------- util ----------
  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
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
      name: name ?? this.name,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      createdAt: createdAt ?? this.createdAt,
      city: city ?? this.city,
      notifyBirthday: notifyBirthday ?? this.notifyBirthday,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      spotifyUrl: spotifyUrl ?? this.spotifyUrl,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
