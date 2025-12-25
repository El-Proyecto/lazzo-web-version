import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Widget to encourage participants to help plan event
/// when location or date (or both) are not defined or suggested.
///
/// This widget appears when event fields are missing AND no suggestions
/// have been added for those fields yet.
///
/// Visibility logic:
/// - Hidden when both date and location are defined
/// - Hidden when missing field has suggestions (widget shrinks)
/// - Shown when at least one field is missing AND no suggestion for it
///
/// Design: Similar layout to RSVPWidget for visual consistency
/// - Same padding, border radius, background color
/// - Title "Help plan this event"
/// - Dynamic CTA button text based on missing fields and suggestions
///
/// Usage:
/// ```dart
/// HelpPlanEventWidget(
///   hasLocation: event.hasDefinedLocation,
///   hasDate: event.hasDefinedDate,
///   hasSuggestedLocation: locationSuggestions.isNotEmpty,
///   hasSuggestedDate: dateSuggestions.isNotEmpty,
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

  /// Whether there are location suggestions added
  final bool hasSuggestedLocation;

  /// Whether there are date suggestions added
  final bool hasSuggestedDate;

  /// Callback when user taps the add suggestion button
  final VoidCallback onAddSuggestion;

  /// Optional custom title (defaults to 'Help plan this event')
  final String? customTitle;

  const HelpPlanEventWidget({
    super.key,
    required this.hasLocation,
    required this.hasDate,
    required this.hasSuggestedLocation,
    required this.hasSuggestedDate,
    required this.onAddSuggestion,
    this.customTitle,
  });

  /// Dynamic button text based on what fields are missing/suggested
  /// Logic:
  /// - Both missing, no suggestions: "Add date and place suggestion"
  /// - One defined/suggested: "Add [missing] suggestion"
  String get _buttonText {
    final locationOk = hasLocation || hasSuggestedLocation;
    final dateOk = hasDate || hasSuggestedDate;

    if (!locationOk && !dateOk) {
      return 'Add date and place suggestion';
    } else if (!locationOk) {
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
            customTitle ?? 'Help plan this event',
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
                color: BrandColors.text1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
