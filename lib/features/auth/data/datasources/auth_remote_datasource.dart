// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient client;
  AuthRemoteDatasource(this.client);

  // 1) Login com email e OTP
  Future<void> login(String email) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();

      // Verifica se o usuário existe antes de enviar OTP

      final existingUser = await client
          .from('users')
          .select('id')
          .eq('email', trimmedEmail)
          .maybeSingle();

      if (existingUser == null) {
        throw Exception(
          'User Not Found. Please register before logging in.',
        );
      }

      // Envia OTP apenas para usuários existentes
      await client.auth.signInWithOtp(
        email: trimmedEmail,
        shouldCreateUser: false,
        //emailRedirectTo: null, // Desabilita magic link
        data: {
          'type': 'login',
          'app': 'lazzo',
          'method': 'otp', // Indica preferência por OTP
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  // 2) Sign up + garante row em `users`
  Future<void> register(String email) async {
    try {
      final trimmedEmail = email.trim().toLowerCase();

      await client.auth.signInWithOtp(
        email: trimmedEmail,
        shouldCreateUser: true,
        emailRedirectTo: null, // Desabilita magic link
        data: {
          'type': 'signup',
          'app': 'lazzo',
          'method': 'otp', // Indica preferência por OTP
        },
      );
    } catch (e) {
      throw Exception('Falha ao enviar código de verificação: ${e.toString()}');
    }
  }

  // 3) Utilizador autenticado atual → lê row de `users`
  // Se o user não existe na BD (ex: após TRUNCATE), força logout
  // Se a sessão foi invalidada no servidor, força logout local
  Future<UserModel?> getCurrentUser() async {
    final u = client.auth.currentUser;
    if (u == null) return null;

    try {
      // Primeiro verifica se há uma sessão local
      final session = client.auth.currentSession;
      if (session == null) {
        await client.auth.signOut();
        return null;
      }

      // Tenta refrescar a sessão com o servidor
      // Isto falhará se a sessão foi eliminada no Supabase (ex: DELETE FROM auth.sessions)
      try {
        await client.auth.refreshSession();
      } catch (refreshError) {
        // Refresh falhou = sessão inválida no servidor
        await client.auth.signOut();
        return null;
      }

      // Verifica se o user existe na tabela public.users
      final row = await _getUsersRow(u.id);
      
      // Se user existe na auth mas não na tabela users, força logout
      // Isto acontece após TRUNCATE ou se os dados foram apagados
      if (row == null) {
        await client.auth.signOut();
        return null;
      }
      
      return UserModel.fromUsersRow(row);
    } catch (e) {
      // Em caso de erro de BD (conexão, RLS, etc), força logout para evitar estado inconsistente
      await client.auth.signOut();
      return null;
    }
  }

  // 4) Logout
  Future<void> logout() async {
    await client.auth.signOut();
  }

  // 5) Envia OTP por SMS
  /* Future<void> sendOtp(String phoneNumber) async {
    await client.auth.signInWithOtp(phone: phoneNumber);
  }
*/
  // Verifica OTP + garante row em `users`
  // isSignup: true para novos users (signup), false para login existente
  Future<UserModel> verifyOtp({
    required String email,
    required String token,
    String? name,
    bool isSignup = false,
  }) async {
    try {
      // Usar o tipo correto de OTP:
      // - OtpType.signup para shouldCreateUser: true (signup)
      // - OtpType.email para shouldCreateUser: false (login)
      final otpType = isSignup ? OtpType.signup : OtpType.email;

      final AuthResponse response = await client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: otpType,
      );

      // Debug

      // 3) Verificar se temos usuário e sessão
      final u = response.user;
      if (u == null || response.session == null) {
        throw Exception('Falha na autenticação: usuário ou sessão inválidos');
      }

      // Debug
      final row = await _upsertUsersRow(id: u.id, email: email, name: name);
      // Debug

      return UserModel.fromUsersRow(row);
    } on AuthException catch (e) {
      // Debug
      throw Exception('Falha na verificação OTP: ${e.message}');
    } on PostgrestException catch (e) {
      // Debug
      throw Exception('Falha na verificação OTP (DB): ${e.message}');
    } catch (e) {
      // Debug
      throw Exception('Falha na verificação OTP: $e');
    }
  }

  // Mantém o teu _upsertUsersRow privado como está.
  // Adiciona este atalho público:
  Future<void> ensureUsersRow({
    required String id,
    required String email,
    String? name,
  }) {
    return _upsertUsersRow(id: id, email: email, name: name);
  }

  // ---------------------------------------------------------------------------
  // Helpers para a tabela `public.users`
  // ---------------------------------------------------------------------------

  /// Lê a row (ou null).
  Future<Map<String, dynamic>?> _getUsersRow(String uid) async {
    final row = await client
        .from('users')
        .select() // <- sem genéricos
        .eq('id', uid)
        .maybeSingle();

    // if null, devolve null; senão, garante Map<String,dynamic>
    return row == null ? null : Map<String, dynamic>.from(row as Map);
  }

  /// Upsert idempotente: cria/atualiza a row com {id, email}.
  /// Usa onConflict: 'id' para evitar race conditions.
  /// Implementa lógica de patch incremental similar ao finish_setup.dart
  Future<Map<String, dynamic>> _upsertUsersRow({
    required String id,
    required String email,
    String? name,
  }) async {
    // Debug

    final patch = <String, dynamic>{
      'id': id,
      'email': email.trim().toLowerCase(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };

    // Only add name if it's provided, not null and not empty
    if (name != null && name.trim().isNotEmpty) {
      patch['name'] = name.trim();
      // Debug
    } else {
      // Debug
    }

    // Debug

    try {
      final row = await client
          .from('users')
          .upsert(patch, onConflict: 'id')
          .select() // devolve a row atualizada/criada
          .single();

      final result = Map<String, dynamic>.from(row as Map);
      // Debug

      return result;
    } catch (e) {
      // Debug
      rethrow;
    }
  }
}
