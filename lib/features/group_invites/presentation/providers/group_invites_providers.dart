import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/usecases/create_group_invite_link.dart';
import '../../data/data_sources/group_invite_remote_data_source.dart';
import '../../data/repositories/group_invite_repository_impl.dart';

final createGroupInviteLinkProvider = Provider<CreateGroupInviteLink>((ref) {
  final client = Supabase.instance.client;
  final dataSource = GroupInviteRemoteDataSource(client);
  final repository = GroupInviteRepositoryImpl(dataSource);
  return CreateGroupInviteLink(repository);
});
