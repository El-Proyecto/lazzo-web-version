import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/memory_summary_card.dart';
import '../widgets/pending_events_section.dart';
import '../../../../shared/components/sections/section_block.dart';
import '../../../../shared/components/cards/event_created_banner.dart';
import '../providers/memory_providers.dart';
import '../providers/pending_event_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _showBanner = false;
  String _eventName = '';
  String _groupName = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Check for success banner arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['showSuccessBanner'] == true) {
      setState(() {
        _showBanner = true;
        _eventName = args['eventName'] ?? '';
        _groupName = args['groupName'] ?? '';
      });
    }
  }

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
            if (_showBanner) ...[
              SizedBox(height: 16),
              EventCreatedBanner(
                eventName: _eventName,
                groupName: _groupName,
                onClose: () {
                  setState(() {
                    _showBanner = false;
                  });
                },
              ),
              SizedBox(height: 16),
            ],

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
