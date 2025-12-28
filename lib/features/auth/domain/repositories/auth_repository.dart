import '../entities/user.dart';

abstract class AuthRepository {
  Future<void> login({required String email});
  Future<void> register({required String email});
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<User?> verifyOtp(
      {required String email, required String otp, String? name});
  Future<void> ensureUsersRow(String id, String email, {String? name});
}
