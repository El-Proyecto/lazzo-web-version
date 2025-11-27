import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../shared/themes/colors.dart';

/// Full-screen preview of ShareCard PNG image for Instagram Story export
/// Shows the exact 1080x1920 PNG that will be shared
class ShareMemoryPreviewPage extends StatelessWidget {
  final Uint8List imageBytes;

  const ShareMemoryPreviewPage({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrandColors.bg1,
      body: SafeArea(
        child: Stack(
          children: [
            // Full-screen PNG image (1080x1920)
            Center(
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: Image.memory(
                  imageBytes,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            // Close button
            Positioned(
              top: 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
