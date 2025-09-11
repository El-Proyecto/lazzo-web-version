import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/themes/colors.dart';

class CreateEventPage extends ConsumerWidget {
  const CreateEventPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      body: const SizedBox.shrink(),
    );
  }
}
