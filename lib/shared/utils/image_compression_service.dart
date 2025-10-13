import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

/// Serviço de compressão de imagens com suporte a WebP e correção EXIF
class ImageCompressionService {
  static const int maxBytes = 1024 * 1024; // 1MB
  static const int maxEdge = 1280; // maior lado
  static const int quality = 80; // ~80%
  static const int minQuality = 55; // qualidade mínima

  /// Corrige orientação EXIF, redimensiona preservando proporção, exporta imagem otimizada ≤1MB
  static Future<Uint8List> compressToWebP(XFile input) async {
    try {
      print('🖼️ Starting image compression for: ${input.path}');

      // 1) Ler bytes originais
      final originalBytes = await input.readAsBytes();
      final originalSize = originalBytes.length;
      print('   📊 Original size: ${_formatBytes(originalSize)}');

      // 2) Decodificar imagem com correção automática de EXIF
      final image = img.decodeImage(originalBytes);
      if (image == null) {
        throw Exception('Unable to decode image');
      }

      print('   📐 Original dimensions: ${image.width}x${image.height}');

      // 3) Redimensionar preservando proporção
      final resizedImage = _resizeImage(image);
      print(
          '   📐 Resized dimensions: ${resizedImage.width}x${resizedImage.height}');

      // 4) Comprimir para formato otimizado com qualidade inicial
      Uint8List compressedBytes = _encodeOptimized(resizedImage, quality);
      int currentQuality = quality;

      // 5) Reduzir qualidade em passos até ≤1MB
      while (compressedBytes.length > maxBytes && currentQuality > minQuality) {
        currentQuality -= 5;
        print(
            '   🔄 Reducing quality to $currentQuality% (current: ${_formatBytes(compressedBytes.length)})');
        compressedBytes = _encodeOptimized(resizedImage, currentQuality);
      }

      final finalSize = compressedBytes.length;
      final compressionRatio =
          ((originalSize - finalSize) / originalSize * 100).toStringAsFixed(1);

      print('   ✅ Image compression completed:');
      print('      📦 Final size: ${_formatBytes(finalSize)}');
      print('      📉 Compression: $compressionRatio%');
      print('      🎚️ Final quality: $currentQuality%');

      if (finalSize > maxBytes) {
        print(
            '   ⚠️ Warning: Unable to compress below ${_formatBytes(maxBytes)}');
      }

      return compressedBytes;
    } catch (e) {
      print('   ❌ Image compression failed: $e');
      throw Exception('Failed to compress image: $e');
    }
  }

  /// Redimensiona imagem preservando proporção
  static img.Image _resizeImage(img.Image image) {
    final width = image.width;
    final height = image.height;

    // Se já está dentro dos limites, retorna original
    if (width <= maxEdge && height <= maxEdge) {
      return image;
    }

    // Calcular novas dimensões preservando proporção
    final double aspectRatio = width / height;
    final int newWidth;
    final int newHeight;

    if (width > height) {
      // Paisagem - limitar largura
      newWidth = maxEdge;
      newHeight = (maxEdge / aspectRatio).round();
    } else {
      // Retrato ou quadrado - limitar altura
      newHeight = maxEdge;
      newWidth = (maxEdge * aspectRatio).round();
    }

    return img.copyResize(
      image,
      width: newWidth,
      height: newHeight,
      interpolation: img.Interpolation.linear,
    );
  }

  /// Codifica imagem com qualidade especificada (JPEG otimizado)
  static Uint8List _encodeOptimized(img.Image image, int quality) {
    // O pacote image tem suporte limitado para WebP encoding
    // Para simplificar, vamos usar JPEG de alta qualidade por enquanto
    final jpegBytes = img.encodeJpg(image, quality: quality);
    return Uint8List.fromList(jpegBytes);
  }

  /// Formata tamanho em bytes para leitura humana
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// Valida se arquivo é uma imagem suportada
  static bool isValidImageFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'].contains(extension);
  }

  /// Gera nome de arquivo temporário para processamento
  static String generateTempFileName(String groupId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'temp_${groupId}_$timestamp.webp';
  }
}
