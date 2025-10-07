import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../routes/app_router.dart';
import '../../domain/entities/group_entity.dart';

class GroupCreatedPage extends StatelessWidget {
  final GroupEntity group;

  const GroupCreatedPage({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: '',
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRouter.mainLayout, (route) => false),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(Insets.screenH),
        child: Column(
          children: [
            const SizedBox(height: Gaps.xs),

            // Group photo with rounded corners (not circle)
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(Radii.md),
                color: BrandColors.bg2,
                image: group.photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(group.photoUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: group.photoUrl == null
                  ? const Icon(Icons.group, size: 60, color: BrandColors.text2)
                  : null,
            ),

            const SizedBox(height: Gaps.lg),

            // Title
            Text(
              'Group Created',
              style: AppText.dropdownTitle.copyWith(color: BrandColors.text1),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: Gaps.xs),

            // Subtitle with group name (no quotes, name in text1)
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
                children: [
                  const TextSpan(text: 'Invite people to join '),
                  TextSpan(
                    text: group.name,
                    style: AppText.bodyMedium.copyWith(
                      color: BrandColors.text1,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: Gaps.xl),

            // Share link section
            _ShareLinkSection(
              linkUrl: 'https://lazzo.app/groups/${group.id}',
              onCopyLink: () {
                Clipboard.setData(
                  ClipboardData(text: 'https://lazzo.app/groups/${group.id}'),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Link copied to clipboard'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
              onShareLink: () async {
                final groupLink = 'https://lazzo.app/groups/${group.id}';
                final shareText = 'Join my group "${group.name}" on Lazzo!\n\n$groupLink';
                
                try {
                  await Share.share(
                    shareText,
                    subject: 'Join ${group.name} on Lazzo',
                  );
                } catch (e) {
                  // Fallback if share fails
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Unable to share. Link copied to clipboard instead.'),
                      ),
                    );
                    Clipboard.setData(ClipboardData(text: groupLink));
                  }
                }
              },
            ),

            const SizedBox(height: Gaps.lg),

            // QR Code section (square)
            _QrCodeSection(data: 'https://lazzo.app/groups/${group.id}'),
          ],
        ),
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
      padding: const EdgeInsets.all(Insets.screenH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
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

          // Copy button (bg3)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BrandColors.bg3,
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
                  Icons.share,
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

  const _QrCodeSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Insets.screenH),
      decoration: BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'QR Code',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
              Text(
                'Scan to join',
                style: AppText.bodyMedium.copyWith(color: BrandColors.text2),
              ),
            ],
          ),
          const SizedBox(height: Gaps.xs),
          // Square QR Code container
          AspectRatio(
            aspectRatio: 1.0, // Makes it square
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0), // Using concrete value instead of Insets.md
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radii.md),
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: double.infinity,
                backgroundColor: Colors.white,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                padding: const EdgeInsets.all(8.0),
                // Removed deprecated foregroundColor
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Colors.black,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
