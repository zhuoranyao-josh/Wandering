import 'package:flutter/painting.dart';

import 'app_image_cache_manager.dart';

/// 统一缓存服务：当前负责图片磁盘缓存与 Flutter 内存图片缓存清理。
class AppCacheService {
  const AppCacheService._();

  static Future<int> getImageCacheSizeBytes() {
    return AppImageCacheManager.instance.store.getCacheSize();
  }

  static Future<void> clearImageCache() async {
    await AppImageCacheManager.instance.emptyCache();
    imageCache.clear();
    imageCache.clearLiveImages();
  }
}
