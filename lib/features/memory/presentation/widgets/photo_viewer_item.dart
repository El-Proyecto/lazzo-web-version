import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/components/common/top_banner.dart';
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

  /// Download photo to device gallery/downloads folder
  Future<void> _handleDownload(BuildContext context) async {
    try {
      // Download the image
      final response = await http.get(Uri.parse(widget.photo.url));
      if (response.statusCode != 200) {
        throw Exception('Failed to download image');
      }

      // Get appropriate directory
      Directory? directory;
      if (Platform.isAndroid) {
        // Try Download folder first, fallback to app directory
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else if (Platform.isIOS) {
        // iOS: use app documents directory (user can share from Files app)
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not find download directory');
      }

      // Generate filename with timestamp
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'lazzo_$timestamp.jpg';
      final filePath = '${directory.path}/$filename';

      // Save the file
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (context.mounted) {
        TopBanner.showSuccess(
          context,
          message: '✓ Photo saved',
        );
      }
    } catch (e) {
      if (context.mounted) {
        TopBanner.showError(
          context,
          message: 'Failed to download photo',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Calculate image dimensions based on aspect ratio
    final isPortrait = widget.photo.aspectRatio < 1.0;

    // For portrait: fit height and center horizontally
    // For landscape: fit width and center vertically
    final double imageWidth;
    final double imageHeight;

    if (isPortrait) {
      // Portrait: use screen width, calculate height
      imageWidth = screenWidth;
      imageHeight = screenWidth / widget.photo.aspectRatio;
    } else {
      // Landscape: calculate dimensions to fit without crop
      // Try to fit width first
      imageWidth = screenWidth;
      imageHeight = screenWidth / widget.photo.aspectRatio;

      // If height exceeds screen, fit by height instead
      if (imageHeight > screenHeight) {
        final adjustedHeight = screenHeight * 0.8; // Leave space for UI
        final adjustedWidth = adjustedHeight * widget.photo.aspectRatio;
        return _buildPhotoContent(
            context, adjustedWidth, adjustedHeight, BoxFit.contain);
      }
    }

    return _buildPhotoContent(context, imageWidth, imageHeight,
        isPortrait ? BoxFit.cover : BoxFit.contain);
  }

  Widget _buildPhotoContent(
      BuildContext context, double width, double height, BoxFit fit) {
    return GestureDetector(
      onTap: _toggleMetadata,
      child: Center(
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              Image.network(
                widget.photo.url,
                fit: fit,
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
                          child: Builder(
                            builder: (context) {
                              final currentUserId =
                                  Supabase.instance.client.auth.currentUser?.id;
                              final isCurrentUser = currentUserId != null &&
                                  widget.photo.uploaderId == currentUserId;
                              final displayName = isCurrentUser
                                  ? 'You'
                                  : widget.photo.uploaderName;
                              final hasProfilePhoto =
                                  widget.photo.profileImageUrl != null &&
                                      widget.photo.profileImageUrl!.isNotEmpty;
                              final uploaderInitial = widget
                                      .photo.uploaderName.isNotEmpty
                                  ? widget.photo.uploaderName[0].toUpperCase()
                                  : '?';

                              return Row(
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: BrandColors.bg3,
                                    foregroundImage: hasProfilePhoto
                                        ? NetworkImage(
                                            widget.photo.profileImageUrl!)
                                        : null,
                                    child: !hasProfilePhoto
                                        ? Text(
                                            uploaderInitial,
                                            style: AppText.bodyMedium.copyWith(
                                              color: BrandColors.text1,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: Gaps.xs),
                                  Text(
                                    displayName,
                                    style: AppText.bodyMedium.copyWith(
                                      color: BrandColors.text1,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        // Top right: Download button
                        Positioned(
                          top: Insets.screenH,
                          right: Insets.screenH,
                          child: GestureDetector(
                            onTap: () => _handleDownload(context),
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
      ),
    );
  }
}
