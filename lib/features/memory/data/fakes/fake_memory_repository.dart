import '../../domain/entities/memory_entity.dart';
import '../../domain/repositories/memory_repository.dart';

enum FakeMemoryScenario {
  mixedDefault,
  singlePortrait,
  portraitLandscape,
  landscapePortrait,
  doublePortrait,
  doubleLandscape,
  portraitLandscapeLandscape,
  landscapePortraitLandscape,
  landscapeLandscapePortrait,
  portraitPortraitLandscape,
  allPortrait,
  allLandscape,
}

class FakeMemoryRepository implements MemoryRepository {
  static FakeMemoryScenario _activeScenario = FakeMemoryScenario.mixedDefault;

  static void setScenario(FakeMemoryScenario scenario) {
    _activeScenario = scenario;
  }

  static final Map<FakeMemoryScenario, Map<String, MemoryEntity>>
      _scenarioMemories = {
    FakeMemoryScenario.mixedDefault: {
      'memory-1': _buildBeachDayMemory(),
    },
    FakeMemoryScenario.singlePortrait: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Single Portrait',
        seed: 'single_portrait',
        coverOrientations: const [true],
        multiDay: false,
      ),
    },
    FakeMemoryScenario.portraitLandscape: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Portrait + Landscape',
        seed: 'portrait_landscape',
        coverOrientations: const [true, false],
        multiDay: false,
      ),
    },
    FakeMemoryScenario.landscapePortrait: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Landscape + Portrait',
        seed: 'landscape_portrait',
        coverOrientations: const [false, true],
        multiDay: false,
      ),
    },
    FakeMemoryScenario.doublePortrait: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Portrait + Portrait',
        seed: 'double_portrait',
        coverOrientations: const [true, true],
        multiDay: false,
      ),
    },
    FakeMemoryScenario.doubleLandscape: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Landscape + Landscape',
        seed: 'double_landscape',
        coverOrientations: const [false, false],
        multiDay: false,
      ),
    },
    FakeMemoryScenario.portraitLandscapeLandscape: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Portrait + Landscape + Landscape',
        seed: 'portrait_landscape_landscape',
        coverOrientations: const [true, false, false],
        multiDay: true,
      ),
    },
    FakeMemoryScenario.landscapePortraitLandscape: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Landscape + Portrait + Landscape',
        seed: 'landscape_portrait_landscape',
        coverOrientations: const [false, true, false],
        multiDay: true,
      ),
    },
    FakeMemoryScenario.landscapeLandscapePortrait: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Landscape + Landscape + Portrait',
        seed: 'landscape_landscape_portrait',
        coverOrientations: const [false, false, true],
        multiDay: true,
      ),
    },
    FakeMemoryScenario.portraitPortraitLandscape: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Portrait + Portrait + Landscape',
        seed: 'portrait_portrait_landscape',
        coverOrientations: const [true, true, false],
        multiDay: true,
      ),
    },
    FakeMemoryScenario.allPortrait: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Portrait + Portrait + Portrait',
        seed: 'all_portrait',
        coverOrientations: const [true, true, true],
        multiDay: true,
      ),
    },
    FakeMemoryScenario.allLandscape: {
      'memory-1': _scenarioMemory(
        id: 'memory-1',
        eventId: 'event-1',
        title: 'Cover: Landscape + Landscape + Landscape',
        seed: 'all_landscape',
        coverOrientations: const [false, false, false],
        multiDay: true,
      ),
    },
  };

  Map<String, MemoryEntity> get _memories =>
      _scenarioMemories[_activeScenario]!;

  @override
  Future<MemoryEntity?> getMemoryById(String memoryId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _memories[memoryId];
  }

  @override
  Future<MemoryEntity?> getMemoryByEventId(String eventId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _memories.values.firstWhere(
      (memory) => memory.eventId == eventId,
      orElse: () => _memories.values.first,
    );
  }

  @override
  Future<String> shareMemory(String memoryId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return 'https://lazzo.app/memory/$memoryId';
  }
}

final DateTime _baseDate = DateTime(2024, 7, 5);

