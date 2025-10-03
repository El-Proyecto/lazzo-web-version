import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

/// Grabber bar para bottom sheets
/// Componente visual para indicar que o bottom sheet pode ser arrastado
class GrabberBar extends StatelessWidget {
  const GrabberBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: Gaps.xl,
      height: Gaps.xxs,
      margin: const EdgeInsets.only(top: Gaps.sm, bottom: Gaps.xxs),
      decoration: BoxDecoration(
        color: BrandColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
