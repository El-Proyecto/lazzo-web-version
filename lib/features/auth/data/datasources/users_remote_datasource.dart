// lib/features/profile/data/datasources/users_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class UsersRemoteDatasource {
  final SupabaseClient _sb;
  UsersRemoteDatasource(this._sb);

  Future<Map<String, dynamic>?> _getRow(String uid) async {
    final row = await _sb.from('users').select().eq('id', uid).maybeSingle();
    return row == null ? null : Map<String, dynamic>.from(row as Map);
  }

  Future<Map<String, dynamic>> _insertMinimal({
    required String id,
    required String phone,
    Map<String, dynamic> extra = const {},
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final data = <String, dynamic>{
      'id': id,
      'phone': phone,                 // <- NOT NULL garantido aqui
      'updated_at': nowIso,
      ...extra,
    };
    final row = await _sb.from('users').insert(data).select().single();
    return Map<String, dynamic>.from(row as Map);
  }

  /// Atualiza campos; se não existir a row, cria-a com {id, phone(auth)} + patch.
  Future<void> upsertPatch(Map<String, dynamic> patch) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');

    final existing = await _getRow(uid);
    final nowIso = DateTime.now().toUtc().toIso8601String();

    if (existing == null) {
      final authPhone = _sb.auth.currentUser?.phone;
      if (authPhone == null || authPhone.isEmpty) {
        throw Exception('Cannot create user row: phone is required by DB and auth has no phone (not verified?).');
      }
      await _insertMinimal(id: uid, phone: authPhone, extra: patch);
      return;
    }

    // Row existe → UPDATE incremental
    final data = <String, dynamic>{
      ...patch,
      'updated_at': nowIso,
    };
    await _sb.from('users').update(data).eq('id', uid);
  }

  Future<Map<String, dynamic>?> fetch() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    return _getRow(uid);
  }
}
