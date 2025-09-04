import 'package:flutter/material.dart';
import '../../constants/text_styles.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader(this.title, {super.key});
  @override Widget build(BuildContext c) =>
    Text(title, style: AppText.titleMediumEmph.copyWith(color: Theme.of(c).colorScheme.onSurface));
}
