import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lazzo/features/event/presentation/providers/event_providers.dart';
import 'package:lazzo/features/memory/domain/entities/memory_entity.dart';
import 'package:lazzo/features/memory/presentation/pages/memory_page.dart';
import 'package:lazzo/features/memory/presentation/providers/memory_providers.dart';
import 'package:lazzo/shared/components/sections/cover_mosaic.dart';
import 'package:lazzo/shared/components/sections/hybrid_photo_grid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_network_images.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(url: 'https://example.com', anonKey: 'anon-key');
    } catch (_) {}
  });

  MemoryEntity makeMemory({required List<MemoryPhoto> photos}) {
    return MemoryEntity(
      id: 'mem-1',
      eventId: 'evt-1',
      title: 'Mega Party',
      emoji: '🍖',
      location: 'Lisboa',
      eventDate: DateTime(2026, 4, 27),
      photos: photos,
      status: EventStatus.ended,
      createdBy: 'host-1',
    );
  }

  MemoryPhoto makePhoto({
    required String id,
    required bool isCover,
    required DateTime capturedAt,
  }) {
    return MemoryPhoto(
      id: id,
      url: 'https://example.com/$id.jpg',
      thumbnailUrl: 'https://example.com/$id-thumb.jpg',
      coverUrl: 'https://example.com/$id-cover.jpg',
      voteCount: 1,
      capturedAt: capturedAt,
      aspectRatio: 1.2,
      uploaderId: 'uploader-1',
      uploaderName: 'User',
      isCover: isCover,
    );
  }

  Future<void> pumpPage(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: const MaterialApp(
          home: MemoryPage(memoryId: 'evt-1'),
        ),
      ),
    );
  }

  group('MemoryPage', () {
    testWidgets('shows event title and emoji', (tester) async {
      await pumpPage(
        tester,
        overrides: [
          currentUserIdProvider.overrideWithValue('uploader-1'),
          memoryDetailProvider.overrideWith(
            (ref, memoryId) async => makeMemory(photos: const []),
          ),
          eventRsvpsProvider.overrideWith((ref, eventId) async => []),
          guestRsvpListProvider.overrideWith((ref, eventId) async => []),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('🍖 Mega Party'), findsOneWidget);
    });

    testWidgets('shows cover photos', (tester) async {
      await pumpPage(
        tester,
        overrides: [
          currentUserIdProvider.overrideWithValue('uploader-1'),
          memoryDetailProvider.overrideWith(
            (ref, memoryId) async => makeMemory(
              photos: [
                makePhoto(id: 'cover-1', isCover: true, capturedAt: DateTime(2026, 4, 27, 10)),
                makePhoto(id: 'cover-2', isCover: true, capturedAt: DateTime(2026, 4, 27, 11)),
              ],
            ),
          ),
          eventRsvpsProvider.overrideWith((ref, eventId) async => []),
          guestRsvpListProvider.overrideWith((ref, eventId) async => []),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(CoverMosaic), findsOneWidget);
    });

    testWidgets('shows empty state when no photos', (tester) async {
      await pumpPage(
        tester,
        overrides: [
          currentUserIdProvider.overrideWithValue('uploader-1'),
          memoryDetailProvider.overrideWith(
            (ref, memoryId) async => makeMemory(photos: const []),
          ),
          eventRsvpsProvider.overrideWith((ref, eventId) async => []),
          guestRsvpListProvider.overrideWith((ref, eventId) async => []),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.text('No photos yet'), findsOneWidget);
    });

    testWidgets('shows HybridPhotoGrid when there are non-cover photos', (tester) async {
      bindMockNetworkImages();
      try {
        await pumpPage(
          tester,
          overrides: [
            currentUserIdProvider.overrideWithValue('uploader-1'),
            memoryDetailProvider.overrideWith(
              (ref, memoryId) async => makeMemory(
                photos: [
                  makePhoto(
                    id: 'grid-1',
                    isCover: false,
                    capturedAt: DateTime(2026, 4, 27, 10),
                  ),
                  makePhoto(
                    id: 'grid-2',
                    isCover: false,
                    capturedAt: DateTime(2026, 4, 27, 11),
                  ),
                ],
              ),
            ),
            eventRsvpsProvider.overrideWith((ref, eventId) async => []),
            guestRsvpListProvider.overrideWith((ref, eventId) async => []),
          ],
        );
        // Avoid pumpAndSettle: MemoryPage invalidates after first frame (skeleton
        // shimmer repeats) and Image.network loadingBuilders use spinners until
        // decode — not guaranteed idle. We only assert the grid is built.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(HybridPhotoGrid), findsOneWidget);
      } finally {
        unbindMockNetworkImages();
      }
    });
  });
}
