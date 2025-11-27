import 'package:flutter/material.dart';
import 'interactive_share_card_preview.dart';
import '../../../../shared/components/widgets/grabber_bar.dart';
import '../../../../shared/components/common/top_banner.dart';
import '../../../../shared/constants/spacing.dart';
import '../../../../shared/constants/text_styles.dart';
import '../../../../shared/themes/colors.dart';
import '../../domain/entities/memory_entity.dart';

/// Bottom sheet for editing photos in the share card
/// Shows a preview of ShareCard and a grid of all photos for selection
class EditSharePhotosSheet extends StatefulWidget {
  final MemoryEntity memory;
  final List<String> initialSelectedPhotoIds;
  final Function(List<String> photoIds) onSave;

  const EditSharePhotosSheet({
    super.key,
    required this.memory,
    required this.initialSelectedPhotoIds,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required MemoryEntity memory,
    required List<String> initialSelectedPhotoIds,
    required Function(List<String> photoIds) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditSharePhotosSheet(
        memory: memory,
        initialSelectedPhotoIds: initialSelectedPhotoIds,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditSharePhotosSheet> createState() => _EditSharePhotosSheetState();
}

class _EditSharePhotosSheetState extends State<EditSharePhotosSheet> {
  late List<String> _selectedPhotoIds;
  static const int _requiredPhotos = 4;

  @override
  void initState() {
    super.initState();
    _selectedPhotoIds = List.from(widget.initialSelectedPhotoIds);
  }

  void _togglePhoto(String photoId) {
    setState(() {
      if (_selectedPhotoIds.contains(photoId)) {
        _selectedPhotoIds.remove(photoId);
      } else {
        if (_selectedPhotoIds.length < _requiredPhotos) {
          _selectedPhotoIds.add(photoId);
        } else {
          // Show warning when trying to select more than 4
          TopBanner.showWarning(
            context,
            message: 'Only 4 photos can be selected',
          );
        }
      }
    });
  }

  int? _getPhotoOrder(String photoId) {
    final index = _selectedPhotoIds.indexOf(photoId);
    return index >= 0 ? index + 1 : null;
  }

  bool get _canSave => _selectedPhotoIds.length == _requiredPhotos;

  void _handleSave() {
    if (_canSave) {
      widget.onSave(_selectedPhotoIds);
      Navigator.of(context).pop();
    } else {
      // Show warning when trying to save without 4 photos
      TopBanner.showWarning(
        context,
        message: 'Please select 4 photos to continue',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get photos for preview
    final selectedPhotos = widget.memory.photos
        .where((p) => _selectedPhotoIds.contains(p.id))
        .toList();

    final heroPhoto = selectedPhotos.isNotEmpty ? selectedPhotos[0] : null;
    final thumbnails = selectedPhotos.length > 1
        ? selectedPhotos.sublist(1, selectedPhotos.length.clamp(0, 4))
        : <MemoryPhoto>[];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.95,
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
          // Grabber bar
          const Center(child: GrabberBar()),
          const SizedBox(height: Gaps.sm),

          // Header with title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Edit Share Photos',
                style: AppText.titleMediumEmph.copyWith(
                  color: BrandColors.text1,
                ),
              ),
            ),
          ),

          const SizedBox(height: Gaps.lg),

          // Preview of ShareCard (only the card, no background)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
            child: _buildPreview(heroPhoto, thumbnails),
          ),

          const SizedBox(height: Gaps.lg),

          // Scrollable photo grid
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: Gaps.lg),
              child: _buildPhotoGrid(),
            ),
          ),

          // Save button
          Padding(
            padding: EdgeInsets.only(
              left: Gaps.lg,
              right: Gaps.lg,
              top: Gaps.sm,
              bottom: Gaps.lg + MediaQuery.of(context).padding.bottom,
            ),
            child: _RecapButton(
              text: 'Save',
              onPressed: _handleSave,
              isEnabled: _canSave,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(MemoryPhoto? heroPhoto, List<MemoryPhoto> thumbnails) {
    // Build list of 4 photo URLs (null for empty slots)
    final photoUrls = <String?>[];

    if (_selectedPhotoIds.isNotEmpty) {
      for (final photoId in _selectedPhotoIds) {
        final photo = widget.memory.photos.firstWhere(
          (p) => p.id == photoId,
          orElse: () => widget.memory.photos.first,
        );
        photoUrls.add(photo.coverUrl ?? photo.url);
      }
    }

    // Fill remaining slots with null
    while (photoUrls.length < 4) {
      photoUrls.add(null);
    }

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.6,
      child: Center(
        child: InteractiveShareCardPreview(
          title: widget.memory.title,
          location: widget.memory.location,
          eventDate: widget.memory.eventDate,
          photoUrls: photoUrls,
          onPickPhoto: (index) {
            // Find first unselected photo and add it
            final unselectedPhotos = widget.memory.photos
                .where((p) => !_selectedPhotoIds.contains(p.id))
                .toList();
            if (unselectedPhotos.isNotEmpty &&
                _selectedPhotoIds.length < _requiredPhotos) {
              _togglePhoto(unselectedPhotos.first.id);
            }
          },
          onRemovePhoto: (index) {
            if (index < _selectedPhotoIds.length) {
              final photoId = _selectedPhotoIds[index];
              _togglePhoto(photoId);
            }
          },
        ),
      ),
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: Gaps.sm,
        mainAxisSpacing: Gaps.sm,
        childAspectRatio: 1,
      ),
      itemCount: widget.memory.photos.length,
      itemBuilder: (context, index) {
        final photo = widget.memory.photos[index];
        final photoOrder = _getPhotoOrder(photo.id);
        final isSelected = photoOrder != null;

        return GestureDetector(
          onTap: () => _togglePhoto(photo.id),
          child: Stack(
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.sm),
                child: Container(
                  decoration: BoxDecoration(
                    border: isSelected
                        ? Border.all(
                            color: BrandColors.recap,
                            width: 3,
                          )
                        : null,
                  ),
                  child: Image.network(
                    photo.thumbnailUrl ?? photo.url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),

              // Order badge
              if (isSelected)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: BrandColors.recap,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$photoOrder',
                        style: AppText.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom button with recap color highlight
class _RecapButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isEnabled;

  const _RecapButton({
    required this.text,
    required this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? BrandColors.recap : BrandColors.bg3,
          foregroundColor: Colors.white,
          disabledBackgroundColor: BrandColors.bg3,
          disabledForegroundColor: BrandColors.text2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.md),
          ),
          elevation: 0,
        ),
        child: Text(
          text,
          style: AppText.labelLarge.copyWith(
            color: isEnabled ? Colors.white : BrandColors.text2,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
