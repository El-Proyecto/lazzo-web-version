import 'package:flutter_riverpod/flutter_riverpod.dart'; // Para StateNotifierProvider, StateNotifier, AsyncValue
import 'package:supabase_flutter/supabase_flutter.dart'; // Para Supabase.instance.client
import '../../data/repositories/auth_repository_impl.dart'; // Caminho para o teu AuthRepositoryImpl
import '../../data/datasources/auth_remote_datasource.dart'; // Caminho para o teu AuthRemoteDatasource
import '../../domain/repositories/auth_repository.dart'; // Caminho para o contrato AuthRepository
import '../../domain/entities/user.dart'
    as domain; // Caminho para a entidade User

final authProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<domain.User?>>((ref) {
  final repo = AuthRepositoryImpl(
    AuthRemoteDatasource(Supabase.instance.client),
  );
  return AuthNotifier(repo);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  throw UnimplementedError('Provide AuthRepository in main.dart override');
});

class AuthNotifier extends StateNotifier<AsyncValue<domain.User?>> {
  final AuthRepository repository;

  AuthNotifier(this.repository) : super(const AsyncLoading()) {
    _initializeAuth();
  }

  /// Inicializa o estado de autenticação verificando se há um usuário logado
  Future<void> _initializeAuth() async {
    try {
      final user = await repository.getCurrentUser();
      state = AsyncData(user);
    } catch (e) {
      // Se houver erro ao verificar usuário, assume que não está logado
      state = const AsyncData(null);
    }
  }

  Future<bool> login(String email) async {
    try {
      await repository.login(email: email.trim().toLowerCase());
      // <- guarda o resultado no state
      return true; // <- todas as paths retornam
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow; // <- evita “body might complete normally”
    }
  }

  Future<void> register(String email) async {
    state = const AsyncLoading();
    try {
      await repository.register(email: email);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> getCurrentUser() async {
    try {
      final user = await repository.getCurrentUser();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    try {
      await repository.logout();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> ensureUsersRow(String id, String email, {String? name}) async {
    try {
      await repository.ensureUsersRow(id, email, name: name);
      // Após garantir a row do usuário, atualiza o estado
      await getCurrentUser();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
