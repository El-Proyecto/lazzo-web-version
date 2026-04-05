import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';

/// Instagram glyph logo SVG (simplified official shape)
const _instagramSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2.163c3.204 0 3.584.012 4.85.07 1.17.054 1.97.24 2.43.403a4.08 4.08 0 0 1 1.518.988 4.08 4.08 0 0 1 .988 1.518c.163.46.35 1.26.403 2.43.058 1.266.07 1.646.07 4.85s-.012 3.584-.07 4.85c-.054 1.17-.24 1.97-.403 2.43a4.36 4.36 0 0 1-2.506 2.506c-.46.163-1.26.35-2.43.403-1.266.058-1.646.07-4.85.07s-3.584-.012-4.85-.07c-1.17-.054-1.97-.24-2.43-.403a4.08 4.08 0 0 1-1.518-.988 4.08 4.08 0 0 1-.988-1.518c-.163-.46-.35-1.26-.403-2.43C2.175 15.584 2.163 15.204 2.163 12s.012-3.584.07-4.85c.054-1.17.24-1.97.403-2.43a4.08 4.08 0 0 1 .988-1.518 4.08 4.08 0 0 1 1.518-.988c.46-.163 1.26-.35 2.43-.403C8.416 2.175 8.796 2.163 12 2.163M12 0C8.741 0 8.333.014 7.053.072 5.775.131 4.902.333 4.14.63a5.88 5.88 0 0 0-2.126 1.384A5.88 5.88 0 0 0 .63 4.14C.333 4.902.131 5.775.072 7.053.014 8.333 0 8.741 0 12s.014 3.667.072 4.947c.059 1.278.261 2.151.558 2.913a5.88 5.88 0 0 0 1.384 2.126A5.88 5.88 0 0 0 4.14 23.37c.762.297 1.635.499 2.913.558C8.333 23.986 8.741 24 12 24s3.667-.014 4.947-.072c1.278-.059 2.151-.261 2.913-.558a6.14 6.14 0 0 0 3.51-3.51c.297-.762.499-1.635.558-2.913C23.986 15.667 24 15.259 24 12s-.014-3.667-.072-4.947c-.059-1.278-.261-2.151-.558-2.913a5.88 5.88 0 0 0-1.384-2.126A5.88 5.88 0 0 0 19.86.63C19.098.333 18.225.131 16.947.072 15.667.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324zM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8zm6.406-11.845a1.44 1.44 0 1 0 0 2.881 1.44 1.44 0 0 0 0-2.881z" fill="white"/>
</svg>
''';

/// WhatsApp logo SVG (simplified official shape)
const _whatsappSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.297-.15-1.255-.463-2.39-1.475-.883-.788-1.48-1.761-1.653-2.059-.173-.297-.018-.458.13-.606.134-.133.298-.347.446-.52.149-.174.198-.298.298-.497.099-.198.05-.371-.025-.52-.075-.149-.669-1.612-.916-2.207-.242-.579-.487-.5-.669-.51-.173-.008-.371-.01-.57-.01-.198 0-.52.074-.792.372-.272.297-1.04 1.016-1.04 2.479 0 1.462 1.065 2.875 1.213 3.074.149.198 2.096 3.2 5.077 4.487.709.306 1.262.489 1.694.625.712.227 1.36.195 1.871.118.571-.085 1.758-.719 2.006-1.413.248-.694.248-1.289.173-1.413-.074-.124-.272-.198-.57-.347m-5.421 7.403h-.004a9.87 9.87 0 0 1-5.031-1.378l-.361-.214-3.741.982.998-3.648-.235-.374a9.86 9.86 0 0 1-1.51-5.26c.001-5.45 4.436-9.884 9.888-9.884 2.64 0 5.122 1.03 6.988 2.898a9.825 9.825 0 0 1 2.893 6.994c-.003 5.45-4.437 9.884-9.885 9.884m8.413-18.297A11.815 11.815 0 0 0 12.05 0C5.495 0 .16 5.335.157 11.892c0 2.096.547 4.142 1.588 5.945L.057 24l6.305-1.654a11.882 11.882 0 0 0 5.683 1.448h.005c6.554 0 11.89-5.335 11.893-11.893a11.821 11.821 0 0 0-3.48-8.413z" fill="white"/>
</svg>
''';

/// Feature-specific widget for sharing options
class ShareOptionsSection extends StatelessWidget {
  final VoidCallback? onInstagramPressed;
  final VoidCallback? onWhatsAppPressed;
  final VoidCallback? onSavePressed;
  final VoidCallback? onMorePressed;

  const ShareOptionsSection({
    super.key,
    this.onInstagramPressed,
    this.onWhatsAppPressed,
    this.onSavePressed,
    this.onMorePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Gaps.md),
      decoration: const BoxDecoration(
        color: BrandColors.bg2,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Radii.md),
          topRight: Radius.circular(Radii.md),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Share to',
            style: AppText.titleMediumEmph.copyWith(
              color: BrandColors.text1,
            ),
          ),
          const SizedBox(height: Gaps.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShareOption(
                label: 'Instagram Story',
                onPressed: onInstagramPressed,
                child: _BrandIconContainer(
                  gradient: const LinearGradient(
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color(0xFF405DE6),
                      Color(0xFF5851DB),
                      Color(0xFF833AB4),
                      Color(0xFFC13584),
                      Color(0xFFE1306C),
                      Color(0xFFFD1D1D),
                      Color(0xFFF56040),
                      Color(0xFFF77737),
                      Color(0xFFFCAF45),
                      Color(0xFFFFDC80),
                    ],
                  ),
                  child: SvgPicture.string(
                    _instagramSvg,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              _ShareOption(
                label: 'WhatsApp',
                onPressed: onWhatsAppPressed,
                child: _BrandIconContainer(
                  color: const Color(0xFF25D366),
                  child: SvgPicture.string(
                    _whatsappSvg,
                    width: 24,
                    height: 24,
                  ),
                ),
              ),
              _ShareOption(
                label: 'Save',
                onPressed: onSavePressed,
                child: const _MaterialIconContainer(
                  icon: Icons.download_rounded,
                ),
              ),
              _ShareOption(
                label: 'More',
                onPressed: onMorePressed,
                child: const _MaterialIconContainer(
                  icon: Icons.ios_share_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Brand icon container with gradient or solid color background
class _BrandIconContainer extends StatelessWidget {
  final Gradient? gradient;
  final Color? color;
  final Widget child;

  const _BrandIconContainer({
    this.gradient,
    this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? color : null,
        borderRadius: BorderRadius.circular(Radii.smAlt),
      ),
      child: Center(child: child),
    );
  }
}

/// Material icon container with bg3 background
class _MaterialIconContainer extends StatelessWidget {
  final IconData icon;

  const _MaterialIconContainer({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: BrandColors.bg3,
        borderRadius: BorderRadius.circular(Radii.smAlt),
      ),
      child: Icon(
        icon,
        color: BrandColors.text1,
        size: IconSizes.md,
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final Widget child;
  final String label;
  final VoidCallback? onPressed;

  const _ShareOption({
    required this.child,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(Radii.sm),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: Gaps.xs),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            child,
            const SizedBox(height: Gaps.xxs),
            Text(
              label,
              style: AppText.bodyMedium.copyWith(
                color: BrandColors.text2,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
