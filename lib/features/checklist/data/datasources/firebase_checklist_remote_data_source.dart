import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../../core/error/app_exception.dart';
import '../../domain/entities/checklist_item.dart';
import 'checklist_remote_data_source.dart';

class FirebaseChecklistRemoteDataSource implements ChecklistRemoteDataSource {
  FirebaseChecklistRemoteDataSource({
    required this.firestore,
    required this.firebaseAuth,
  });

  final FirebaseFirestore firestore;
  final FirebaseAuth firebaseAuth;

  @override
  Future<List<ChecklistItem>> getMyChecklists() async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null || userId.trim().isEmpty) {
        return const <ChecklistItem>[];
      }

      final snapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('checklists')
          .get();

      final items = snapshot.docs
          .map((doc) => _mapChecklistItem(doc.id, doc.data()))
          .toList(growable: false);

      if (items.isEmpty) {
        return const <ChecklistItem>[];
      }

      final coverImageMap = await _loadCoverImages(
        items
            .map((item) => item.placeId.trim())
            .where((placeId) => placeId.isNotEmpty)
            .toSet(),
      );

      final enrichedItems = items
          .map(
            (item) => item.copyWith(
              coverImageUrl:
                  coverImageMap[item.placeId.trim()] ??
                  item.coverImageUrl.trim(),
            ),
          )
          .toList(growable: false);

      enrichedItems.sort((left, right) {
        final leftDate =
            left.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final rightDate =
            right.startDate ?? DateTime.fromMillisecondsSinceEpoch(0);
        final dateCompare = leftDate.compareTo(rightDate);
        if (dateCompare != 0) {
          return dateCompare;
        }
        return left.destination.compareTo(right.destination);
      });
      return enrichedItems;
    } catch (_) {
      throw AppException('checklist_load_failed');
    }
  }

  @override
  Future<String> createChecklistFromPlace({
    required String placeId,
    required String destination,
    String? coverImageUrl,
  }) async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null || userId.trim().isEmpty) {
        throw AppException('checklist_create_failed');
      }

      final trimmedPlaceId = placeId.trim();
      final trimmedDestination = destination.trim();
      final trimmedCoverImageUrl = coverImageUrl?.trim() ?? '';
      final ref = firestore
          .collection('users')
          .doc(userId)
          .collection('checklists')
          .doc();

      // 基于当前 place 创建行程清单，字段结构与后续正式数据保持一致。
      await ref.set(<String, dynamic>{
        'placeId': trimmedPlaceId,
        'destination': trimmedDestination,
        'coverImageUrl': trimmedCoverImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
        'totalBudget': null,
        'aiGenerated': false,
      });

      return ref.id;
    } catch (_) {
      throw AppException('checklist_create_failed');
    }
  }

  @override
  Future<void> deleteChecklist(String checklistId) async {
    try {
      final userId = firebaseAuth.currentUser?.uid;
      if (userId == null || userId.trim().isEmpty) {
        throw AppException('checklist_delete_failed');
      }

      await firestore
          .collection('users')
          .doc(userId)
          .collection('checklists')
          .doc(checklistId)
          .delete();
    } catch (_) {
      throw AppException('checklist_delete_failed');
    }
  }

  ChecklistItem _mapChecklistItem(String id, Map<String, dynamic> data) {
    return ChecklistItem(
      id: id,
      destination: (data['destination'] as String?)?.trim() ?? '',
      placeId: (data['placeId'] as String?)?.trim() ?? '',
      coverImageUrl: (data['coverImageUrl'] as String?)?.trim() ?? '',
      startDate: _readDateTime(data['startDate']),
      endDate: _readDateTime(data['endDate']),
      statusText: (data['statusText'] as String?)?.trim(),
    );
  }

  Future<Map<String, String>> _loadCoverImages(Set<String> placeIds) async {
    if (placeIds.isEmpty) {
      return const <String, String>{};
    }

    final result = <String, String>{};
    final docs = await Future.wait(
      placeIds.map(
        (placeId) => firestore.collection('places').doc(placeId).get(),
      ),
    );

    for (final doc in docs) {
      if (!doc.exists) {
        continue;
      }
      final data = doc.data();
      if (data == null) {
        continue;
      }

      final coverImage =
          (data['coverImage'] as String?)?.trim() ??
          (data['previewAssetPath'] as String?)?.trim() ??
          '';
      if (coverImage.isNotEmpty) {
        result[doc.id] = coverImage;
      }
    }

    return result;
  }

  DateTime? _readDateTime(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value.trim());
    }
    return null;
  }
}
