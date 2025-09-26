import 'package:flutter/material.dart';
import '../../themes/colors.dart';

/// Tokenized editable profile photo component
/// Shows current photo with edit overlay and tap handler
class EditableProfilePhoto extends StatelessWidget {
  final String? profileImageUrl;
  final VoidCallback onTap;
  final double size;

  const EditableProfilePhoto({
    super.key,
    this.profileImageUrl,
    required this.onTap,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          // Profile photo
          Container(
            width: size,
            height: size,
            decoration: const ShapeDecoration(
              color: BrandColors.bg3,
              shape: CircleBorder(
                side: BorderSide(width: 2, color: BrandColors.border),
              ),
            ),
            child: ClipOval(
              child: profileImageUrl != null && profileImageUrl!.isNotEmpty
                  ? Image.network(
                      profileImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),

          // Edit overlay
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 36,
              height: 36,
              decoration: const ShapeDecoration(
                color: BrandColors.planning,
                shape: CircleBorder(
                  side: BorderSide(width: 2, color: BrandColors.bg1),
                ),
              ),
              child: const Icon(Icons.camera_alt, size: 18, color: BrandColors.text1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: BrandColors.bg3,
      child: Icon(Icons.person, size: size * 0.4, color: BrandColors.text2),
    );
  }
}
