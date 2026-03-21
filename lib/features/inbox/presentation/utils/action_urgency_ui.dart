import 'package:flutter/material.dart';

import '../../domain/entities/action.dart';
import '../../../../shared/themes/colors.dart';

/// UI-only urgency mapping for inbox actions.
/// Keeps color rules centralized and consistent across widgets.
Color actionUrgencyColor(ActionEntity action) {
  if (action.isOverdue) {
    return BrandColors.cantVote; // Red
  }

  final timeLeft = action.timeLeft;
  if (timeLeft == null) return BrandColors.text2;

  if (timeLeft.inHours <= 2) {
    return BrandColors.cantVote; // Red
  } else if (timeLeft.inHours <= 24) {
    return BrandColors.recap; // Orange
  } else {
    return BrandColors.planning; // Green
  }
}
