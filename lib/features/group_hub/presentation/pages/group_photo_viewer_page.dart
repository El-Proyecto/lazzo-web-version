import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
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
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.photos.length,
        itemBuilder: (context, index) {
          final photo = widget.photos[index];
          
          // Debug print for uploader info
          print('\n👤 [GROUP PHOTO VIEWER] Photo uploader info:');
          print('   - photoId: ${photo.id}');
          print('   - uploaderId: ${photo.uploaderId}');
          print('   - uploaderName: "${photo.uploaderName}"');
          print('   - Display: ${photo.uploaderName ?? "Unknown"}');
          
          return Center(
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
          );
        },
      ),
    );
  }
}
