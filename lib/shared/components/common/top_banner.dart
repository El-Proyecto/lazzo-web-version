import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Reusable top banner component that appears below the AppBar
/// with slide-down animation and can be dismissed by dragging up
class TopBanner {
  // Global reference to current banner to ensure only one is visible
  static OverlayEntry? _currentBanner;

  /// Banner type enum
  static const String typeSuccess = 'success';
  static const String typeError = 'error';
  static const String typeWarning = 'warning';
  static const String typeInfo = 'info';
  static const String typeNeutral = 'neutral';

  /// Shows a neutral banner (no icon, bg2 background)
  static void show(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showBanner(
      context,
      message: message,
      type: typeNeutral,
      duration: duration,
    );
  }

  /// Shows a success banner (green background, check icon)
  static void showSuccess(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showBanner(
      context,
      message: message,
      type: typeSuccess,
      duration: duration ?? const Duration(milliseconds: 2200),
    );
  }

  /// Shows an error banner (red background, error icon)
  static void showError(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showBanner(
      context,
      message: message,
      type: typeError,
      duration: duration ?? const Duration(milliseconds: 3000),
    );
  }

  /// Shows a warning banner (yellow background, warning icon)
  static void showWarning(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showBanner(
      context,
      message: message,
      type: typeWarning,
      duration: duration ?? const Duration(milliseconds: 3000),
    );
  }

  /// Shows an info banner (blue background, info icon)
  static void showInfo(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    _showBanner(
      context,
      message: message,
      type: typeInfo,
      duration: duration ?? const Duration(milliseconds: 2200),
    );
  }

  /// Internal method to show banner with specific type
  static void _showBanner(
    BuildContext context, {
    required String message,
    required String type,
    Duration? duration,
  }) {
    // Remove current banner if exists
    _currentBanner?.remove();
    _currentBanner = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final GlobalKey<_TopBannerWidgetState> bannerKey = GlobalKey();

    overlayEntry = OverlayEntry(
      builder: (context) => _TopBannerWidget(
        key: bannerKey,
        message: message,
        type: type,
        onDismiss: () {
          overlayEntry.remove();
          if (_currentBanner == overlayEntry) {
            _currentBanner = null;
          }
        },
      ),
    );

    overlay.insert(overlayEntry);
    _currentBanner = overlayEntry;

    // Auto-dismiss after duration if specified
    if (duration != null) {
      Future.delayed(duration, () {
        if (overlayEntry.mounted && _currentBanner == overlayEntry) {
          // Trigger upward animation before removing
          bannerKey.currentState?._animateDismiss();
        }
      });
    }
  }
}

class _TopBannerWidget extends StatefulWidget {
  final String message;
  final String type;
  final VoidCallback onDismiss;

  const _TopBannerWidget({
    super.key,
    required this.message,
    required this.type,
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

  /// Animate banner dismissal upward
  void _animateDismiss() {
    setState(() {
      _dragDistance = -200; // Move banner up off-screen
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
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
    // If dragged up more than 50 pixels, dismiss with upward animation
    if (_dragDistance < -50) {
      // Animate upward (beyond initial position) before dismissing
      setState(() {
        _dragDistance = -200; // Move banner up off-screen
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        widget.onDismiss();
      });
    } else {
      // Reset position
      setState(() {
        _dragDistance = 0;
      });
    }
  }

  // Get banner configuration based on type
  _BannerConfig _getConfig() {
    switch (widget.type) {
      case TopBanner.typeSuccess:
        return const _BannerConfig(
          backgroundColor: BrandColors.notificationSuccess, // Green (planning)
          icon: Icons.check_circle,
          iconColor: Colors.white,
        );
      case TopBanner.typeError:
        return const _BannerConfig(
          backgroundColor: BrandColors.notificationError, // Red (cantVote)
          icon: Icons.error,
          iconColor: Colors.white,
        );
      case TopBanner.typeWarning:
        return const _BannerConfig(
          backgroundColor: BrandColors.notificationWarning, // Yellow (warning)
          icon: Icons.warning,
          iconColor: Colors.white,
        );
      case TopBanner.typeInfo:
        return _BannerConfig(
          backgroundColor: BrandColors.notificationInfo
              .withValues(alpha: 0.95), // Neutral bg2
          icon: Icons.info,
          iconColor: BrandColors.text1,
        );
      case TopBanner.typeNeutral:
      default:
        return _BannerConfig(
          backgroundColor:
              BrandColors.notificationNeutral.withValues(alpha: 0.95),
          icon: null,
          iconColor: null,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final config = _getConfig();

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
                top: topPadding + kToolbarHeight + 8, // 8px offset below AppBar
                left: Insets.screenH,
                right: Insets.screenH,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: Pads.sectionH,
                vertical: Gaps.md,
              ),
              decoration: BoxDecoration(
                color: config.backgroundColor,
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
                  color: (widget.type == TopBanner.typeNeutral ||
                          widget.type == TopBanner.typeInfo)
                      ? BrandColors.text1
                      : Colors.white,
                  decoration: TextDecoration.none,
                ),
                child: Row(
                  children: [
                    // Icon (only for typed banners)
                    if (config.icon != null) ...[
                      Icon(
                        config.icon,
                        color: config.iconColor,
                        size: 20,
                      ),
                      const SizedBox(width: Gaps.sm),
                    ],
                    // Message text (left aligned)
                    Expanded(
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.left,
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

/// Banner configuration helper class
class _BannerConfig {
  final Color backgroundColor;
  final IconData? icon;
  final Color? iconColor;

  const _BannerConfig({
    required this.backgroundColor,
    this.icon,
    this.iconColor,
  });
}
