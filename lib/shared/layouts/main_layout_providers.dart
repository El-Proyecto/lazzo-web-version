import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to control the current tab in MainLayout
final mainLayoutTabProvider = StateProvider<int>((ref) => 0);
