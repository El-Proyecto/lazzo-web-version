import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/memory_entity.dart';

/// Photo viewer with tap-to-toggle metadata overlay
/// Metadata auto-hides after 2-3 seconds
class PhotoViewerItem extends StatefulWidget {
  final MemoryPhoto photo;
  final DateTime eventDate;
  final bool isMultiDay;

  const PhotoViewerItem({
    super.key,
    required this.photo,
    required this.eventDate,
    required this.isMultiDay,
  });

  @override
  State<PhotoViewerItem> createState() => _PhotoViewerItemState();
}

class _PhotoViewerItemState extends State<PhotoViewerItem> {
  bool _showMetadata = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showMetadata = false;
        });
      }
    });
  }

  void _toggleMetadata() {
    setState(() {
      _showMetadata = !_showMetadata;
    });
    if (_showMetadata) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  String _formatTime(DateTime capturedAt) {
    return DateFormat('HH:mm').format(capturedAt);
  }

  String _formatDate(DateTime capturedAt) {
    return DateFormat('d MMM').format(capturedAt);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final imageHeight = screenWidth / widget.photo.aspectRatio;

    return GestureDetector(
      onTap: _toggleMetadata,
      child: SizedBox(
        width: screenWidth,
        height: imageHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Photo
            Image.network(
              widget.photo.url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: BrandColors.bg3,
                  child: Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: BrandColors.bg3,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: BrandColors.text2,
                      size: 48,
                    ),
                  ),
                );
              },
            ),

            // Metadata overlay
            if (_showMetadata)
              AnimatedOpacity(
                opacity: _showMetadata ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.6),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Top left: Avatar + Name
                      Positioned(
                        top: Insets.screenH,
                        left: Insets.screenH,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: BrandColors.bg3,
                              child: Text(
                                widget.photo.uploaderName[0].toUpperCase(),
                                style: AppText.bodyMedium.copyWith(
                                  color: BrandColors.text1,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: Gaps.xs),
                            Text(
                              widget.photo.uploaderName,
                              style: AppText.bodyMedium.copyWith(
                                color: BrandColors.text1,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Top right: Download button
                      Positioned(
                        top: Insets.screenH,
                        right: Insets.screenH,
                        child: GestureDetector(
                          onTap: () {
                            // TODO P2: Implement download
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Download not implemented'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(Gaps.xs),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(Radii.pill),
                            ),
                            child: const Icon(
                              Icons.download,
                              color: BrandColors.text1,
                              size: IconSizes.sm,
                            ),
                          ),
                        ),
                      ),

                      // Bottom right: Date (if multi-day) • Time
                      Positioned(
                        bottom: Insets.screenH,
                        right: Insets.screenH,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Pads.ctlH,
                            vertical: Gaps.xs,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(Radii.pill),
                          ),
                          child: Text(
                            widget.isMultiDay
                                ? '${_formatDate(widget.photo.capturedAt)} • ${_formatTime(widget.photo.capturedAt)}'
                                : _formatTime(widget.photo.capturedAt),
                            style: AppText.bodyMedium.copyWith(
                              color: BrandColors.text1,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
