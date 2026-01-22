import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import 'dart:io';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/group_photo_entity.dart';
import '../widgets/group_photo_viewer_app_bar.dart';

class GroupPhotoViewerPage extends StatefulWidget {
  final List<GroupPhotoEntity> photos;
  final int initialIndex;
  final String eventName;
  final String locationAndDate;

  const GroupPhotoViewerPage({
    super.key,
    required this.photos,
    required this.initialIndex,
    required this.eventName,
    required this.locationAndDate,
  });

  @override
  State<GroupPhotoViewerPage> createState() => _GroupPhotoViewerPageState();
}

class _GroupPhotoViewerPageState extends State<GroupPhotoViewerPage> {
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _pageController.addListener(_onPageChanged);
  }

  void _onPageChanged() {
    final page = _pageController.page?.round();
    if (page != null && page != _currentIndex) {
      setState(() {
        _currentIndex = page;
      });
    }
  }

  Future<void> _handleDownloadCurrentPhoto() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final currentPhoto = widget.photos[_currentIndex];

      // Download photo to temporary directory
      final response = await http.get(Uri.parse(currentPhoto.url));
      if (response.statusCode == 200) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempDir = await getTemporaryDirectory();
        final fileName = 'lazzo_$timestamp.jpg';
        final filePath = path.join(tempDir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        // Save to device gallery
        await Gal.putImage(filePath, album: 'Lazzo');

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo saved to gallery!'),
            backgroundColor: BrandColors.planning,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        throw Exception('Failed to download photo');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save photo: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: GroupPhotoViewerAppBar(
        title: widget.eventName,
        subtitle: widget.locationAndDate,
        onBackPressed: () => Navigator.of(context).pop(),
        onDownloadPressed: _isDownloading ? null : _handleDownloadCurrentPhoto,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];

          // Check if current user is the uploader
          final currentUserId = Supabase.instance.client.auth.currentUser?.id;
          final isCurrentUser =
              currentUserId != null && photo.uploaderId == currentUserId;
          final displayName =
              isCurrentUser ? 'You' : (photo.uploaderName ?? 'Unknown');

          final hasProfilePhoto = photo.profileImageUrl != null &&
              photo.profileImageUrl!.isNotEmpty;
          final uploaderInitial =
              photo.uploaderName != null && photo.uploaderName!.isNotEmpty
                  ? photo.uploaderName![0].toUpperCase()
                  : '?';

                                                                      
          return Stack(
            children: [
              // Main photo (centered, interactive)
              Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    photo.url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: BrandColors.bg2,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: BrandColors.text2,
                            size: 64,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Uploader info overlay (bottom-left)
              Positioned(
                bottom: 16,
                left: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: BrandColors.bg1.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: BrandColors.bg3,
                        foregroundImage: hasProfilePhoto
                            ? NetworkImage(photo.profileImageUrl!)
                            : null,
                        child: !hasProfilePhoto
                            ? Text(
                                uploaderInitial,
                                style: const TextStyle(
                                  color: BrandColors.text1,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: BrandColors.text1,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
