// login_user.dart
//import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<void> call(String phoneNumber) {
    return repository.login(phoneNumber: phoneNumber);
  }
}
