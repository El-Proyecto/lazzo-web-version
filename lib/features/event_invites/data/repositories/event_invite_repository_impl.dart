import '../../domain/entities/event_invite_link_entity.dart';
import '../../domain/repositories/event_invite_repository.dart';
import '../data_sources/event_invite_remote_data_source.dart';

class EventInviteRepositoryImpl implements EventInviteRepository {
  final EventInviteRemoteDataSource _dataSource;

  EventInviteRepositoryImpl(this._dataSource);

  @override
  Future<EventInviteLinkEntity> createInviteLink({
    required String eventId,
    int expiresInHours = 48,
    String? shareChannel,
  }) async {
    try {
      final model = await _dataSource.createInviteLink(
        eventId: eventId,
        expiresInHours: expiresInHours,
        shareChannel: shareChannel,
      );
      return model.toEntity();
    } catch (e) {
      throw Exception('Failed to create event invite link: $e');
    }
  }
}
