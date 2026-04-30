import 'package:flutter/foundation.dart';

import '../../domain/entities/checklist_destination_snapshot.dart';
import '../../domain/entities/checklist_item.dart';
import '../../domain/repositories/checklist_repository.dart';

class ChecklistController extends ChangeNotifier {
  ChecklistController({required this.repository});

  final ChecklistRepository repository;

  bool _isLoading = false;
  bool _isDeleting = false;
  String? _errorKey;
  List<ChecklistItem> _items = const <ChecklistItem>[];

  bool get isLoading => _isLoading;
  bool get isDeleting => _isDeleting;
  String? get errorKey => _errorKey;
  List<ChecklistItem> get items => _items;

  Future<void> load() async {
    final stopwatch = Stopwatch()..start();
    final cachedCount = _items.length;
    debugPrint('[MyTrips] controller load started cachedCount=$cachedCount');
    _isLoading = true;
    _errorKey = null;
    notifyListeners();
    try {
      _items = await repository.getMyChecklists();
      debugPrint(
        '[MyTrips] controller load completed '
        'count=${_items.length} elapsed=${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (_) {
      _errorKey = 'checklistLoadFailed';
      debugPrint(
        '[MyTrips] controller load failed '
        'elapsed=${stopwatch.elapsedMilliseconds}ms',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> createChecklistFromPlace({
    required String placeId,
    required String destination,
    String? coverImageUrl,
    Map<String, String>? destinationNames,
    ChecklistDestinationSnapshot? destinationSnapshot,
  }) async {
    _errorKey = null;
    notifyListeners();
    try {
      final checklistId = await repository.createChecklistFromPlace(
        placeId: placeId,
        destination: destination,
        coverImageUrl: coverImageUrl,
        destinationNames: destinationNames,
        destinationSnapshot: destinationSnapshot,
      );
      await load();
      return checklistId;
    } catch (_) {
      _errorKey = 'checklistCreateFailed';
      notifyListeners();
      return null;
    }
  }

  Future<String?> createChecklistFromDestinationSnapshot({
    required ChecklistDestinationSnapshot destinationSnapshot,
    Map<String, String>? destinationNames,
  }) async {
    _errorKey = null;
    notifyListeners();
    try {
      final checklistId = await repository
          .createChecklistFromDestinationSnapshot(
            destinationSnapshot: destinationSnapshot,
            destinationNames: destinationNames,
          );
      await load();
      return checklistId;
    } catch (_) {
      _errorKey = 'checklistCreateFailed';
      notifyListeners();
      return null;
    }
  }

  Future<bool> deleteChecklist(String checklistId) async {
    _isDeleting = true;
    _errorKey = null;
    notifyListeners();
    try {
      await repository.deleteChecklist(checklistId);
      await load();
      return true;
    } catch (_) {
      _errorKey = 'checklistDeleteFailed';
      notifyListeners();
      return false;
    } finally {
      _isDeleting = false;
      notifyListeners();
    }
  }
}
