/// Search result entity for home search
/// Contains results grouped by section
class SearchResult {
  final List<SearchItem> confirmedEvents;
  final List<SearchItem> pendingEvents;
  final List<SearchItem> livingEvents;
  final List<SearchItem> recapEvents;
  final List<SearchItem> memories;
  final List<SearchItem> payments;

  const SearchResult({
    this.confirmedEvents = const [],
    this.pendingEvents = const [],
    this.livingEvents = const [],
    this.recapEvents = const [],
    this.memories = const [],
    this.payments = const [],
  });

  bool get isEmpty =>
      confirmedEvents.isEmpty &&
      pendingEvents.isEmpty &&
      livingEvents.isEmpty &&
      recapEvents.isEmpty &&
      memories.isEmpty &&
      payments.isEmpty;

  int get totalResults =>
      confirmedEvents.length +
      pendingEvents.length +
      livingEvents.length +
      recapEvents.length +
      memories.length +
      payments.length;
}

/// Individual search item
class SearchItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? emoji;
  final DateTime? date;
  final String? location;
  final SearchItemType type;

  const SearchItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.emoji,
    this.date,
    this.location,
    required this.type,
  });
}

enum SearchItemType {
  confirmedEvent,
  pendingEvent,
  livingEvent,
  recapEvent,
  memory,
  payment,
}
