import '../widgets/date_time_suggestions_widget.dart' show DateTimeSuggestion;
import '../../domain/entities/suggestion.dart';

/// Data class for processed date/time suggestions with votes
class DateTimeSuggestionsData {
  final List<DateTimeSuggestion> suggestions;
  final bool hasAlternatives;
  final DateTimeSuggestion? currentEventOption;

  const DateTimeSuggestionsData({
    required this.suggestions,
    required this.hasAlternatives,
    this.currentEventOption,
  });

  /// Empty state
  static const empty = DateTimeSuggestionsData(
    suggestions: [],
    hasAlternatives: false,
    currentEventOption: null,
  );
}

/// Data class for processed location suggestions with votes
class LocationSuggestionsData {
  final List<LocationSuggestion> suggestions;
  final List<SuggestionVote> allVotes;
  final bool hasAlternatives;
  final int currentEventGoingCount;

  const LocationSuggestionsData({
    required this.suggestions,
    required this.allVotes,
    required this.hasAlternatives,
    required this.currentEventGoingCount,
  });

  /// Empty state
  static const empty = LocationSuggestionsData(
    suggestions: [],
    allVotes: [],
    hasAlternatives: false,
    currentEventGoingCount: 0,
  );
}


