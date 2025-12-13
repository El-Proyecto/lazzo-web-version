import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Dialog to inform host that event cannot be confirmed
/// until all required fields (date and location) are defined.
///
/// This dialog appears when a host tries to confirm an event that
/// is missing date and/or location. It provides clear feedback
/// about what needs to be defined before confirmation is possible.
///
/// Design:
/// - Title: "Cannot Confirm Event"
/// - Dynamic message based on missing fields
/// - Single "Ok" button (not destructive)
/// - Uses standard dialog styling from design system
///
/// Usage:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (context) => MissingFieldsConfirmationDialog(
///     hasLocation: event.hasDefinedLocation,
///     hasDate: event.hasDefinedDate,
///   ),
/// );
/// ```
class MissingFieldsConfirmationDialog extends StatelessWidget {
  /// Whether the event has a location defined
  final bool hasLocation;

  /// Whether the event has a date defined
  final bool hasDate;

  const MissingFieldsConfirmationDialog({
    super.key,
    required this.hasLocation,
    required this.hasDate,
  });

  /// Dynamic message text based on what fields are missing
  String get _message {
    if (!hasLocation && !hasDate) {
      return 'You need to define both date and location before confirming this event.';
    } else if (!hasLocation) {
      return 'You need to define a location before confirming this event.';
    } else {
      return 'You need to define a date before confirming this event.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BrandColors.bg2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Gaps.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Cannot Confirm Event',
              style: AppText.titleMediumEmph.copyWith(
                color: BrandColors.text1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.sm),

            // Message
            Text(
              _message,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Gaps.md),

            // Ok Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BrandColors.planning,
                  foregroundColor: BrandColors.bg1,
                  padding: const EdgeInsets.symmetric(
                    vertical: Pads.ctlVSm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Radii.smAlt),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Ok',
                  style: AppText.labelLarge.copyWith(
                    color: BrandColors.bg1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
