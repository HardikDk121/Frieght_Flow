import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/bilty.dart';
import '../core/services/app_data_store.dart';
import '../core/services/firestore_service.dart';

class BiltyProvider extends ChangeNotifier {
  final AppDataStore     _store     = AppDataStore.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  List<Bilty> _bilties  = [];
  bool        _loading  = false;
  bool        _useCloud = false;
  String?     _error;

  StreamSubscription<List<Bilty>>? _sub;

  List<Bilty> get bilties        => _bilties;
  List<Bilty> get pendingBilties => _bilties.where((b) => b.isPending).toList();
  bool        get isLoading      => _loading;
  String?     get error          => _error;

  void load() {
    _bilties = _store.getBilties();
    notifyListeners();
  }

  void enableCloud(String userId) {
    // Always cancel existing subscription first (handles re-login)
    _sub?.cancel();
    _useCloud = true;

    _sub = _firestore.watchBilties(userId).listen(
      (list) { _bilties = list; _error = null; notifyListeners(); },
      onError: (e) { _error = 'Bilties stream error: $e'; debugPrint(_error); notifyListeners(); },
    );
  }

  /// Called on logout — cancels stream and clears data
  void resetCloud() {
    _sub?.cancel();
    _sub = null;
    _bilties = [];
    _useCloud = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  List<Bilty> pendingBiltiesForRoute(String routeId) =>
      _bilties.where((b) => b.isPending && b.routeId == routeId).toList();

  Bilty? getBiltyById(String id) =>
      _bilties.where((b) => b.id == id).firstOrNull;

  Future<bool> addBilty({
    required String routeId,
    required String consignorName, required String consignorPhone,
    String consignorGst = '',
    required String consigneeName, required String consigneePhone,
    String consigneeGst = '',
    required String consigneeCity, required String goodsDescription,
    required String goodsCategory, required double weightKg,
    required int    noOfPackages,  required double freightPerKg,
    required PaymentType paymentType, required String createdBy,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final bilty = Bilty(
        id: _store.uid(), userId: createdBy, biltyNo: _store.biltyNo(), routeId: routeId,
        consignorName: consignorName, consignorPhone: consignorPhone,
        consignorGst: consignorGst, consigneeName: consigneeName,
        consigneePhone: consigneePhone, consigneeGst: consigneeGst,
        consigneeCity: consigneeCity, goodsDescription: goodsDescription,
        goodsCategory: goodsCategory, weightKg: weightKg,
        noOfPackages: noOfPackages, freightPerKg: freightPerKg,
        paymentType: paymentType, createdAt: DateTime.now(), createdBy: createdBy,
      );
      if (_useCloud) {
        await _firestore.addBilty(bilty);
        // Stream will auto-update _bilties
      } else {
        await _store.addBilty(bilty);
        _bilties = _store.getBilties();
      }
      _loading = false; notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false; notifyListeners();
      return false;
    }
  }

  void refresh() {
    if (!_useCloud) { _bilties = _store.getBilties(); notifyListeners(); }
  }
}
