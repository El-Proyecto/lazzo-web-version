import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/components/nav/common_app_bar.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/text_styles.dart';
import '../providers/group_hub_providers.dart';
import 'group_photo_viewer_page.dart';

class GroupPhotosPage extends ConsumerStatefulWidget {
  final String memoryId;
  final String eventName;
  final String locationAndDate;

  const GroupPhotosPage({
    super.key,
    required this.memoryId,
    required this.eventName,
    required this.locationAndDate,
  });

  @override
  ConsumerState<GroupPhotosPage> createState() => _GroupPhotosPageState();
}

class _GroupPhotosPageState extends ConsumerState<GroupPhotosPage> {
  bool _isSelectionMode = false;
  final Set<String> _selectedPhotoIds = {};

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

  void _handleShare() {
    // TODO: Implement share functionality
    print('Sharing ${_selectedPhotoIds.length} photos');
  }

  void _handleDownload() {
    // TODO: Implement download functionality
    print('Downloading ${_selectedPhotoIds.length} photos');
  }

  @override
  Widget build(BuildContext context) {
    final photosAsync = ref.watch(groupPhotosProvider(widget.memoryId));

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
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: BrandColors.bg2,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: BrandColors.text2,
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
                              onTap: _handleShare,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: BrandColors.bg3,
                                  borderRadius: BorderRadius.circular(Radii.md),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.ios_share,
                                      color: BrandColors.text1,
                                      size: 20,
                                    ),
                                    const SizedBox(width: Gaps.xs),
                                    Text(
                                      'Share',
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
                              onTap: _handleDownload,
                              child: Container(
                                height: 48,
                                decoration: BoxDecoration(
                                  color: BrandColors.planning,
                                  borderRadius: BorderRadius.circular(Radii.md),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(
                                      Icons.download_rounded,
                                      color: BrandColors.text1,
                                      size: 20,
                                    ),
                                    const SizedBox(width: Gaps.xs),
                                    Text(
                                      'Download',
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
