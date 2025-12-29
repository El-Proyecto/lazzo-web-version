import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/usecases/accept_group_invite_by_token.dart';
import '../../data/data_sources/group_invite_remote_data_source.dart';
import '../../data/repositories/group_invite_repository_impl.dart';

final acceptGroupInviteProvider = Provider<AcceptGroupInviteByToken>((ref) {
  final client = Supabase.instance.client;
  final dataSource = GroupInviteRemoteDataSource(client);
  final repository = GroupInviteRepositoryImpl(dataSource);
  return AcceptGroupInviteByToken(repository);
});
