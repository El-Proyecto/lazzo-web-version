import '../entities/user.dart';

abstract class AuthRepository {
  Future<void> login({required String phoneNumber});
  Future<User> register({required String phone, required String password, required String username});
  Future<User?> getCurrentUser();
  Future<void> logout();
  Future<void> sendOtp(String phoneNumber);
  Future<User> verifyOtp(String phoneNumber, String token);
}
