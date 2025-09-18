import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/sections/section_block.dart';
import '../../../../shared/components/cards/event_created_banner.dart';
import '../widgets/memory_summary_card.dart';
import '../widgets/pending_events_section.dart';
import '../providers/memory_providers.dart';
import '../providers/banner_provider.dart';
import '../providers/pending_event_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final lastMemoryAsync = ref.watch(lastMemoryControllerProvider);

    // Reset stacked state when entering the home page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(stackedEventsStateProvider.notifier).resetToStacked();
    });

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Success banner if needed
            Consumer(
              builder: (context, ref, child) {
                final bannerState = ref.watch(bannerProvider);
                if (!bannerState.isVisible) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
                    const SizedBox(height: 16),
                    EventCreatedBanner(
                      eventName: bannerState.eventName,
                      groupName: bannerState.groupName,
                      onClose: () {
                        ref.read(bannerProvider.notifier).hideBanner();
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),

            // Pending Events Section
            const PendingEventsSection(),

            // Recent Memory Section
            lastMemoryAsync.when(
              data: (memory) {
                if (memory == null) {
                  print('memory is null');
                  return const SizedBox.shrink();
                }
                return SectionBlock(
                  title: 'Recent Memory',
                  child: MemorySummaryCard(
                    emoji: memory.emoji,
                    title: memory.title,
                    onTap: () {
                      // TODO: Navigate to memory details
                    },
                  ),
                );
              },
              loading: () => const SectionBlock(
                title: 'Recent Memory',
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    height: 94,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
              error: (error, stackTrace) => SectionBlock(
                title: 'Recent Memory',
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Failed to load memory: $error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
            // More sections can be added here
          ],
        ),
      ),
    );
  }
}
