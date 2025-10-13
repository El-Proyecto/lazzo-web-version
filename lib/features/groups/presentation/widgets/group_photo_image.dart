import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/themes/colors.dart';
import '../../../../shared/constants/spacing.dart';
import '../providers/groups_provider.dart';

/// Widget que carrega e exibe a foto de um grupo dinamicamente
/// Converte photoPath em URL usando getGroupCoverUrl
class GroupPhotoImage extends ConsumerWidget {
  final String? photoPath;
  final DateTime? photoUpdatedAt;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final Widget? placeholder;

  const GroupPhotoImage({
    super.key,
    this.photoPath,
    this.photoUpdatedAt,
    this.width = 120,
    this.height = 120,
    this.borderRadius,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Se não há photoPath, mostrar placeholder
    if (photoPath == null || photoPath!.isEmpty) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(Radii.md),
          color: BrandColors.bg2,
        ),
        child: placeholder ?? 
            const Icon(Icons.group, size: 60, color: BrandColors.text2),
      );
    }

    // Se photoPath é uma URL (http/https), usar diretamente
    if (photoPath!.startsWith('http://') || photoPath!.startsWith('https://')) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(Radii.md),
          color: BrandColors.bg2,
          image: DecorationImage(
            image: NetworkImage(photoPath!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Se photoPath é um path no storage, converter para URL
    final urlProvider = groupCoverUrlProvider((photoPath, photoUpdatedAt));
    
    return Consumer(
      builder: (context, ref, child) {
        final urlAsync = ref.watch(urlProvider);
        
        return urlAsync.when(
          data: (url) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(Radii.md),
              color: BrandColors.bg2,
              image: url != null ? DecorationImage(
                image: NetworkImage(url),
                fit: BoxFit.cover,
              ) : null,
            ),
            child: url == null ? (placeholder ?? 
                const Icon(Icons.group, size: 60, color: BrandColors.text2)) : null,
          ),
          loading: () => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(Radii.md),
              color: BrandColors.bg2,
            ),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (error, stack) => Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              borderRadius: borderRadius ?? BorderRadius.circular(Radii.md),
              color: BrandColors.bg2,
            ),
            child: placeholder ?? 
                const Icon(Icons.group, size: 60, color: BrandColors.text2),
          ),
        );
      },
    );
  }
}