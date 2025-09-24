// lib/features/profile/data/repositories/users_repository.dart
import '../datasources/users_remote_datasource.dart';

class UsersRepository {
  final UsersRemoteDatasource remote;
  UsersRepository(this.remote);

  Future<void> upsertPatch(Map<String, dynamic> patch) =>
      remote.upsertPatch(patch);
  Future<Map<String, dynamic>?> load() => remote.fetch();
}
