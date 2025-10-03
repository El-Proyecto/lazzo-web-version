import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

class EventPage extends StatelessWidget {
  final String? eventId;
  final String? section; // e.g., 'uploads'

  const EventPage({super.key, this.eventId, this.section});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: AppBar(
        backgroundColor: BrandColors.bg1,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.text1),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Event',
          style: AppText.titleMediumEmph.copyWith(color: BrandColors.text1),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Gaps.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.event, size: 64, color: BrandColors.text2),
              const SizedBox(height: Gaps.lg),
              Text(
                'Event Page',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
              const SizedBox(height: Gaps.md),
              Text(
                'This is a placeholder for the event page.',
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                textAlign: TextAlign.center,
              ),
              if (eventId != null) ...[
                const SizedBox(height: Gaps.md),
                Text(
                  'Event ID: $eventId',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                ),
              ],
              if (section != null) ...[
                const SizedBox(height: Gaps.sm),
                Text(
                  'Section: $section',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
