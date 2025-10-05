import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Location widget for displaying event location
/// Shows location with subtitle and tappable map
/// TODO P2: Implement map preview similar to create_event location section
class LocationWidget extends StatelessWidget {
  final String displayName;
  final String formattedAddress;
  final double latitude;
  final double longitude;

  const LocationWidget({
    super.key,
    required this.displayName,
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with subtitle
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Location', style: AppText.labelLarge),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: AppText.bodyMedium.copyWith(
                  color: BrandColors.text2,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.md),

          // TODO P2: Add map preview here (similar to create_event)
          // Placeholder for map preview - tappable to open Maps
          InkWell(
            onTap: () => _openInMaps(latitude, longitude),
            borderRadius: BorderRadius.circular(Radii.sm),
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: BrandColors.text2),
                    SizedBox(height: Gaps.xs),
                    Text(
                      'Tap to open in Maps',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        height: 20 / 14,
                        letterSpacing: 0.25,
                        color: BrandColors.text2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final urls = [
      'comgooglemaps://?q=$lat,$lng&center=$lat,$lng&zoom=14',
      'googlemaps://?q=$lat,$lng&center=$lat,$lng&zoom=14',
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    ];

    for (final urlString in urls) {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }
  }
}
