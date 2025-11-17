import '../../domain/entities/poll.dart';
import '../../domain/repositories/poll_repository.dart';
import '../data_sources/poll_remote_data_source.dart';

/// Implementation of PollRepository using Supabase
class PollRepositoryImpl implements PollRepository {
  final PollRemoteDataSource _remoteDataSource;

  PollRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Poll>> getEventPolls(String eventId) async {
    final models = await _remoteDataSource.getEventPolls(eventId);
    return models.map((model) => model.toEntity()).toList();
  }

  @override
  Future<Poll> createPoll({
    required String eventId,
    required PollType type,
    required String question,
    required List<String> options,
  }) async {
    // Convert enum to string
    String typeString;
    switch (type) {
      case PollType.date:
        typeString = 'date';
        break;
      case PollType.location:
        typeString = 'location';
        break;
      case PollType.custom:
        typeString = 'custom';
        break;
    }

    // Get current user ID (assuming auth is available)
    // For now, we'll need to pass it as parameter - fix this in use case
    final model = await _remoteDataSource.createPoll(
      eventId: eventId,
      type: typeString,
      question: question,
      options: options,
      createdBy: 'TODO', // TODO: Get from auth context in use case
    );
    return model.toEntity();
  }

  @override
  Future<void> voteOnPoll(String pollId, String optionId, String userId) async {
    await _remoteDataSource.voteOnPoll(pollId, optionId, userId);
  }

  @override
  Future<void> pickFinalOption(String pollId, String optionId) async {
    await _remoteDataSource.pickFinalOption(pollId, optionId);
  }
}