MemoryEntity _buildBeachDayMemory() {
  final day1 = _baseDate;
  final day2 = day1.add(const Duration(days: 1));

  return MemoryEntity(
    id: 'memory-1',
    eventId: 'event-1',
    title: 'Beach Day',
    location: 'Marrakech, Morocco',
    eventDate: day1,
    photos: [
      _portraitPhoto(
        'bd_cover_1',
        15,
        day1.add(const Duration(hours: 14, minutes: 30)),
      ),
      _portraitPhoto(
        'bd_cover_2',
        8,
        day1.add(const Duration(hours: 15)),
      ),
      _landscapePhoto(
        'bd_cover_3',
        12,
        day1.add(const Duration(hours: 16)),
      ),
      _landscapePhoto(
        'bd_cover_4',
        10,
        day1.add(const Duration(hours: 16, minutes: 30)),
      ),
      _portraitPhoto(
        'bd_grid_1',
        5,
        day1.add(const Duration(hours: 17)),
      ),
      _landscapePhoto(
        'bd_grid_2',
        7,
        day1.add(const Duration(hours: 17, minutes: 30)),
      ),
      _portraitPhoto(
        'bd_grid_3',
        6,
        day1.add(const Duration(hours: 18)),
      ),
      _landscapePhoto(
        'bd_grid_4',
        4,
        day1.add(const Duration(hours: 18, minutes: 30)),
      ),
      _portraitPhoto(
        'bd_grid_5',
        3,
        day2.add(const Duration(hours: 10)),
      ),
      _landscapePhoto(
        'bd_grid_6',
        2,
        day2.add(const Duration(hours: 10, minutes: 30)),
      ),
      _portraitPhoto(
        'bd_grid_7',
        4,
        day2.add(const Duration(hours: 11)),
      ),
      _landscapePhoto(
        'bd_grid_8',
        3,
        day2.add(const Duration(hours: 11, minutes: 30)),
      ),
      _portraitPhoto(
        'bd_grid_9',
        2,
        day2.add(const Duration(hours: 14)),
      ),
    ],
  );
}

MemoryEntity _scenarioMemory({
  required String id,
  required String eventId,
  required String title,
  required String seed,
  required List<bool> coverOrientations,
  required bool multiDay,
}) {
  final coverVotes = [90, 80, 70];
  final coverPhotos = <MemoryPhoto>[];

  for (var i = 0; i < coverOrientations.length; i++) {
    final capturedAt = _baseDate.add(Duration(hours: i + 1));
    final vote = coverVotes[i];
    final photoId = '${seed}_cover_${i + 1}';
    coverPhotos.add(
      coverOrientations[i]
          ? _portraitPhoto(photoId, vote, capturedAt)
          : _landscapePhoto(photoId, vote, capturedAt),
    );
  }

  final photos = <MemoryPhoto>[
    ...coverPhotos,
    ..._scenarioExtras(seed: seed, multiDay: multiDay),
  ];

  return MemoryEntity(
    id: id,
    eventId: eventId,
    title: title,
    location: 'Test Location',
    eventDate: _baseDate,
    photos: photos,
  );
}

List<MemoryPhoto> _scenarioExtras({
  required String seed,
  required bool multiDay,
}) {
  final day2 = _baseDate.add(const Duration(days: 1));
  final day3 = _baseDate.add(const Duration(days: 2));

  DateTime dayOr(DateTime fallback, bool include) =>
      include ? fallback : _baseDate;

  return [
    _portraitPhoto(
      '${seed}_extra_1',
      20,
      _baseDate.add(const Duration(hours: 6)),
    ),
    _landscapePhoto(
      '${seed}_extra_2',
      18,
      _baseDate.add(const Duration(hours: 6, minutes: 45)),
    ),
    _portraitPhoto(
      '${seed}_extra_3',
      16,
      dayOr(day2, multiDay).add(const Duration(hours: 8)),
    ),
    _landscapePhoto(
      '${seed}_extra_4',
      14,
      dayOr(day2, multiDay).add(const Duration(hours: 9, minutes: 30)),
    ),
    _portraitPhoto(
      '${seed}_extra_5',
      12,
      dayOr(day3, multiDay).add(const Duration(hours: 10)),
    ),
    _landscapePhoto(
      '${seed}_extra_6',
      10,
      dayOr(day3, multiDay).add(const Duration(hours: 12)),
    ),
  ];
}

MemoryPhoto _portraitPhoto(
  String id,
  int vote,
  DateTime capturedAt,
) {
  return MemoryPhoto(
    id: id,
    url: 'https://picsum.photos/seed/$id/800/1000',
    thumbnailUrl: 'https://picsum.photos/seed/${id}_thumb/400/500',
    coverUrl: 'https://picsum.photos/seed/${id}_cover/1024/1280',
    voteCount: vote,
    capturedAt: capturedAt,
    aspectRatio: 0.8,
    uploaderId: 'user-$id',
    uploaderName: 'User $id',
  );
}

MemoryPhoto _landscapePhoto(
  String id,
  int vote,
  DateTime capturedAt,
) {
  return MemoryPhoto(
    id: id,
    url: 'https://picsum.photos/seed/$id/1600/900',
    thumbnailUrl: 'https://picsum.photos/seed/${id}_thumb/800/450',
    coverUrl: 'https://picsum.photos/seed/${id}_cover/1600/900',
    voteCount: vote,
    capturedAt: capturedAt,
    aspectRatio: 16 / 9,
    uploaderId: 'user-$id',
    uploaderName: 'User $id',
  );
}
