import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:gal/gal.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/text_styles.dart';
import '../providers/group_hub_providers.dart';
import 'group_photo_viewer_page.dart';

class GroupPhotosPage extends ConsumerStatefulWidget {
  final String groupId;
  final String eventName;
  final String locationAndDate;

  const GroupPhotosPage({
    super.key,
    required this.groupId,
    required this.eventName,
    required this.locationAndDate,
  });

  @override
  ConsumerState<GroupPhotosPage> createState() => _GroupPhotosPageState();
}

class _GroupPhotosPageState extends ConsumerState<GroupPhotosPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};
  bool _isProcessing = false;

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedPhotoIds.clear();
      }
    });
  }

  void _togglePhotoSelection(String photoId) {
    setState(() {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
      } else {
        _selectedPhotoIds.add(photoId);
      }
    });
  }

  Future<void> _handleShare() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final photosAsync = ref.read(groupPhotosProvider(widget.groupId));
      final photos = photosAsync.value;
      if (photos == null) return;

      final selectedPhotos = photos
          .where((photo) => _selectedPhotoIds.contains(photo.id))
          .toList();

      if (selectedPhotos.isEmpty) return;

      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Preparing ${selectedPhotos.length} photo(s)...'),
          backgroundColor: BrandColors.bg3,
          duration: const Duration(seconds: 2),
        ),
      );

      // Download photos to temp directory
      final tempDir = await getTemporaryDirectory();
      final files = <XFile>[];

      for (var i = 0; i < selectedPhotos.length; i++) {
        final photo = selectedPhotos[i];
        try {
          final response = await http.get(Uri.parse(photo.url));
          if (response.statusCode == 200) {
            final fileName = 'photo_${i + 1}.jpg';
            final filePath = path.join(tempDir.path, fileName);
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);
            files.add(XFile(filePath));
          }
        } catch (e) {
          print('Error downloading photo: $e');
        }
      }

      if (files.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to prepare photos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Share the files
      await Share.shareXFiles(
        files,
        text: 'Check out these photos from ${widget.eventName}',
      );

      // Exit selection mode after sharing
      setState(() {
        _isSelectionMode = false;
        _selectedPhotoIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDownload() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final photosAsync = ref.read(groupPhotosProvider(widget.groupId));
      final photos = photosAsync.value;
      if (photos == null) return;

      final selectedPhotos = photos
          .where((photo) => _selectedPhotoIds.contains(photo.id))
          .toList();

      if (selectedPhotos.isEmpty) return;

      // Show loading
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading ${selectedPhotos.length} photo(s)...'),
          backgroundColor: BrandColors.bg3,
          duration: const Duration(seconds: 2),
        ),
      );

      int successCount = 0;
      for (var i = 0; i < selectedPhotos.length; i++) {
        final photo = selectedPhotos[i];
        try {
          // Download photo to temporary directory first
          final response = await http.get(Uri.parse(photo.url));
          if (response.statusCode == 200) {
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final tempDir = await getTemporaryDirectory();
            final fileName = 'lazzo_${timestamp}_${i + 1}.jpg';
            final filePath = path.join(tempDir.path, fileName);
            final file = File(filePath);
            await file.writeAsBytes(response.bodyBytes);
            
            // Save to device gallery using Gal package
            // Android: Saves to Pictures/ folder (visible in Gallery/Photos app)
            // iOS: Saves to Photos app
            try {
              await Gal.putImage(filePath, album: 'Lazzo');
              successCount++;
              print('✅ Saved photo ${i + 1} to gallery');
            } catch (e) {
              print('❌ Failed to save photo ${i + 1} to gallery: $e');
              // Gallery permission might be needed, but file is downloaded
            }
          }
        } catch (e) {
          print('❌ Error downloading photo ${i + 1}: $e');
        }
      }

      if (!mounted) return;
      
      if (successCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Saved $successCount photo(s) to gallery!\n'
              'Check Pictures/Lazzo folder or Photos app',
            ),
            backgroundColor: BrandColors.planning,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: BrandColors.text1,
              onPressed: () {},
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save photos. Try again.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Exit selection mode after download
      setState(() {
        _isSelectionMode = false;
        _selectedPhotoIds.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error downloading photos: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(groupPhotosProvider(widget.groupId));

    return Scaffold(
      backgroundColor: BrandColors.bg1,
      appBar: CommonAppBar(
        title: 'Photos',
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: const Icon(
              Icons.arrow_back_ios,
              color: BrandColors.text1,
              size: 20,
            ),
          ),
        ),
        trailing: GestureDetector(
          onTap: _toggleSelectionMode,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: Icon(
              _isSelectionMode ? Icons.close : Icons.check_circle_outline,
              color: BrandColors.text1,
              size: 24,
            ),
          ),
        ),
      ),
      body: photosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => const Center(
          child: Text(
            'Error loading photos',
            style: TextStyle(color: BrandColors.text2),
          ),
        ),
        data: (photos) {
          if (photos.isEmpty) {
            return const Center(
              child: Text(
                'No photos yet',
                style: TextStyle(color: BrandColors.text2),
              ),
            );
          }

          return Stack(
            children: [
              GridView.builder(
                padding: EdgeInsets.only(
                  left: Pads.sectionH,
                  right: Pads.sectionH,
                  top: Pads.sectionH,
                  bottom: _isSelectionMode && _selectedPhotoIds.isNotEmpty
                      ? 100
                      : Pads.sectionH,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 1, // Square tiles
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  final isSelected = _selectedPhotoIds.contains(photo.id);

                  return GestureDetector(
                    onTap: () {
                      if (_isSelectionMode) {
                        _togglePhotoSelection(photo.id);
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => GroupPhotoViewerPage(
                              photos: photos,
                              initialIndex: index,
                              eventName: widget.eventName,
                              locationAndDate: widget.locationAndDate,
                            ),
                          ),
                        );
                      }
                    },
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(Radii.sm),
                            color: BrandColors.bg2,
                            border: _isSelectionMode && isSelected
                                ? Border.all(
                                    color: BrandColors.planning,
                                    width: 3,
                                  )
                                : null,
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: SizedBox.expand(
                            child: Image.network(
                              photo.url,
                              fit: BoxFit.cover,
                              // Performance optimization: cache thumbnails at smaller size
                              cacheWidth: 200,
                              cacheHeight: 200,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: BrandColors.bg2,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: BrandColors.text2,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: BrandColors.bg2,
                                  child: const Center(
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: BrandColors.text2,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        if (_isSelectionMode)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? BrandColors.planning
                                    : BrandColors.bg2.withValues(alpha: 0.8),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: BrandColors.text1,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      color: BrandColors.text1,
                                      size: 16,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),

              // Bottom action bar
              if (_isSelectionMode && _selectedPhotoIds.isNotEmpty)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    color: BrandColors.bg2,
                    padding: const EdgeInsets.symmetric(
                      horizontal: Pads.sectionH,
                      vertical: Gaps.md,
                    ),
                    child: SafeArea(
                      top: false,
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _isProcessing ? null : _handleShare,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _isProcessing
                                      ? BrandColors.bg3.withValues(alpha: 0.5)
                                      : BrandColors.bg3,
                                  borderRadius: BorderRadius.circular(Radii.md),
                                ),
                                child: _isProcessing
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: BrandColors.text1,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.ios_share,
                                            color: BrandColors.text1,
                                            size: 20,
                                          ),
                                          const SizedBox(width: Gaps.xs),
                                          Text(
                                            'Share (${_selectedPhotoIds.length})',
                                            style: AppText.labelLarge.copyWith(
                                              color: BrandColors.text1,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: Gaps.md),
                          Expanded(
                            child: GestureDetector(
                              onTap: _isProcessing ? null : _handleDownload,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _isProcessing
                                      ? BrandColors.planning.withValues(alpha: 0.5)
                                      : BrandColors.planning,
                                  borderRadius: BorderRadius.circular(Radii.md),
                                ),
                                child: _isProcessing
                                    ? const Center(
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: BrandColors.text1,
                                          ),
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            Icons.download_rounded,
                                            color: BrandColors.text1,
                                            size: 20,
                                          ),
                                          const SizedBox(width: Gaps.xs),
                                          Text(
                                            'Download (${_selectedPhotoIds.length})',
                                            style: AppText.labelLarge.copyWith(
                                              color: BrandColors.text1,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
