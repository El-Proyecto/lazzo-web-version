import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for the success banner
class BannerState {
  final bool isVisible;
  final String eventName;
  final String groupName;

  const BannerState({
    this.isVisible = false,
    this.eventName = '',
    this.groupName = '',
  });

  BannerState copyWith({
    bool? isVisible,
    String? eventName,
    String? groupName,
  }) {
    return BannerState(
      isVisible: isVisible ?? this.isVisible,
      eventName: eventName ?? this.eventName,
      groupName: groupName ?? this.groupName,
    );
  }
}

/// Notifier for banner state management
class BannerNotifier extends StateNotifier<BannerState> {
  BannerNotifier() : super(const BannerState());

  /// Show success banner with event details
  void showSuccessBanner(String eventName, String groupName) {
    state = BannerState(
      isVisible: true,
      eventName: eventName,
      groupName: groupName,
    );
  }

  /// Hide the banner (when user closes it)
  void hideBanner() {
    state = state.copyWith(isVisible: false);
  }

  /// Clear banner state completely
  void clearBanner() {
    state = const BannerState();
  }
}

/// Provider for the success banner state
final bannerProvider = StateNotifierProvider<BannerNotifier, BannerState>(
  (ref) => BannerNotifier(),
);
