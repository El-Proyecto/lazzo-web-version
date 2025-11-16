import 'package:flutter/material.dart';
import '../../../features/home/domain/entities/participant_photo.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';

/// Bottom sheet to display photo contributions by participants
/// Shows in Living and Recap states
class PhotosBottomSheet {
  static void show({
    required BuildContext context,
    required List<ParticipantPhoto> participants,
    required int totalPhotos,
    required int maxPhotos,
  }) {
    // Sort participants by photo count (descending)
    final sortedParticipants = List<ParticipantPhoto>.from(participants)
      ..sort((a, b) => b.photoCount.compareTo(a.photoCount));

    final photoCountText = totalPhotos == 0
        ? 'No photos yet'
        : '$totalPhotos of $maxPhotos photos';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: const BoxDecoration(
          color: BrandColors.bg2,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(Radii.md),
            topRight: Radius.circular(Radii.md),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Grabber
            Container(
              margin: const EdgeInsets.only(top: Gaps.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: BrandColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: Gaps.sm),

            // Custom Header with photo count on the right
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Photos by participants',
                    style: AppText.titleMediumEmph.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                  Text(
                    photoCountText,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Gaps.lg),

            // Content - List of participants
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: Gaps.lg,
                  right: Gaps.lg,
                  bottom: Gaps.lg,
                ),
                child: Column(
                  children: sortedParticipants
                      .map(
                        (participant) =>
                            _ParticipantPhotoItem(participant: participant),
                      )
                      .toList(),
                ),
              ),
            ),

            // Bottom safe area
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

/// Individual participant photo item
class _ParticipantPhotoItem extends StatelessWidget {
  final ParticipantPhoto participant;

  const _ParticipantPhotoItem({required this.participant});

  String get _displayName {
    // Show "You" for current user, otherwise show the user name
    return participant.userId == 'current_user' ? 'You' : participant.userName;
  }

  String get _photoText {
    if (participant.photoCount == 0) {
      return 'No photos yet';
    } else if (participant.photoCount == 1) {
      return '1 photo';
    } else {
      return '${participant.photoCount} photos';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gaps.sm),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 16,
            backgroundColor: BrandColors.bg3,
            child: participant.userAvatar != null &&
                    participant.userAvatar!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      participant.userAvatar!,
                      width: 32,
                      height: 32,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildDefaultAvatar(),
                    ),
                  )
                : _buildDefaultAvatar(),
          ),
          const SizedBox(width: Gaps.sm),

          // Name
          Expanded(
            child: Text(
              _displayName,
              style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
            ),
          ),

          // Photo count
          Text(
            _photoText,
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Text(
      participant.userName.isNotEmpty
          ? participant.userName[0].toUpperCase()
          : '?',
      style: AppText.bodyMediumEmph.copyWith(
        color: BrandColors.text2,
        fontSize: 14,
      ),
    );
  }
}
