import 'package:supabase_flutter/supabase_flutter.dart';

/// Cache service for avatar signed URLs
/// Prevents redundant storage calls for the same avatars
///
/// Features:
/// - In-memory cache with expiry (50min, URLs valid for 1h)
/// - Batch processing: fetch multiple URLs in parallel
/// - Automatic cache cleanup for expired entries
class AvatarCacheService {
  static final AvatarCacheService _instance = AvatarCacheService._internal();
  factory AvatarCacheService() => _instance;
  AvatarCacheService._internal();

  static const String _avatarBucketName = 'users-profile-pic';
  static const int _cacheExpirySeconds =
      3000; // 50min (signed URLs valid for 1h)

  // Cache: storage_path -> (url, expiry_time)
  final Map<String, _CacheEntry> _cache = {};

  /// Get authenticated avatar URL with caching
  /// Returns empty string if path is null/empty or already a full URL
  Future<String> getAvatarUrl(
    SupabaseClient client,
    String? storagePath,
  ) async {
    if (storagePath == null || storagePath.isEmpty) return '';

    // Already a full URL
    if (storagePath.startsWith('http://') ||
        storagePath.startsWith('https://')) {
      return storagePath;
    }

    // Normalize path (remove leading slash if present)
    final normalizedPath =
        storagePath.startsWith('/') ? storagePath.substring(1) : storagePath;

    // Check cache
    final cached = _cache[normalizedPath];
    if (cached != null && !cached.isExpired) {
      return cached.url;
    }

    // Fetch from storage
    try {
      final url = await client.storage
          .from(_avatarBucketName)
          .createSignedUrl(normalizedPath, 3600);

      // Store in cache
      _cache[normalizedPath] = _CacheEntry(
        url: url,
        expiryTime:
            DateTime.now().add(const Duration(seconds: _cacheExpirySeconds)),
      );

      return url;
    } catch (e) {
      return '';
    }
  }

  /// Batch process multiple avatar paths in parallel
  /// Returns map: original_storage_path -> signed_url
  ///
  /// This is much more efficient than calling getAvatarUrl() in a loop
  /// because it:
  /// 1. Checks cache first for all paths
  /// 2. Fetches only uncached URLs in parallel
  /// 3. Updates cache for newly fetched URLs
  Future<Map<String, String>> batchGetAvatarUrls(
    SupabaseClient client,
    List<String> storagePaths,
  ) async {
    final result = <String, String>{};
    final pathsToFetch = <String, String>{}; // normalized -> original

    // Check cache first
    for (final path in storagePaths) {
      if (path.isEmpty) continue;

      // Skip if already a full URL
      if (path.startsWith('http://') || path.startsWith('https://')) {
        result[path] = path;
        continue;
      }

      final normalizedPath = path.startsWith('/') ? path.substring(1) : path;
      final cached = _cache[normalizedPath];

      if (cached != null && !cached.isExpired) {
        result[path] = cached.url;
      } else {
        pathsToFetch[normalizedPath] = path;
      }
    }

    // Fetch uncached URLs in parallel
    if (pathsToFetch.isNotEmpty) {
      final futures = pathsToFetch.keys.map((normalizedPath) async {
        try {
          final url = await client.storage
              .from(_avatarBucketName)
              .createSignedUrl(normalizedPath, 3600);

          _cache[normalizedPath] = _CacheEntry(
            url: url,
            expiryTime: DateTime.now()
                .add(const Duration(seconds: _cacheExpirySeconds)),
          );

          return MapEntry(normalizedPath, url);
        } catch (e) {
          return MapEntry(normalizedPath, '');
        }
      });

      final fetchedUrls = await Future.wait(futures);

      // Map back to original paths
      for (final entry in fetchedUrls) {
        final originalPath = pathsToFetch[entry.key]!;
        result[originalPath] = entry.value;
      }
    }

    return result;
  }

  /// Clear expired entries (call periodically)
  void clearExpired() {
    _cache.removeWhere((_, entry) => entry.isExpired);
  }

  /// Clear specific path from cache (forces refresh on next load)
  /// Useful when user updates their profile photo
  void clearPath(String? storagePath) {
    if (storagePath == null || storagePath.isEmpty) return;
    final normalizedPath =
        storagePath.startsWith('/') ? storagePath.substring(1) : storagePath;
    _cache.remove(normalizedPath);
  }

  /// Clear all cache (for testing/logout)
  void clearAll() {
    _cache.clear();
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getStats() {
    final expired = _cache.values.where((e) => e.isExpired).length;
    return {
      'total': _cache.length,
      'active': _cache.length - expired,
      'expired': expired,
    };
  }
}

/// Internal cache entry with expiry tracking
class _CacheEntry {
  final String url;
  final DateTime expiryTime;

  _CacheEntry({required this.url, required this.expiryTime});

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}
