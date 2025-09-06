import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/memory_summary_card.dart';
import '../../../../shared/components/sections/section_block.dart';
import '../providers/memory_providers.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastMemoryAsync = ref.watch(lastMemoryControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
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
                    'Failed to load memory',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
            // TODO: Add more sections here (Next/Pending memories)
          ],
        ),
      ),
    );
  }
}
