// ══════════════════════════════════════════════════════════════════════════════
// FirestoreService — LIVE VERSION
//
// After completing FIREBASE_SETUP.md, copy this file to:
//   lib/core/services/firestore_service.dart
// (replacing the stub)
// ══════════════════════════════════════════════════════════════════════════════
// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lib/core/models/app_user.dart';
import 'lib/core/models/bilty.dart';
import 'lib/core/models/challan.dart';
import 'lib/core/models/driver.dart';
import 'lib/core/models/freight_route.dart';
import 'lib/core/models/trip.dart';
import 'lib/core/models/truck.dart';

class FirestoreService {
  FirestoreService._();
  static final FirestoreService instance = FirestoreService._();

  // Lazy getter — only calls FirebaseFirestore.instance when a method is used,
  // never at class construction. Safe before Firebase.initializeApp().
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _users    => _db.collection('users');
  CollectionReference<Map<String, dynamic>> get _trucks   => _db.collection('trucks');
  CollectionReference<Map<String, dynamic>> get _drivers  => _db.collection('drivers');
  CollectionReference<Map<String, dynamic>> get _routes   => _db.collection('routes');
  CollectionReference<Map<String, dynamic>> get _bilties  => _db.collection('bilties');
  CollectionReference<Map<String, dynamic>> get _challans => _db.collection('challans');
  CollectionReference<Map<String, dynamic>> get _trips    => _db.collection('trips');

  Map<String, dynamic> _fromSnap(DocumentSnapshot<Map<String, dynamic>> s) {
    final data = s.data()!;
    data['id'] = s.id;
    return data;
  }

  Future<AppUser?> findUserByEmail(String email) async {
    final q = await _users.where('email', isEqualTo: email).limit(1).get();
    if (q.docs.isEmpty) return null;
    return AppUser.fromMap(_fromSnap(q.docs.first));
  }

  Future<AppUser> loginUser({required String email, required String password}) async {
    final user = await findUserByEmail(email);
    if (user == null) throw Exception('No account found for this email.');
    if (password.length < 6) throw Exception('Invalid password.');
    return user;
  }

  Future<AppUser> registerUser({required String email, required String name, required String password}) async {
    final existing = await findUserByEmail(email);
    if (existing != null) throw Exception('An account with this email already exists.');
    final ref = _users.doc();
    final user = AppUser(id: ref.id, email: email, name: name, role: UserRole.admin, createdAt: DateTime.now());
    final data = user.toMap(); data.remove('id');
    await ref.set(data);
    return user;
  }

  Stream<List<Truck>> watchTrucks() => _trucks.orderBy('vehicleNo').snapshots()
      .map((q) => q.docs.map((s) => Truck.fromMap(_fromSnap(s))).toList());
  Future<void> addTruck(Truck t) async { final d = t.toMap(); d.remove('id'); await _trucks.doc(t.id).set(d); }
  Future<void> updateTruck(Truck t) async { final d = t.toMap(); d.remove('id'); await _trucks.doc(t.id).update(d); }
  Future<void> deleteTruck(String id) => _trucks.doc(id).delete();
  Future<Truck?> getTruck(String id) async { final s = await _trucks.doc(id).get(); return s.exists ? Truck.fromMap(_fromSnap(s)) : null; }

  Stream<List<Driver>> watchDrivers() => _drivers.orderBy('name').snapshots()
      .map((q) => q.docs.map((s) => Driver.fromMap(_fromSnap(s))).toList());
  Future<void> addDriver(Driver d) async { final data = d.toMap(); data.remove('id'); await _drivers.doc(d.id).set(data); }
  Future<void> updateDriver(Driver d) async { final data = d.toMap(); data.remove('id'); await _drivers.doc(d.id).update(data); }
  Future<void> deleteDriver(String id) => _drivers.doc(id).delete();
  Future<Driver?> getDriver(String id) async { final s = await _drivers.doc(id).get(); return s.exists ? Driver.fromMap(_fromSnap(s)) : null; }

  Stream<List<FreightRoute>> watchRoutes() =>
      _routes.where('isActive', isEqualTo: true).orderBy('origin').snapshots()
          .map((q) => q.docs.map((s) => FreightRoute.fromMap(_fromSnap(s))).toList());
  Future<void> addRoute(FreightRoute r) async { final d = r.toMap(); d.remove('id'); await _routes.doc(r.id).set(d); }
  Future<FreightRoute?> getRoute(String id) async { final s = await _routes.doc(id).get(); return s.exists ? FreightRoute.fromMap(_fromSnap(s)) : null; }

