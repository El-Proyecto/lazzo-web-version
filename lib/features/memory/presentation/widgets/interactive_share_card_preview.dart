import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';

/// Interactive preview of ShareCard with photo slots
/// Shows 1 hero photo + 3 thumbnails with pick/remove functionality
class InteractiveShareCardPreview extends StatelessWidget {
  final String title;
  final String? location;
  final DateTime eventDate;
  final List<String?> photoUrls; // List of 4 URLs (null = empty slot)
  final Function(int index)? onPickPhoto;
  final Function(int index)? onRemovePhoto;

  const InteractiveShareCardPreview({
    super.key,
    required this.title,
    this.location,
    required this.eventDate,
    required this.photoUrls,
    this.onPickPhoto,
    this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    // Ensure we always have exactly 4 slots
    final slots = List<String?>.filled(4, null);
    for (int i = 0; i < photoUrls.length && i < 4; i++) {
      slots[i] = photoUrls[i];
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(32.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(32.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(Gaps.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero photo slot (square)
              _buildPhotoSlot(
                index: 0,
                photoUrl: slots[0],
                isHero: true,
              ),

              const SizedBox(height: Gaps.xs),

              // Thumbnails row (3 square slots)
              Row(
                children: [
                  for (int i = 1; i < 4; i++) ...[
                    if (i > 1) const SizedBox(width: Gaps.xs),
                    Expanded(
                      child: _buildPhotoSlot(
                        index: i,
                        photoUrl: slots[i],
                        isHero: false,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSlot({
    required int index,
    required String? photoUrl,
    required bool isHero,
  }) {
    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

    return AspectRatio(
      aspectRatio: 1.0,
      child: GestureDetector(
        onTap: hasPhoto ? null : () => onPickPhoto?.call(index),
        child: Stack(
          children: [
            // Photo or empty slot
            Container(
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(isHero ? Radii.md : Radii.sm),
                color: hasPhoto ? null : BrandColors.bg3.withValues(alpha: 0.5),
              ),
              child: hasPhoto
                  ? ClipRRect(
                      borderRadius:
                          BorderRadius.circular(isHero ? Radii.md : Radii.sm),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildEmptySlot(isHero);
                        },
                      ),
                    )
                  : _buildEmptySlot(isHero),
            ),

            // Remove button (only if has photo)
            if (hasPhoto && onRemovePhoto != null)
              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: () => onRemovePhoto?.call(index),
                  child: Container(
                    width: isHero ? 28 : 20,
                    height: isHero ? 28 : 20,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: isHero ? 16 : 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptySlot(bool isHero) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            color: Colors.white.withValues(alpha: 0.4),
            size: isHero ? 52 : 20,
          ),
        ],
      ),
    );
  }
}
