import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Widget to encourage participants to help plan event
/// when location or date (or both) are not defined.
///
/// This widget appears instead of the RSVP widget when the event
/// is not fully defined (missing date and/or location).
///
/// Design: Similar layout to RSVPWidget for visual consistency
/// - Same padding, border radius, background color
/// - Title "Help plan this event"
/// - Single CTA button with dynamic text based on missing fields
///
/// Usage:
/// ```dart
/// HelpPlanEventWidget(
///   hasLocation: event.hasDefinedLocation,
///   hasDate: event.hasDefinedDate,
///   onAddSuggestion: () {
///     // Open bottom sheet to add suggestions
///   },
/// )
/// ```
class HelpPlanEventWidget extends StatelessWidget {
  /// Whether the event has a location defined
  final bool hasLocation;

  /// Whether the event has a date defined
  final bool hasDate;

  /// Callback when user taps the add suggestion button
  final VoidCallback onAddSuggestion;

  const HelpPlanEventWidget({
    super.key,
    required this.hasLocation,
    required this.hasDate,
    required this.onAddSuggestion,
  });

  /// Dynamic button text based on what fields are missing
  String get _buttonText {
    if (!hasLocation && !hasDate) {
      return 'Add date and place suggestion';
    } else if (!hasLocation) {
      return 'Add place suggestion';
    } else {
      return 'Add date suggestion';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            'Help plan this event',
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
          const SizedBox(height: Gaps.sm),

          // CTA Button
          ElevatedButton(
            onPressed: onAddSuggestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: BrandColors.planning,
              foregroundColor: BrandColors.bg1,
              padding: const EdgeInsets.symmetric(
                horizontal: Gaps.md,
                vertical: Pads.ctlVSm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Radii.smAlt),
              ),
              elevation: 0,
            ),
            child: Text(
              _buttonText,
              style: AppText.labelLarge.copyWith(
                color: BrandColors.bg1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
