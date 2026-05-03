import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// 统一图片磁盘缓存管理器：集中控制缓存 key、时长和数量上限。
class AppImageCacheManager extends CacheManager with ImageCacheManager {
  AppImageCacheManager._()
    : super(
        Config(
          cacheKey,
          stalePeriod: const Duration(days: 14),
          maxNrOfCacheObjects: 300,
        ),
      );

  static const String cacheKey = 'wandering_image_cache';
  static AppImageCacheManager? _instance;

  static AppImageCacheManager get instance {
    return _instance ??= AppImageCacheManager._();
  }
}
