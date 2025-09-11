// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient client;
  AuthRemoteDatasource(this.client);

  // 1) Login com email e OTP
  Future<void> login(String email) async {
    try {
      print('[AUTH_DATASOURCE] Iniciando login com OTP para: $email');
      await client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: 'lazzo://auth-callback-dev',
        data: {'type': 'login'},  // Metadata para identificar o tipo de operação
      );
      print('[AUTH_DATASOURCE] OTP enviado com sucesso para login');
    } catch (e) {
      print('[AUTH_DATASOURCE] Erro ao enviar OTP para login: $e');
      print('[AUTH_DATASOURCE] Client status: ${client.auth.currentSession}');
      rethrow;
    }
  }


  // 2) Sign up + garante row em `users`
  Future<void> register(String email) async {
    print('[AUTH_DATASOURCE] Iniciando signInWithOtp para: $email');
    try {
      await client.auth.signInWithOtp(
        email: email.trim().toLowerCase(),
        shouldCreateUser: true,
        data: {
          'type': 'signup',
          'app': 'lazzo',
        },
      );
      print('[AUTH_DATASOURCE] OTP enviado com sucesso');
    } catch (e) {
      print('[AUTH_DATASOURCE] Erro ao enviar OTP: $e');
      print('[AUTH_DATASOURCE] Client status: ${client.auth.currentSession}');
      throw Exception('Falha ao enviar código de verificação: ${e.toString()}');
    }
  }


  // 3) Utilizador autenticado atual → lê row de `users` (se não existir, cria mínima)
  Future<UserModel?> getCurrentUser() async {
    final u = client.auth.currentUser;
    if (u == null) return null;

    final row = await _getUsersRow(u.id) ?? await _upsertUsersRow(
      id: u.id,
      email: u.email ?? '',
    );
    return UserModel.fromUsersRow(row);
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
  Future<UserModel> verifyOtp({
    required String email,
    required String token,
  }) async {
    try {
      print('[AUTH_DATASOURCE] Iniciando verificação OTP...');
      print('[AUTH_DATASOURCE] Email: $email');
      print('[AUTH_DATASOURCE] Code length: ${token.length}');
      
      // 1) Verificar estado atual
      final currentUser = client.auth.currentUser;
      print('[AUTH_DATASOURCE] Estado atual - User: ${currentUser?.id ?? 'null'}');
      print('[AUTH_DATASOURCE] Estado atual - Session existe: ${client.auth.currentSession != null}');
      
      // 2) Verificar OTP
      print('[AUTH_DATASOURCE] Chamando verifyOTP...');
      final AuthResponse response = await client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.email,  // Mudado para signup pois é um novo registro
      );
      
      print('[AUTH_DATASOURCE] Resposta recebida do verifyOTP');
      print('[AUTH_DATASOURCE] User ID: ${response.user?.id ?? 'null'}');
      print('[AUTH_DATASOURCE] Session existe: ${response.session != null}');

      // 3) Verificar se temos usuário e sessão
      final u = response.user;
      if (u == null || response.session == null) {
        print('[AUTH_DATASOURCE] Erro: Usuário ou sessão nulos após verificação');
        throw Exception('Falha na autenticação: usuário ou sessão inválidos');
      }
      
      print('[AUTH_DATASOURCE] Criando/atualizando registro do usuário...');
      final row = await _upsertUsersRow(
        id: u.id,
        email: email,
      );

      print('[AUTH_DATASOURCE] Verificação concluída com sucesso');
      return UserModel.fromUsersRow(row);
      
    } on AuthException catch (e) {
      print('[AUTH_DATASOURCE] Erro de autenticação: ${e.message}');
      throw Exception('Falha na verificação OTP: ${e.message}');
    } on PostgrestException catch (e) {
      print('[AUTH_DATASOURCE] Erro de banco de dados: ${e.message}');
      throw Exception('Falha na verificação OTP (DB): ${e.message}');
    } catch (e) {
      print('[AUTH_DATASOURCE] Erro inesperado: $e');
      throw Exception('Falha na verificação OTP: $e');
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

  /// Upsert idempotente: cria/atualiza a row com {id, email}.
  /// Usa onConflict: 'id' para evitar race conditions.
  Future<Map<String, dynamic>> _upsertUsersRow({
    required String id,
    required String email,
  }) async {
    final patch = <String, dynamic>{
      'id': id,
      'email': email,
    };

    final row = await client
        .from('users')
        .upsert(patch, onConflict: 'id')
        .select()          // <- sem genéricos
        .single();

    return Map<String, dynamic>.from(row as Map);
  }
}
