import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../../services/analytics_service.dart';
import '../../constants/spacing.dart';
import '../../constants/text_styles.dart';
import '../../themes/colors.dart';
import '../widgets/grabber_bar.dart';
import 'top_banner.dart';

/// Reusable bottom sheet for inviting people via link and QR code
/// Used for groups and events
class InviteBottomSheet extends StatelessWidget {
  final String inviteUrl;
  final String entityName; // "group" or "event" name
  final String entityType; // "group" or "event"

  const InviteBottomSheet({
    super.key,
    required this.inviteUrl,
    required this.entityName,
    required this.entityType,
  });

  /// Show the invite bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String inviteUrl,
    required String entityName,
    required String entityType,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => InviteBottomSheet(
        inviteUrl: inviteUrl,
        entityName: entityName,
        entityType: entityType,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const GrabberBar(),

          // Title
          Padding(
            padding: const EdgeInsets.only(
              left: Pads.sectionH,
              right: Pads.sectionH,
              bottom: Pads.sectionH,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Invite People',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
            ),
          ),

          // Share link section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
            child: _ShareLinkSection(
              linkUrl: inviteUrl,
              onCopyLink: () {
                Clipboard.setData(ClipboardData(text: inviteUrl));
                TopBanner.showInfo(
                  context,
                  message: 'Link copied to clipboard',
                );
                AnalyticsService.track('invite_link_shared', properties: {
                  'share_channel': 'copy',
                  'entity_type': entityType,
                  'platform': 'ios',
                });
              },
              onShareLink: () async {
                final shareText =
                    'Join my $entityType "$entityName" on Lazzo!\n\n$inviteUrl';

                try {
                  await SharePlus.instance.share(
                    ShareParams(
                      text: shareText,
                      subject: 'Join $entityName on Lazzo',
                    ),
                  );
                  AnalyticsService.track('invite_link_shared', properties: {
                    'share_channel': 'share',
                    'entity_type': entityType,
                    'platform': 'ios',
                  });
                } catch (e) {
                  if (context.mounted) {
                    TopBanner.showInfo(
                      context,
                      message:
                          'Unable to share. Link copied to clipboard instead.',
                    );
                    Clipboard.setData(ClipboardData(text: inviteUrl));
                  }
                }
              },
            ),
          ),

          const SizedBox(height: Gaps.lg),

          // QR Code section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
            child: _QrCodeSection(data: inviteUrl),
          ),

          const SizedBox(height: Gaps.lg),

          // Bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + Gaps.sm),
        ],
      ),
    );
  }
}

class _ShareLinkSection extends StatelessWidget {
  final String linkUrl;
  final VoidCallback onCopyLink;
  final VoidCallback onShareLink;

  const _ShareLinkSection({
    required this.linkUrl,
    required this.onCopyLink,
    required this.onShareLink,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        children: [
          // Link icon
          const Icon(
            Icons.insert_link,
            size: IconSizes.lg,
            color: BrandColors.text1,
          ),

          const SizedBox(width: Gaps.md),

          // Link text and expiry
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  linkUrl,
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text1),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Expires in 48h',
                  style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                ),
              ],
            ),
          ),

          const SizedBox(width: Gaps.md),

          // Copy button (bg2)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.bg2,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onCopyLink,
                child: const Icon(
                  Icons.copy,
                  size: IconSizes.sm,
                  color: BrandColors.text1,
                ),
              ),
            ),
          ),

          const SizedBox(width: Gaps.xs),

          // Share button (green)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.planning,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onShareLink,
                child: const Icon(
                  Icons.ios_share,
                  size: IconSizes.sm,
                  color: BrandColors.text1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QrCodeSection extends StatelessWidget {
  final String data;

  const _QrCodeSection({
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Pads.sectionH),
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        children: [
          Text(
            'QR Code',
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
          const SizedBox(height: Gaps.md),
          Container(
            padding: const EdgeInsets.all(Gaps.md),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(Radii.sm),
            ),
            child: QrImageView(
              data: data,
              version: QrVersions.auto,
              size: 180.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: Gaps.md),
          Text(
            'People can scan this QR code to join',
            style: AppText.bodyMedium.copyWith(
              color: BrandColors.text2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
