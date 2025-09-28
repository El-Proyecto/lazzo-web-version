import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../themes/colors.dart';

/// Generic card foundation that can be used as base for feature-specific cards
/// Provides consistent styling, padding, and interaction patterns
class BaseCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final List<BoxShadow>? boxShadow;
  final bool isPressed;

  const BaseCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius = Radii.md,
    this.boxShadow,
    this.isPressed = false,
  });

  /// Factory for standard app card with default spacing
  factory BaseCard.standard({
    required Widget child,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return BaseCard(
      padding: const EdgeInsets.all(Gaps.md),
      backgroundColor: backgroundColor ?? BrandColors.bg2,
      borderRadius: Radii.md,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory for compact card with minimal padding
  factory BaseCard.compact({
    required Widget child,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return BaseCard(
      padding: const EdgeInsets.all(Gaps.sm),
      backgroundColor: backgroundColor ?? BrandColors.bg2,
      borderRadius: Radii.sm,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory for outlined card with border
  factory BaseCard.outlined({
    required Widget child,
    VoidCallback? onTap,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return BaseCard(
      padding: const EdgeInsets.all(Gaps.md),
      backgroundColor: backgroundColor ?? Colors.transparent,
      borderColor: borderColor ?? BrandColors.border,
      borderWidth: 1,
      borderRadius: Radii.md,
      onTap: onTap,
      child: child,
    );
  }

  /// Factory for elevated card with shadow
  factory BaseCard.elevated({
    required Widget child,
    VoidCallback? onTap,
    Color? backgroundColor,
  }) {
    return BaseCard(
      padding: const EdgeInsets.all(Gaps.md),
      backgroundColor: backgroundColor ?? BrandColors.bg2,
      borderRadius: Radii.md,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      onTap: onTap,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      padding: padding,
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? BrandColors.bg2,
        borderRadius: BorderRadius.circular(borderRadius),
        border: borderWidth > 0
            ? Border.all(
                color: borderColor ?? BrandColors.border,
                width: borderWidth,
              )
            : null,
        boxShadow: boxShadow,
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: AnimatedScale(
          scale: isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}
