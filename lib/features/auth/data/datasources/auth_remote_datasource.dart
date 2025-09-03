// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient client;
  AuthRemoteDatasource(this.client);

  // 1) Envia OTP por SMS
  Future<void> login(String phoneNumber) async {
    await sendOtp(phoneNumber);
  }

  // 2) Sign up + garante row em `users`
  Future<UserModel> register(
    String phoneNumber,
    String password,
    String username, // a tua tabela não tem username; fica só nos metadados de auth se quiseres
  ) async {
    try {
      final res = await client.auth.signUp(
        phone: phoneNumber,
        password: password,
        data: {'username': username},
      );
      final u = res.user;
      if (u == null) throw Exception('Registration failed: user is null');

      final row = await _upsertUsersRow(id: u.id, phone: u.phone);
      return UserModel.fromUsersRow(row);
    } on AuthException catch (e) {
      throw Exception('Registration failed: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Registration failed (DB): ${e.message}');
    } catch (e) {
      throw Exception('Registration failed: $e');
    }
  }

  // 3) Utilizador autenticado atual → lê row de `users` (se não existir, cria mínima)
  Future<UserModel?> getCurrentUser() async {
    final u = client.auth.currentUser;
    if (u == null) return null;

    final row = await _getUsersRow(u.id) ?? await _upsertUsersRow(id: u.id, phone: u.phone);
    return UserModel.fromUsersRow(row);
  }

  // 4) Logout
  Future<void> logout() async {
    await client.auth.signOut();
  }

  // 5) Envia OTP por SMS
  Future<void> sendOtp(String phoneNumber) async {
    await client.auth.signInWithOtp(phone: phoneNumber);
  }

  // 6) Verifica OTP + garante row em `users`
  Future<UserModel> verifyOtp(String phoneNumber, String token) async {
    try {
      final res = await client.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
      final u = res.user;
      if (u == null) throw Exception('OTP verification failed: user is null');

      final row = await _upsertUsersRow(id: u.id, phone: u.phone);
      return UserModel.fromUsersRow(row);
    } on AuthException catch (e) {
      throw Exception('OTP verification failed: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('OTP verification failed (DB): ${e.message}');
    } catch (e) {
      throw Exception('OTP verification failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers para a tabela `public.users`
  // ---------------------------------------------------------------------------

  /// Lê a row (ou null).
  Future<Map<String, dynamic>?> _getUsersRow(String uid) async {
    final row = await client
        .from('users')
        .select()           // <- sem genéricos
        .eq('id', uid)
        .maybeSingle();

    // if null, devolve null; senão, garante Map<String,dynamic>
    return row == null ? null : Map<String, dynamic>.from(row as Map);
  }

  /// Upsert idempotente: cria/atualiza a row com {id, phone}.
  /// Usa onConflict: 'id' para evitar race conditions.
  Future<Map<String, dynamic>> _upsertUsersRow({
    required String id,
    String? phone,
  }) async {
    final patch = <String, dynamic>{'id': id};
    if (phone != null) patch['phone'] = phone;

    final row = await client
        .from('users')
        .upsert(patch, onConflict: 'id')
        .select()          // <- sem genéricos
        .single();

    return Map<String, dynamic>.from(row as Map);
  }
}
