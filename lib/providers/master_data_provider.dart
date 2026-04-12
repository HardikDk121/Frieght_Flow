import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/driver.dart';
import '../core/models/freight_route.dart';
import '../core/models/truck.dart';
import '../core/services/app_data_store.dart';
import '../core/services/firestore_service.dart';

class MasterDataProvider extends ChangeNotifier {
  final AppDataStore    _store     = AppDataStore.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  List<Truck>        _trucks  = [];
  List<Driver>       _drivers = [];
  List<FreightRoute> _routes  = [];
  bool    _loading  = false;
  bool    _useCloud = false;
  String? _error;

  StreamSubscription<List<Truck>>?        _truckSub;
  StreamSubscription<List<Driver>>?       _driverSub;
  StreamSubscription<List<FreightRoute>>? _routeSub;

  List<Truck>        get trucks          => _trucks;
  List<Driver>       get drivers         => _drivers;
  List<FreightRoute> get routes          => _routes;
  bool               get isLoading       => _loading;
  String?            get error           => _error;
  bool               get isCloudEnabled  => _useCloud;

  List<Truck>  get availableTrucks  =>
      _trucks.where((t) => t.status == TruckStatus.available).toList();
  List<Driver> get availableDrivers =>
      _drivers.where((d) => d.isAvailable).toList();

  // ── Local in-memory (default) ─────────────────────────────────────────────
  void load() {
    _trucks  = _store.getTrucks();
    _drivers = _store.getDrivers();
    _routes  = _store.getRoutes();
    notifyListeners();
  }

  // ── Firestore streaming (userId-scoped) ───────────────────────────────────
  void enableCloud(String userId) {
    // Cancel any existing subscriptions first (handles re-login with different user)
    _truckSub?.cancel();
    _driverSub?.cancel();
    _routeSub?.cancel();
    _useCloud = true;

    _truckSub = _firestore.watchTrucks(userId).listen(
      (list) { _trucks = list; _error = null; notifyListeners(); },
      onError: (e) { _error = 'Trucks stream error: $e'; debugPrint(_error); notifyListeners(); },
    );
    _driverSub = _firestore.watchDrivers(userId).listen(
      (list) { _drivers = list; _error = null; notifyListeners(); },
      onError: (e) { _error = 'Drivers stream error: $e'; debugPrint(_error); notifyListeners(); },
    );
    _routeSub = _firestore.watchRoutes(userId).listen(
      (list) { _routes = list; _error = null; notifyListeners(); },
      onError: (e) { _error = 'Routes stream error: $e'; debugPrint(_error); notifyListeners(); },
    );
  }

  /// Called on logout — cancels streams and clears data
  void resetCloud() {
    _truckSub?.cancel();
    _driverSub?.cancel();
    _routeSub?.cancel();
    _truckSub = null;
    _driverSub = null;
    _routeSub = null;
    _trucks = [];
    _drivers = [];
    _routes = [];
    _useCloud = false;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _truckSub?.cancel();
    _driverSub?.cancel();
    _routeSub?.cancel();
    super.dispose();
  }

  // ── Lookup helpers ────────────────────────────────────────────────────────
  FreightRoute? routeById(String id) =>
      _routes.where((r) => r.id == id).firstOrNull;
  Truck?  truckById(String id)  =>
      _trucks.where((t) => t.id == id).firstOrNull;
  Driver? driverById(String id) =>
      _drivers.where((d) => d.id == id).firstOrNull;

  // ── Trucks ────────────────────────────────────────────────────────────────
  Future<void> addTruck({
    required String vehicleNo, required String make,
    required String model,     required double capacityKg,
    required String userId,
  }) async {
    _loading = true; notifyListeners();
    try {
      final truck = Truck(
        id: _store.uid(), userId: userId, vehicleNo: vehicleNo.toUpperCase(),
        make: make, model: model, capacityKg: capacityKg,
        createdAt: DateTime.now(),
      );
      if (_useCloud) {
        await _firestore.addTruck(truck);
      } else {
        await _store.addTruck(truck);
        _trucks = _store.getTrucks();
      }
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> updateTruckStatus(String id, TruckStatus status) async {
    final truck = truckById(id);
    if (truck == null) return;
    final updated = truck.copyWith(status: status);
    if (_useCloud) {
      await _firestore.updateTruck(updated);
    } else {
      await _store.updateTruck(updated);
      _trucks = _store.getTrucks();
      notifyListeners();
    }
  }

  Future<void> deleteTruck(String id) async {
    if (_useCloud) {
      await _firestore.deleteTruck(id);
    } else {
      await _store.deleteTruck(id);
      _trucks = _store.getTrucks();
      notifyListeners();
    }
  }

  // ── Drivers ───────────────────────────────────────────────────────────────
  Future<void> addDriver({
    required String name, required String licenseNo, required String phone,
    required String userId,
  }) async {
    _loading = true; notifyListeners();
    try {
      final driver = Driver(
        id: _store.uid(), userId: userId, name: name, licenseNo: licenseNo,
        phone: phone, createdAt: DateTime.now(),
      );
      if (_useCloud) {
        await _firestore.addDriver(driver);
      } else {
        await _store.addDriver(driver);
        _drivers = _store.getDrivers();
      }
    } finally {
      _loading = false; notifyListeners();
    }
  }

  Future<void> deleteDriver(String id) async {
    if (_useCloud) {
      await _firestore.deleteDriver(id);
    } else {
      await _store.deleteDriver(id);
      _drivers = _store.getDrivers();
      notifyListeners();
    }
  }

  // ── Routes ────────────────────────────────────────────────────────────────
  Future<void> addRoute({
    required String origin, required String destination,
    required double distanceKm, required double baseRatePerKg,
    required String userId,
  }) async {
    _loading = true; notifyListeners();
    try {
      final route = FreightRoute(
        id: _store.uid(), userId: userId, origin: origin, destination: destination,
        distanceKm: distanceKm, baseRatePerKg: baseRatePerKg,
        createdAt: DateTime.now(),
      );
      if (_useCloud) {
        await _firestore.addRoute(route);
      } else {
        await _store.addRoute(route);
        _routes = _store.getRoutes();
      }
    } finally {
      _loading = false; notifyListeners();
    }
  }
}
