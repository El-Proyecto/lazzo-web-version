import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/usecases/create_event_invite_link.dart';
import '../../data/data_sources/event_invite_remote_data_source.dart';
import '../../data/repositories/event_invite_repository_impl.dart';

final createEventInviteLinkProvider = Provider<CreateEventInviteLink>((ref) {
  final client = Supabase.instance.client;
  final dataSource = EventInviteRemoteDataSource(client);
  final repository = EventInviteRepositoryImpl(dataSource);
  return CreateEventInviteLink(repository);
});
