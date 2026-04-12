import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/bilty.dart';
import '../core/models/challan.dart';
import '../core/services/app_data_store.dart';
import '../core/services/firestore_service.dart';

class ChallanProvider extends ChangeNotifier {
  final AppDataStore     _store     = AppDataStore.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  List<Challan> _challans  = [];
  bool          _loading   = false;
  bool          _useCloud  = false;
  String?       _error;

  String?      _selectedRouteId;
  List<String> _selectedBiltyIds = [];

  StreamSubscription<List<Challan>>? _sub;

  List<Challan> get challans         => _challans;
  List<Challan> get openChallans     =>
      _challans.where((c) => c.status == ChallanStatus.open).toList();
  bool          get isLoading        => _loading;
  String?       get error            => _error;
  String?       get selectedRouteId  => _selectedRouteId;
  List<String>  get selectedBiltyIds => List.unmodifiable(_selectedBiltyIds);
  bool          get canCreateChallan =>
      _selectedBiltyIds.isNotEmpty && _selectedRouteId != null;

  void load() { _challans = _store.getChallans(); notifyListeners(); }

  void enableCloud(String userId) {
    // Always cancel existing subscription first (handles re-login)
    _sub?.cancel();
    _useCloud = true;

    _sub = _firestore.watchChallans(userId).listen(
      (list) { _challans = list; _error = null; notifyListeners(); },
      onError: (e) { _error = 'Challans stream error: $e'; debugPrint(_error); notifyListeners(); },
    );
  }

  /// Called on logout — cancels stream and clears data
  void resetCloud() {
    _sub?.cancel();
    _sub = null;
    _challans = [];
    _selectedRouteId = null;
    _selectedBiltyIds = [];
    _useCloud = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  Challan? getChallanById(String id) =>
      _challans.where((c) => c.id == id).firstOrNull;

  List<Bilty> getBiltiesForChallan(Challan challan) {
    // Look up bilties from the in-memory store for now
    final biltyStore = AppDataStore.instance;
    return challan.biltyIds
        .map((id) => biltyStore.getBilty(id))
        .whereType<Bilty>()
        .toList();
  }

  void setRouteFilter(String routeId) {
    _selectedRouteId = routeId;
    _selectedBiltyIds.clear();
    notifyListeners();
  }

  void toggleBiltySelection(String biltyId) {
    if (_selectedBiltyIds.contains(biltyId)) {
      _selectedBiltyIds.remove(biltyId);
    } else {
      _selectedBiltyIds.add(biltyId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedRouteId = null;
    _selectedBiltyIds = [];
    notifyListeners();
  }

  Future<Challan?> createChallanWithTruck({
    required List<String> biltyIds, required String routeId,
    required String truckId,        required String createdBy,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final challan = Challan(
        id: _store.uid(), userId: createdBy, challanNo: _store.challanNo(),
        routeId: routeId, biltyIds: biltyIds, truckId: truckId,
        createdAt: DateTime.now(), createdBy: createdBy,
      );
      if (_useCloud) {
        await _firestore.addChallan(challan, biltyIds);
      } else {
        await _store.addChallan(challan);
        _challans = _store.getChallans();
      }
      clearSelection();
      _loading = false; notifyListeners();
      return challan;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false; notifyListeners();
      return null;
    }
  }

  Future<Challan?> createChallan({required String createdBy}) async {
    if (!canCreateChallan) return null;
    return createChallanWithTruck(
      biltyIds: List.from(_selectedBiltyIds),
      routeId: _selectedRouteId!,
      truckId: '',
      createdBy: createdBy,
    );
  }

  void refresh() {
    if (!_useCloud) { _challans = _store.getChallans(); notifyListeners(); }
  }
}
