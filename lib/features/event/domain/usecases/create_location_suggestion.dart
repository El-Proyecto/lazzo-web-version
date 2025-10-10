import '../entities/suggestion.dart';
import '../repositories/suggestion_repository.dart';

/// Use case to create a new location suggestion
class CreateLocationSuggestion {
  final SuggestionRepository repository;

  const CreateLocationSuggestion(this.repository);

  Future<LocationSuggestion> call({
    required String eventId,
    required String userId,
    required String locationName,
    String? address,
    double? latitude,
    double? longitude,
  }) async {
    return await repository.createLocationSuggestion(
      eventId: eventId,
      userId: userId,
      locationName: locationName,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
