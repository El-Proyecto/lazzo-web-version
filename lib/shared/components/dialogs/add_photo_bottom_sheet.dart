import 'package:flutter/material.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Event option for the add photo event selector
class PhotoEventOption {
  final String id;
  final String name;
  final String emoji;

  const PhotoEventOption({
    required this.id,
    required this.name,
    required this.emoji,
  });
}

/// Bottom sheet to select an event for adding photos.
/// Phase 1 of the add photo flow when multiple events exist.
class AddPhotoEventSelectorSheet {
  static Future<PhotoEventOption?> show({
    required BuildContext context,
    required List<PhotoEventOption> events,
    required String title,
  }) {
    return showModalBottomSheet<PhotoEventOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        width: double.infinity,
        decoration: const ShapeDecoration(
          color: BrandColors.bg2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Radii.pill),
              topRight: Radius.circular(Radii.pill),
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(Insets.screenH),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: AppText.labelLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Gaps.lg),
                ...events.map(
                  (event) => Padding(
                    padding: const EdgeInsets.only(bottom: Gaps.md),
                    child: _EventOptionTile(
                      event: event,
                      onTap: () => Navigator.of(context).pop(event),
                    ),
                  ),
                ),
                const SizedBox(height: Gaps.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EventOptionTile extends StatelessWidget {
  final PhotoEventOption event;
  final VoidCallback onTap;

  const _EventOptionTile({required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(Pads.ctlV),
        decoration: BoxDecoration(
          color: BrandColors.bg3,
          borderRadius: BorderRadius.circular(Radii.md),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Text(
                event.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: Gaps.sm),
            Expanded(
              child: Text(
                event.name,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: BrandColors.text2,
              size: IconSizes.md,
            ),
          ],
        ),
      ),
    );
  }
}
