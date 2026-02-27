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

/// Reusable bottom sheet for sharing events via QR code or invite card.
///
/// Two sharing modes:
/// 1. **QR Code** — Scannable QR that opens the invite link
/// 2. **Card** — Visual card with event emoji (Partiful-style) + link
class InviteBottomSheet extends StatefulWidget {
  final String inviteUrl;
  final String entityName;
  final String entityType;
  final String eventEmoji;
  final String? eventId;

  const InviteBottomSheet({
    super.key,
    required this.inviteUrl,
    required this.entityName,
    required this.entityType,
    this.eventEmoji = '📅',
    this.eventId,
  });

  /// Show the invite bottom sheet
  static Future<void> show({
    required BuildContext context,
    required String inviteUrl,
    required String entityName,
    required String entityType,
    String eventEmoji = '📅',
    String? eventId,
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
        eventEmoji: eventEmoji,
        eventId: eventId,
      ),
    );
  }

  @override
  State<InviteBottomSheet> createState() => _InviteBottomSheetState();
}

class _InviteBottomSheetState extends State<InviteBottomSheet> {
  int _selectedTab = 0; // 0 = QR Code, 1 = Card

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
          const GrabberBar(),

          // Title
          Padding(
            padding: const EdgeInsets.only(
              left: Pads.sectionH,
              right: Pads.sectionH,
              bottom: Gaps.md,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Share',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
            ),
          ),

          // Tab switcher
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: BrandColors.bg3,
                borderRadius: BorderRadius.circular(Radii.sm),
              ),
              child: Row(
                children: [
                  _TabButton(
                    label: 'QR Code',
                    icon: Icons.qr_code_2,
                    isSelected: _selectedTab == 0,
                    onTap: () => setState(() => _selectedTab = 0),
                  ),
                  _TabButton(
                    label: 'Card',
                    icon: Icons.style,
                    isSelected: _selectedTab == 1,
                    onTap: () => setState(() => _selectedTab = 1),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: Gaps.lg),

          // Content
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _selectedTab == 0
                ? _QrCodeTab(
                    key: const ValueKey('qr'),
                    inviteUrl: widget.inviteUrl,
                  )
                : _InviteCardTab(
                    key: const ValueKey('card'),
                    inviteUrl: widget.inviteUrl,
                    entityName: widget.entityName,
                    entityType: widget.entityType,
                    eventEmoji: widget.eventEmoji,
                  ),
          ),

          const SizedBox(height: Gaps.md),

          // Action buttons row (Copy + Share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
            child: Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.copy,
                    label: 'Copy link',
                    color: BrandColors.bg3,
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: widget.inviteUrl),
                      );
                      TopBanner.showInfo(
                        context,
                        message: 'Link copied to clipboard',
                      );
                      AnalyticsService.track('invite_link_shared', properties: {
                        if (widget.eventId != null) 'event_id': widget.eventId!,
                        'share_method': 'copy_link',
                        'platform': 'ios',
                      });
                    },
                  ),
                ),
                const SizedBox(width: Gaps.sm),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.ios_share,
                    label: 'Share',
                    color: BrandColors.planning,
                    onTap: () async {
                      final shareContent =
                          _selectedTab == 0 ? 'qr_code' : 'card';
                      try {
                        await SharePlus.instance.share(
                          ShareParams(
                            text:
                                'Join my ${widget.entityType} "${widget.entityName}" on Lazzo!\n\n${widget.inviteUrl}',
                            subject: 'Join ${widget.entityName} on Lazzo',
                          ),
                        );
                        AnalyticsService.track('invite_link_shared',
                            properties: {
                              if (widget.eventId != null)
                                'event_id': widget.eventId!,
                              'share_method': 'share',
                              'share_content': shareContent,
                              'platform': 'ios',
                            });
                      } catch (e) {
                        if (context.mounted) {
                          TopBanner.showInfo(
                            context,
                            message:
                                'Unable to share. Link copied to clipboard instead.',
                          );
                          Clipboard.setData(
                            ClipboardData(text: widget.inviteUrl),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ),
          ),

          SizedBox(
            height: MediaQuery.of(context).padding.bottom + Gaps.lg,
          ),
        ],
      ),
    );
  }
}

// ── Tab button ───────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isSelected ? BrandColors.bg2 : Colors.transparent,
            borderRadius: BorderRadius.circular(Radii.sm - 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? BrandColors.text1 : BrandColors.text2,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppText.labelLarge.copyWith(
                  color: isSelected ? BrandColors.text1 : BrandColors.text2,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── QR Code Tab ──────────────────────────────────────────────

class _QrCodeTab extends StatelessWidget {
  final String inviteUrl;

  const _QrCodeTab({super.key, required this.inviteUrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
      child: Column(
        children: [
          // QR container
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(Gaps.lg),
            decoration: BoxDecoration(
              color: BrandColors.bg3,
              borderRadius: BorderRadius.circular(Radii.md),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(Gaps.md),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(Radii.sm),
                  ),
                  child: QrImageView(
                    data: inviteUrl,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: Gaps.md),
                Text(
                  'Scan to join the event',
                  style: AppText.bodyMedium.copyWith(
                    color: BrandColors.text2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Invite Card Tab (Partiful-style) ─────────────────────────

class _InviteCardTab extends StatelessWidget {
  final String inviteUrl;
  final String entityName;
  final String entityType;
  final String eventEmoji;

  const _InviteCardTab({
    super.key,
    required this.inviteUrl,
    required this.entityName,
    required this.entityType,
    required this.eventEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Pads.sectionH),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(Gaps.lg),
        decoration: BoxDecoration(
          color: BrandColors.bg1,
          borderRadius: BorderRadius.circular(Radii.md),
          border: Border.all(
            color: BrandColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: Gaps.md),

            // Big emoji
            Text(
              eventEmoji,
              style: const TextStyle(fontSize: 72),
            ),

            const SizedBox(height: Gaps.lg),

            // Event name
            Text(
              entityName,
              style: AppText.titleLargeEmph.copyWith(
                color: BrandColors.text1,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: Gaps.sm),

            // Subtitle
            Text(
              'You\'re invited!',
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
              ),
            ),

            const SizedBox(height: Gaps.lg),

            // Lazzo branding — app icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/app_icon.png',
                    width: 20,
                    height: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'LAZZO',
                  style: AppText.labelLarge.copyWith(
                    color: BrandColors.text2,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: Gaps.md),
          ],
        ),
      ),
    );
  }
}

// ── Action Button ────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(Radii.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Gaps.md,
            vertical: Gaps.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: IconSizes.sm, color: BrandColors.text1),
              const SizedBox(width: Gaps.xs),
              Text(
                label,
                style: AppText.labelLarge.copyWith(
                  color: BrandColors.text1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
