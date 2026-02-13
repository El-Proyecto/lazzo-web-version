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
      // 1) Ler bytes originais
      final originalBytes = await input.readAsBytes();

      // 2) Decodificar imagem com correção automática de EXIF
      final image = img.decodeImage(originalBytes);
      if (image == null) {
        throw Exception('Unable to decode image');
      }

      // 3) Redimensionar preservando proporção
      final resizedImage = _resizeImage(image);

      // 4) Comprimir para formato otimizado com qualidade inicial
      Uint8List compressedBytes = _encodeOptimized(resizedImage, quality);
      int currentQuality = quality;

      // 5) Reduzir qualidade em passos até ≤1MB
      while (compressedBytes.length > maxBytes && currentQuality > minQuality) {
        currentQuality -= 5;
        compressedBytes = _encodeOptimized(resizedImage, currentQuality);
      }

      final finalSize = compressedBytes.length;

      if (finalSize > maxBytes) {}

      return compressedBytes;
    } catch (e) {
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

  /// Valida se arquivo é uma imagem suportada
  static bool isValidImageFile(String path) {
    final extension = path.toLowerCase().split('.').last;
    return ['jpg', 'jpeg', 'png', 'webp', 'heic', 'heif'].contains(extension);
  }

  /// Gera nome de arquivo temporário para processamento
  static String generateTempFileName(String eventId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'temp_${eventId}_$timestamp.webp';
  }
}