  Stream<List<Bilty>> watchBilties() => _bilties.orderBy('createdAt', descending: true).snapshots()
      .map((q) => q.docs.map((s) => Bilty.fromMap(_fromSnap(s))).toList());
  Future<void> addBilty(Bilty b) async { final d = b.toMap(); d.remove('id'); await _bilties.doc(b.id).set(d); }
  Future<void> updateBilty(Bilty b) async { final d = b.toMap(); d.remove('id'); await _bilties.doc(b.id).update(d); }
  Future<Bilty?> getBilty(String id) async { final s = await _bilties.doc(id).get(); return s.exists ? Bilty.fromMap(_fromSnap(s)) : null; }

  Stream<List<Challan>> watchChallans() => _challans.orderBy('createdAt', descending: true).snapshots()
      .map((q) => q.docs.map((s) => Challan.fromMap(_fromSnap(s))).toList());
  Future<void> addChallan(Challan c, List<String> biltyIds) async {
    final batch = _db.batch();
    final data = c.toMap(); data.remove('id');
    batch.set(_challans.doc(c.id), data);
    for (final bId in biltyIds) {
      batch.update(_bilties.doc(bId), {'status': BiltyStatus.loadedInChallan.index, 'challanId': c.id});
    }
    await batch.commit();
  }
  Future<void> updateChallan(Challan c) async { final d = c.toMap(); d.remove('id'); await _challans.doc(c.id).update(d); }
  Future<Challan?> getChallan(String id) async { final s = await _challans.doc(id).get(); return s.exists ? Challan.fromMap(_fromSnap(s)) : null; }

  Stream<List<Trip>> watchTrips() => _trips.orderBy('createdAt', descending: true).snapshots()
      .map((q) => q.docs.map((s) => Trip.fromMap(_fromSnap(s))).toList());
  Future<void> addTrip(Trip t) async {
    final batch = _db.batch();
    final data = t.toJson(); data.remove('id');
    batch.set(_trips.doc(t.id), data);
    batch.update(_challans.doc(t.challanId), {'status': ChallanStatus.assignedToTrip.index, 'tripId': t.id});
    batch.update(_trucks.doc(t.truckId), {'status': TruckStatus.onTrip.index});
    batch.update(_drivers.doc(t.driverId), {'isAvailable': false});
    await batch.commit();
  }
  Future<Trip> advanceTripState({required String tripId, required TripState newState, required String updatedBy, String? note, TripLatLng? location}) async {
    final tripSnap = await _trips.doc(tripId).get();
    if (!tripSnap.exists) throw Exception('Trip not found.');
    final trip = Trip.fromMap(_fromSnap(tripSnap));
    if (!TripStateHelper.nextStates(trip.state).contains(newState)) {
      throw Exception('Invalid transition: ${TripStateHelper.label(trip.state)} → ${TripStateHelper.label(newState)}');
    }
    final event = TripStateEvent(from: trip.state, to: newState, timestamp: DateTime.now(), updatedBy: updatedBy, note: note, location: location);
    final updated = trip.copyWith(
      state: newState, stateHistory: [...trip.stateHistory, event],
      actualDispatchDate: newState == TripState.dispatched ? DateTime.now() : trip.actualDispatchDate,
      actualDeliveryDate: newState == TripState.delivered  ? DateTime.now() : trip.actualDeliveryDate,
      currentLocation: location ?? trip.currentLocation,
    );
    final batch = _db.batch();
    final data = updated.toJson(); data.remove('id');
    batch.update(_trips.doc(tripId), data);
    if (TripStateHelper.isTerminal(newState)) {
      batch.update(_trucks.doc(trip.truckId), {'status': TruckStatus.available.index});
      batch.update(_drivers.doc(trip.driverId), {'isAvailable': true});
      batch.update(_challans.doc(trip.challanId), {'status': ChallanStatus.closed.index});
      if (newState == TripState.delivered) {
        final challan = await getChallan(trip.challanId);
        if (challan != null) {
          for (final bId in challan.biltyIds) { batch.update(_bilties.doc(bId), {'status': BiltyStatus.delivered.index}); }
        }
      }
    }
    await batch.commit();
    return updated;
  }
  Future<void> updateTripLocation(String tripId, TripLatLng location) =>
      _trips.doc(tripId).update({'currentLocation': location.toJson()});
  Future<bool> isSeeded() async { final s = await _trucks.limit(1).get(); return s.docs.isNotEmpty; }
}
