import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/map_home_region_entity.dart';
import '../../domain/entities/place_detail_sections_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../mappers/map_home_firestore_mapper.dart';
import '../utils/map_home_firestore_utils.dart';
import 'map_home_remote_data_source.dart';

class FirebaseMapHomeRemoteDataSource implements MapHomeRemoteDataSource {
  FirebaseMapHomeRemoteDataSource({required this.firestore});

  final FirebaseFirestore firestore;

  @override
  Future<List<PlaceEntity>> getPlaces() async {
    try {
      final snapshot = await firestore.collection('places').get();
      final places = <PlaceEntity>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (!_hasValidCoordinates(data)) {
            debugPrint('Skip place doc ${doc.id}: missing coordinates');
            continue;
          }
          places.add(mapPlaceEntityFromFirestore(doc.id, data));
        } catch (error) {
          debugPrint('Skip invalid place doc ${doc.id}: $error');
        }
      }
      return places;
    } catch (error) {
      // Firestore 不可用时先返回空列表，避免地图主流程被单点失败拖垮。
      debugPrint('Load places failed: $error');
      return <PlaceEntity>[];
    }
  }

  @override
  Future<List<GlobeMarkerEntity>> getMarkers() async {
    try {
      final snapshot = await firestore.collection('markers').get();
      final markers = <GlobeMarkerEntity>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          if (!_hasValidPlaceId(data)) {
            debugPrint('Skip marker doc ${doc.id}: missing placeId');
            continue;
          }
          markers.add(mapGlobeMarkerEntityFromFirestore(doc.id, data));
        } catch (error) {
          debugPrint('Skip invalid marker doc ${doc.id}: $error');
        }
      }
      return markers;
    } catch (error) {
      debugPrint('Load markers failed: $error');
      return <GlobeMarkerEntity>[];
    }
  }

  @override
  Future<List<MapHomeRegionEntity>> getRegions() async {
    try {
      final snapshot = await firestore.collection('regions').get();
      final regions = <MapHomeRegionEntity>[];
      for (final doc in snapshot.docs) {
        try {
          regions.add(mapRegionEntityFromFirestore(doc.id, doc.data()));
        } catch (error) {
          debugPrint('Skip invalid region doc ${doc.id}: $error');
        }
      }
      return regions;
    } catch (error) {
      debugPrint('Load regions failed: $error');
      return <MapHomeRegionEntity>[];
    }
  }

  @override
  Future<PlaceDetailSectionsEntity?> getPlaceDetailSections(
    String placeId,
  ) async {
    final trimmedPlaceId = placeId.trim();
    debugPrint('[PlaceDetail] load started placeId=$trimmedPlaceId');
    if (trimmedPlaceId.isEmpty) {
      debugPrint('[PlaceDetail] root place loaded=false');
      return null;
    }

    try {
      final placeRef = firestore.collection('places').doc(trimmedPlaceId);
      final placeDoc = await placeRef.get();
      if (!placeDoc.exists || placeDoc.data() == null) {
        debugPrint('[PlaceDetail] root place loaded=false');
        return null;
      }
      debugPrint('[PlaceDetail] root place loaded=true');

      final place = mapPlaceEntityFromFirestore(placeDoc.id, placeDoc.data()!);
      final results = await Future.wait<dynamic>(<Future<dynamic>>[
        _loadExperiences(placeRef),
        _loadFlavors(placeRef),
        _loadStays(placeRef),
        _loadGallery(placeRef),
      ]);

      final experiences = results[0] as List<PlaceExperienceEntity>;
      final flavors = results[1] as List<PlaceFlavorEntity>;
      final stays = results[2] as List<PlaceStayEntity>;
      final gallery = results[3] as List<PlaceGalleryEntity>;

      debugPrint('[PlaceDetail] experiences count=${experiences.length}');
      debugPrint('[PlaceDetail] flavors count=${flavors.length}');
      debugPrint('[PlaceDetail] stays count=${stays.length}');
      debugPrint('[PlaceDetail] gallery count=${gallery.length}');

      return PlaceDetailSectionsEntity(
        place: place,
        experiences: experiences,
        flavors: flavors,
        stays: stays,
        gallery: gallery,
      );
    } catch (error) {
      debugPrint('[PlaceDetail] load failed error=$error');
      return null;
    }
  }

  bool _hasValidCoordinates(Map<String, dynamic> data) {
    return data['latitude'] != null && data['longitude'] != null;
  }

  bool _hasValidPlaceId(Map<String, dynamic> data) {
    final value = (data['placeId'] as String?)?.trim();
    return value != null && value.isNotEmpty;
  }

  Future<List<PlaceExperienceEntity>> _loadExperiences(
    DocumentReference<Map<String, dynamic>> placeRef,
  ) async {
    try {
      final snapshot = await placeRef.collection('experiences').get();
      final items = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return PlaceExperienceEntity(
              title: readLanguageMap(data['title']),
              badge: readLanguageMap(data['badge']),
              order: _readOrder(data),
              enabled: _readEnabled(data),
            );
          })
          .where((item) => item.enabled)
          .toList(growable: false);
      items.sort((a, b) => a.order.compareTo(b.order));
      return items;
    } catch (error) {
      debugPrint(
        '[PlaceDetail] experiences read failed error=$error '
        '(check rules: /places/{placeId}/experiences)',
      );
      return const <PlaceExperienceEntity>[];
    }
  }

  Future<List<PlaceFlavorEntity>> _loadFlavors(
    DocumentReference<Map<String, dynamic>> placeRef,
  ) async {
    try {
      final snapshot = await placeRef.collection('flavors').get();
      final items = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return PlaceFlavorEntity(
              name: readLanguageMap(data['name']),
              subtitle: readLanguageMap(data['subtitle']),
              imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
              order: _readOrder(data),
              enabled: _readEnabled(data),
            );
          })
          .where((item) => item.enabled)
          .toList(growable: false);
      items.sort((a, b) => a.order.compareTo(b.order));
      return items;
    } catch (error) {
      debugPrint(
        '[PlaceDetail] flavors read failed error=$error '
        '(check rules: /places/{placeId}/flavors)',
      );
      return const <PlaceFlavorEntity>[];
    }
  }

  Future<List<PlaceStayEntity>> _loadStays(
    DocumentReference<Map<String, dynamic>> placeRef,
  ) async {
    try {
      final snapshot = await placeRef.collection('stays').get();
      final items = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return PlaceStayEntity(
              name: readLanguageMap(data['name']),
              badge: readLanguageMap(data['badge']),
              imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
              priceRange: (data['priceRange'] as String?)?.trim() ?? '',
              order: _readOrder(data),
              enabled: _readEnabled(data),
            );
          })
          .where((item) => item.enabled)
          .toList(growable: false);
      items.sort((a, b) => a.order.compareTo(b.order));
      return items;
    } catch (error) {
      debugPrint(
        '[PlaceDetail] stays read failed error=$error '
        '(check rules: /places/{placeId}/stays)',
      );
      return const <PlaceStayEntity>[];
    }
  }

  Future<List<PlaceGalleryEntity>> _loadGallery(
    DocumentReference<Map<String, dynamic>> placeRef,
  ) async {
    try {
      final snapshot = await placeRef.collection('gallery').get();
      final items = snapshot.docs
          .map((doc) {
            final data = doc.data();
            return PlaceGalleryEntity(
              imageUrl: (data['imageUrl'] as String?)?.trim() ?? '',
              caption: readLanguageMap(data['caption']),
              order: _readOrder(data),
              enabled: _readEnabled(data),
            );
          })
          .where((item) => item.enabled && item.imageUrl.isNotEmpty)
          .toList(growable: false);
      items.sort((a, b) => a.order.compareTo(b.order));
      return items;
    } catch (error) {
      debugPrint(
        '[PlaceDetail] gallery read failed error=$error '
        '(check rules: /places/{placeId}/gallery)',
      );
      return const <PlaceGalleryEntity>[];
    }
  }

  int _readOrder(Map<String, dynamic> data) {
    final fromOrder = data['order'];
    if (fromOrder is num) {
      return fromOrder.toInt();
    }
    final fromDisplayOrder = data['displayOrder'];
    if (fromDisplayOrder is num) {
      return fromDisplayOrder.toInt();
    }
    return 0;
  }

  bool _readEnabled(Map<String, dynamic> data) {
    final enabled = data['enabled'];
    if (enabled is bool) {
      return enabled;
    }
    return true;
  }
}
