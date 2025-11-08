import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Reusable top banner component that appears below the AppBar
/// with slide-down animation and can be dismissed by dragging up
class TopBanner {
  /// Shows a banner at the top of the screen with animation
  ///
  /// [context] - BuildContext for overlay access
  /// [message] - Text to display in the banner
  /// [duration] - How long to show the banner (default 3 seconds)
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _TopBannerWidget(
        message: message,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after duration
    Future.delayed(duration, () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

class _TopBannerWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _TopBannerWidget({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_TopBannerWidget> createState() => _TopBannerWidgetState();
}

class _TopBannerWidgetState extends State<_TopBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  double _dragDistance = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragDistance += details.delta.dy;
      // Limit drag to only upward direction
      if (_dragDistance > 0) {
        _dragDistance = 0;
      }
    });
  }

  void _onVerticalDragEnd(DragEndDetails details) {
    // If dragged up more than 50 pixels, dismiss
    if (_dragDistance < -50) {
      _controller.reverse().then((_) => widget.onDismiss());
    } else {
      // Reset position
      setState(() {
        _dragDistance = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onVerticalDragUpdate: _onVerticalDragUpdate,
          onVerticalDragEnd: _onVerticalDragEnd,
          child: Transform.translate(
            offset: Offset(0, _dragDistance),
            child: Container(
              margin: EdgeInsets.only(
                top: topPadding + kToolbarHeight,
                left: Insets.screenH,
                right: Insets.screenH,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: Pads.sectionH,
                vertical: Gaps.md,
              ),
              decoration: BoxDecoration(
                color: BrandColors.bg2.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(Radii.md),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DefaultTextStyle(
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                  decoration: TextDecoration.none,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
