// lib/features/auth/data/datasources/auth_remote_datasource.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final SupabaseClient client;
  AuthRemoteDatasource(this.client);

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      print('[AUTH_DATASOURCE] Starting Google Sign In');
      final response = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'lazzo://auth-callback-dev',
        scopes: 'email profile',
      );
      print('[AUTH_DATASOURCE] Google Sign In response: $response');
      return response;
    } catch (e) {
      print('[AUTH_DATASOURCE] Error with Google Sign In: $e');
      rethrow;
    }
  }

  // 1) Login com email e OTP
  Future<void> login(String email) async {
    try {
      print('[AUTH_DATASOURCE] Iniciando login com OTP para: $email');
      final trimmedEmail = email.trim().toLowerCase();
      
      // Verifica se o usuário existe antes de enviar OTP
      final existingUser = await client
          .from('users')
          .select('id')
          .eq('email', trimmedEmail)
          .maybeSingle();
      
      if (existingUser == null) {
        throw Exception('Usuário não encontrado. Por favor, registre-se primeiro.');
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
      print('[AUTH_DATASOURCE] OTP enviado com sucesso para login');
    } catch (e) {
      print('[AUTH_DATASOURCE] Erro ao enviar OTP para login: $e');
      rethrow;
    }
  }


  // 2) Sign up + garante row em `users`
  Future<void> register(String email) async {
    try {
      print('[AUTH_DATASOURCE] Iniciando registro com OTP para: $email');
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
      print('[AUTH_DATASOURCE] OTP enviado com sucesso para registro');
    } catch (e) {
      print('[AUTH_DATASOURCE] Erro ao enviar OTP para registro: $e');
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
      
      // 1) Verificar estado atual
      //final currentUser = client.auth.currentUser;
      
      // 2) Verificar OTP
      final AuthResponse response = await client.auth.verifyOTP(
        email: email.trim().toLowerCase(),
        token: token.trim(),
        type: OtpType.email,  // Mudado para signup pois é um novo registro
      );
      

      // 3) Verificar se temos usuário e sessão
      final u = response.user;
      if (u == null || response.session == null) {
        throw Exception('Falha na autenticação: usuário ou sessão inválidos');
      }
      
      final row = await _upsertUsersRow(
        id: u.id,
        email: email,
      );

      return UserModel.fromUsersRow(row);
      
    } on AuthException catch (e) {
      throw Exception('Falha na verificação OTP: ${e.message}');
    } on PostgrestException catch (e) {
      throw Exception('Falha na verificação OTP (DB): ${e.message}');
    } catch (e) {
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
