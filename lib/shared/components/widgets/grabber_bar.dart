import 'package:flutter/material.dart';
import '../../themes/colors.dart';

/// Grabber bar para bottom sheets
/// Componente visual para indicar que o bottom sheet pode ser arrastado
class GrabberBar extends StatelessWidget {
  const GrabberBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 4,
      margin: EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: BrandColors.border,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
