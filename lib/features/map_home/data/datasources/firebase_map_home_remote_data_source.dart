import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../domain/entities/globe_marker_entity.dart';
import '../../domain/entities/map_home_region_entity.dart';
import '../../domain/entities/place_entity.dart';
import '../mappers/map_home_firestore_mapper.dart';
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

  bool _hasValidCoordinates(Map<String, dynamic> data) {
    return data['latitude'] != null && data['longitude'] != null;
  }

  bool _hasValidPlaceId(Map<String, dynamic> data) {
    final value = (data['placeId'] as String?)?.trim();
    return value != null && value.isNotEmpty;
  }
}
