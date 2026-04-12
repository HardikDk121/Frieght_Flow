import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/bilty.dart';
import '../core/models/challan.dart';
import '../core/models/driver.dart';
import '../core/models/freight_route.dart';
import '../core/models/trip.dart';
import '../core/models/truck.dart';
import '../core/services/app_data_store.dart';
import '../core/services/firestore_service.dart';
import '../core/services/location_service.dart';

class TripManagementProvider extends ChangeNotifier {
  final AppDataStore     _store     = AppDataStore.instance;
  final FirestoreService _firestore = FirestoreService.instance;

  List<Trip> _trips    = [];
  bool       _loading  = false;
  bool       _useCloud = false;
  String?    _error;
  String?    _successMsg;

  StreamSubscription<List<Trip>>? _sub;

  List<Trip> get trips       => _trips;
  bool        get isLoading  => _loading;
  String?     get error      => _error;
  String?     get successMsg => _successMsg;
  bool        get isCloudEnabled => _useCloud;

  List<Trip> get activeTrips =>
      _trips.where((t) => !TripStateHelper.isTerminal(t.state)).toList();
  List<Trip> get completedTrips =>
      _trips.where((t) => t.state == TripState.delivered).toList();

  void load() { _trips = _store.getTrips(); notifyListeners(); }

  void enableCloud(String userId) {
    // Always cancel existing subscription first (handles re-login)
    _sub?.cancel();
    _useCloud = true;

    _sub = _firestore.watchTrips(userId).listen(
      (list) { _trips = list; _error = null; notifyListeners(); },
      onError: (e) { _error = 'Trips stream error: $e'; debugPrint(_error); notifyListeners(); },
    );
  }

  /// Called on logout — cancels stream and clears data
  void resetCloud() {
    _sub?.cancel();
    _sub = null;
    _trips = [];
    _useCloud = false;
    _error = null;
    _successMsg = null;
    notifyListeners();
  }

  @override
  void dispose() { _sub?.cancel(); super.dispose(); }

  // ── Lookups ───────────────────────────────────────────────────────────────
  FreightRoute? routeForTrip(Trip t)  => _store.getRoute(t.routeId);
  Truck?        truckForTrip(Trip t)  => _store.getTruck(t.truckId);
  Driver?       driverForTrip(Trip t) => _store.getDriver(t.driverId);
  Challan?      challanForTrip(Trip t)=> _store.getChallan(t.challanId);

  List<Bilty> biltiesForTrip(Trip t) {
    final challan = _store.getChallan(t.challanId);
    if (challan == null) return [];
    return challan.biltyIds
        .map((id) => _store.getBilty(id))
        .whereType<Bilty>()
        .toList();
  }

  // ── Create trip ───────────────────────────────────────────────────────────
  Future<bool> createTrip({
    required String routeId,  required String truckId,
    required String driverId, required String challanId,
    required DateTime scheduledDate, required String createdBy,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      final trip = Trip(
        id: _store.uid(), userId: createdBy, tripNo: _store.tripNo(), routeId: routeId,
        truckId: truckId, driverId: driverId, challanId: challanId,
        scheduledDate: scheduledDate, createdBy: createdBy, createdAt: DateTime.now(),
      );
      if (_useCloud) {
        await _firestore.addTrip(trip);
      } else {
        await _store.addTrip(trip);
        _trips = _store.getTrips();
      }
      _successMsg = 'Trip ${trip.tripNo} created successfully.';
      _loading = false; notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false; notifyListeners();
      return false;
    }
  }

  // ── Advance state (with GPS capture) ─────────────────────────────────────
  Future<bool> advanceState({
    required String tripId, required TripState newState,
    required String updatedBy, String? note,
  }) async {
    _loading = true; _error = null; notifyListeners();
    try {
      // Capture GPS position at state transition
      final location = await LocationService.instance.getCurrentLocation();

      if (_useCloud) {
        await _firestore.advanceTripState(
          tripId: tripId, newState: newState,
          updatedBy: updatedBy, note: note, location: location,
        );
        // Stream will update _trips automatically
      } else {
        await _store.advanceTripState(
          tripId: tripId, newState: newState,
          updatedBy: updatedBy, note: note,
        );
        _trips = _store.getTrips();
      }
      _successMsg = 'Status updated to "${TripStateHelper.label(newState)}".';
      _loading = false; notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false; notifyListeners();
      return false;
    }
  }

  /// Manually push a GPS update for an active trip (called from live map)
  Future<void> updateLocation(String tripId, TripLatLng location) async {
    if (_useCloud) {
      await _firestore.updateTripLocation(tripId, location);
    } else {
      final idx = _trips.indexWhere((t) => t.id == tripId);
      if (idx != -1) {
        _trips[idx] = _trips[idx].copyWith(currentLocation: location);
        notifyListeners();
      }
    }
  }

  void clearMessages() { _error = null; _successMsg = null; notifyListeners(); }
  void refresh() {
    if (!_useCloud) { _trips = _store.getTrips(); notifyListeners(); }
  }
}
