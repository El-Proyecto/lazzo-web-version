import 'package:flutter/material.dart';

/// Badge widget that displays a notification counter indicator.
/// Shows a small dot when there are unread notifications.
/// Used in navigation bars to indicate pending notifications.
class NotificationBadge extends StatelessWidget {
  final Color color;
  final double size;
  final double? positionTop;
  final double? positionRight;

  const NotificationBadge({
    super.key,
    required this.color,
    this.size = 8,
    this.positionTop,
    this.positionRight,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: positionTop ?? 8,
      right: positionRight ?? 8,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
