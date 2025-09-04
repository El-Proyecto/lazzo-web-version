import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/cards/memory_ready_card.dart';
import '../../../../shared/components/sections/section_block.dart';
import '../providers/home_data_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext c, WidgetRef ref) {
    final last = ref.watch(lastMemoryProvider);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (last != null)
          SectionBlock(
            title: 'Last Memory',
            child: MemoryReadyCard(
              emoji: last.emoji,
              title: last.title,
              onTap: () {/* navegar para memória */},
            ),
          ),
        // ...outras sections
      ],
    );
  }
}
