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
      email: m.email,                     // a tua tabela não tem username
      dateOfBirth: m.birthDate,
      name: m.name,
    );
  }

  @override
  Future<void> login({required String email}) async {
    await remoteDatasource.login(email);
  }

  @override
  Future<void> register({
    required String email
    }) async {
    try {
      await remoteDatasource.register(email);
    } catch (e) {
      rethrow;
    }
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
  Future<bool> signInWithGoogle() async {
    return await remoteDatasource.signInWithGoogle();
  }

  @override
  Future<User?> verifyOtp({required String email, required String otp}) async {
    try {
      final userModel = await remoteDatasource.verifyOtp(
        email: email,
        token: otp,
      );
      return _toDomain(userModel);
    } catch (e) {
      
      rethrow;
    }
  }

  @override
  Future<void> ensureUsersRow(String id, String email, {String? name}) {
    return remoteDatasource.ensureUsersRow(id: id, email: email, name: name);
  }

}
