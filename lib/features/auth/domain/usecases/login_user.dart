// login_user.dart
//import '../entities/user.dart';
import '../repositories/auth_repository.dart';

class LoginUser {
  final AuthRepository repository;

  LoginUser(this.repository);

  Future<void> call(String email, String password) {
    return repository.login(email: email);
  }
}
