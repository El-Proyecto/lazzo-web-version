// lib/features/auth/data/repositories/auth_repository_impl.dart
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource remoteDatasource;

  AuthRepositoryImpl(this.remoteDatasource);

  // ---- mapeamento data -> domínio ----
  User _toDomain(UserModel m) {
    return User(
      id: m.id,
      phoneNumber: m.phone ?? '',        // fallback se vier null da BD
      username: '',                      // a tua tabela não tem username
      dateOfBirth: m.birthDate,
      name: m.name,
    );
  }

  @override
  Future<void> login({required String phoneNumber}) {
    return remoteDatasource.login(phoneNumber);
  }

  @override
  Future<User> register({
    required String phone,
    required String password,
    required String username,
  }) async {
    final model = await remoteDatasource.register(phone, password, username);
    return _toDomain(model);
  }

  @override
  Future<User?> getCurrentUser() async {
    final model = await remoteDatasource.getCurrentUser();
    return model == null ? null : _toDomain(model);
  }

  @override
  Future<void> logout() {
    return remoteDatasource.logout();
  }

  @override
  Future<void> sendOtp(String phoneNumber) {
    return remoteDatasource.sendOtp(phoneNumber);
  }

  @override
  Future<User> verifyOtp(String phoneNumber, String token) async {
    final model = await remoteDatasource.verifyOtp(phoneNumber, token);
    return _toDomain(model);
  }
}
