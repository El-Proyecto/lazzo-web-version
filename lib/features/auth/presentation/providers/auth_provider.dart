//import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Para Supabase.instance.client
import '../../data/repositories/auth_repository_impl.dart'; // Caminho para o teu AuthRepositoryImpl
import '../../data/datasources/auth_remote_datasource.dart'; // Caminho para o teu AuthRemoteDatasource
import '../../domain/repositories/auth_repository.dart'; // Caminho para o contrato AuthRepository
import '../../domain/entities/user.dart' as domain;  // Caminho para a entidade User

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<domain.User?>>((ref) {
  final repo = AuthRepositoryImpl(AuthRemoteDatasource(Supabase.instance.client));
  return AuthNotifier(repo);
});

class AuthNotifier extends StateNotifier<AsyncValue<domain.User?>> {
  final AuthRepository repository;

  AuthNotifier(this.repository) : super(const AsyncLoading()) {
    getCurrentUser();
  }

  Future<void> login(String phoneNumber) async {
    state = const AsyncLoading();
    print("Login attempt with phone number: $phoneNumber");
    try {
      await repository.login(phoneNumber: phoneNumber);
      // O OTP foi enviado, agora navega para o ecrã de verificação de código
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> getCurrentUser() async {
    final user = await repository.getCurrentUser();
    state = AsyncData(user);
  }

  Future<void> logout() async {
    await repository.logout();
    state = const AsyncData(null);
  }

  Future<void> sendOtp(String phoneNumber) async {
    try {
      await repository.sendOtp(phoneNumber);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> verifyOtp(String phoneNumber, String token) async {
    state = const AsyncLoading();
    try {
      final user = await repository.verifyOtp(phoneNumber, token);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
