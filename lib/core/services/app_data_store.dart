import 'dart:math';
import '../models/app_user.dart';
import '../models/bilty.dart';
import '../models/challan.dart';
import '../models/driver.dart';
import '../models/freight_route.dart';
import '../models/trip.dart';
import '../models/truck.dart';

class AppDataStore {
  AppDataStore._();
  static final AppDataStore instance = AppDataStore._();

  final _rng = Random();

  final Map<String, AppUser>      _users    = {};
  final Map<String, Truck>        _trucks   = {};
  final Map<String, Driver>       _drivers  = {};
  final Map<String, FreightRoute> _routes   = {};
  final Map<String, Bilty>        _bilties  = {};
  final Map<String, Challan>      _challans = {};
  final Map<String, Trip>         _trips    = {};

  bool _seeded = false;

  String uid() => DateTime.now().microsecondsSinceEpoch.toString() + _rng.nextInt(9999).toString();

  String biltyNo() {
    final seq = (_bilties.length + 1).toString().padLeft(5, '0');
    return 'FF-${DateTime.now().year}-$seq';
  }

  String challanNo() {
    final seq = (_challans.length + 1).toString().padLeft(4, '0');
    return 'CH-${DateTime.now().year}-$seq';
  }

  String tripNo() {
    final seq = (_trips.length + 1).toString().padLeft(4, '0');
    return 'TR-${DateTime.now().year}-$seq';
  }

  void seed() {
    if (_seeded) return;
    _seeded = true;

    // ── Admin user ────────────────────────────────────────────────────────
    final admin = AppUser(
      id: 'admin-001',
      email: 'admin@freightflow.in',
      name: 'Rajesh Shah',
      role: UserRole.admin,
      createdAt: DateTime(2024, 1, 1),
    );
    _users[admin.id] = admin;

    // ── Trucks ────────────────────────────────────────────────────────────
    final trucks = [
      Truck(id: 'truck-001', userId: 'admin-001', vehicleNo: 'GJ-03-AX-4821', make: 'Tata',          model: '407',      capacityKg: 4000,  createdAt: DateTime(2024, 1, 10)),
      Truck(id: 'truck-002', userId: 'admin-001', vehicleNo: 'GJ-05-BK-7734', make: 'Ashok Leyland', model: '1109',     capacityKg: 9000,  status: TruckStatus.onTrip, createdAt: DateTime(2024, 2, 5)),
      Truck(id: 'truck-003', userId: 'admin-001', vehicleNo: 'GJ-01-CZ-2290', make: 'Tata',          model: 'LPT 1618', capacityKg: 16000, createdAt: DateTime(2024, 3, 12)),
      Truck(id: 'truck-004', userId: 'admin-001', vehicleNo: 'GJ-06-TH-9102', make: 'Mahindra',      model: 'Blazo',    capacityKg: 6000,  status: TruckStatus.maintenance, createdAt: DateTime(2024, 4, 1)),
    ];
    for (final t in trucks) { _trucks[t.id] = t; }

    // ── Drivers ───────────────────────────────────────────────────────────
    final drivers = [
      Driver(id: 'drv-001', userId: 'admin-001', name: 'Ramesh Patel',  licenseNo: 'GJ03-20180023412', phone: '9876543210', createdAt: DateTime(2024, 1, 15)),
      Driver(id: 'drv-002', userId: 'admin-001', name: 'Suresh Yadav',  licenseNo: 'GJ05-20160045678', phone: '9898989890', isAvailable: false, createdAt: DateTime(2024, 2, 10)),
      Driver(id: 'drv-003', userId: 'admin-001', name: 'Dinesh Kumar',  licenseNo: 'GJ01-20190067890', phone: '9712345678', createdAt: DateTime(2024, 3, 20)),
      Driver(id: 'drv-004', userId: 'admin-001', name: 'Mahesh Singh',  licenseNo: 'GJ06-20150089012', phone: '9664567890', createdAt: DateTime(2024, 4, 5)),
    ];
    for (final d in drivers) { _drivers[d.id] = d; }

    // ── Routes ────────────────────────────────────────────────────────────
    final routes = [
      FreightRoute(id: 'route-001', userId: 'admin-001', origin: 'Rajkot',    destination: 'Mumbai',    distanceKm: 620,  baseRatePerKg: 4.80, createdAt: DateTime(2024, 1, 1)),
      FreightRoute(id: 'route-002', userId: 'admin-001', origin: 'Rajkot',    destination: 'Delhi',     distanceKm: 1060, baseRatePerKg: 6.20, createdAt: DateTime(2024, 1, 1)),
      FreightRoute(id: 'route-003', userId: 'admin-001', origin: 'Rajkot',    destination: 'Bangalore', distanceKm: 1380, baseRatePerKg: 7.50, createdAt: DateTime(2024, 1, 1)),
      FreightRoute(id: 'route-004', userId: 'admin-001', origin: 'Rajkot',    destination: 'Pune',      distanceKm: 580,  baseRatePerKg: 4.50, createdAt: DateTime(2024, 1, 1)),
      FreightRoute(id: 'route-005', userId: 'admin-001', origin: 'Rajkot',    destination: 'Ahmedabad', distanceKm: 218,  baseRatePerKg: 2.80, createdAt: DateTime(2024, 1, 1)),
      FreightRoute(id: 'route-006', userId: 'admin-001', origin: 'Ahmedabad', destination: 'Chennai',   distanceKm: 1920, baseRatePerKg: 8.20, createdAt: DateTime(2024, 1, 1)),
    ];
    for (final r in routes) { _routes[r.id] = r; }

    // ── Bilties with realistic GST numbers ────────────────────────────────
    // GST format: 2-digit state code + PAN (5 letters + 4 digits + 1 letter) + 1 digit + Z + checksum
    // Gujarat = 24, Maharashtra = 27, Delhi = 07, Karnataka = 29, Rajasthan = 08
    final now = DateTime.now();

    final biltyData = [
      // (consignorName, consignorPhone, consignorGst, consigneeName, consigneePhone, consigneeGst, consigneeCity, category, weightKg, packages, routeId, paymentType)
      ('Shree Balaji Textiles Pvt Ltd', '9876541234', '24AABBS1234C1Z5',
       'Metro Fashion Hub',            '9823456789', '27AACMF5678D1Z3',
       'Mumbai',    'Textiles & Garments',    2400.0, 12, 'route-001', PaymentType.toPay),

      ('Diamond Silk Export House',    '9712345678', '24AACDS9876E1Z2',
       'Karol Bagh Wholesale Mkt',     '9811234567', '07AADKB4321F1Z8',
       'Delhi',     'Textiles & Garments',     850.0,  6, 'route-002', PaymentType.paid),

      ('Gujarat Pharma Industries',    '9978563412', '24AAGPI2345G1Z7',
       'MedPlus Distribution Centre',  '9845671230', '29AADMP6789H1Z6',
       'Bangalore', 'Perishable / Cold Chain', 1200.0, 8, 'route-003', PaymentType.toBeBilled),

      ('Anand Auto Components Ltd',    '9664512378', '24AAACA7654I1Z4',
       'Pune Motors Private Limited',  '9765432108', '27AABPM3456J1Z9',
       'Pune',      'Machinery & Equipment',  3800.0,  3, 'route-004', PaymentType.toPay),

      ('Rajkot Steel Fabricators',     '9898761234', '24AABRS4567K1Z1',
       'Ahmed Steel Trading Co',       '9823456710', '27AACAT8901L1Z5',
       'Mumbai',    'Machinery & Equipment',  1600.0, 10, 'route-001', PaymentType.toPay),

      ('Saurashtra Agro Exports',      '9834561234', '24AACSA3210M1Z3',
       'Fresh Harvest Delhi Hub',      '9876501234', '07AABFH6543N1Z7',
       'Delhi',     'Agricultural Produce',   3200.0, 20, 'route-002', PaymentType.paid),
    ];

    int seq = 1;
    for (final d in biltyData) {
      final route = _routes[d.$11]!;
      final bId = 'bilty-${seq.toString().padLeft(3, '0')}';
      final bNo = 'FF-2025-${seq.toString().padLeft(5, '0')}';
      _bilties[bId] = Bilty(
        id: bId, userId: 'admin-001', biltyNo: bNo, routeId: d.$11,
        consignorName: d.$1, consignorPhone: d.$2, consignorGst: d.$3,
        consigneeName: d.$4, consigneePhone: d.$5, consigneeGst: d.$6,
        consigneeCity: d.$7,
        goodsDescription: d.$8, goodsCategory: d.$8,
        weightKg: d.$9, noOfPackages: d.$10,
        freightPerKg: route.baseRatePerKg,
        paymentType: d.$12,
        createdAt: now.subtract(Duration(days: seq * 2)),
        createdBy: 'admin-001',
      );
      seq++;
    }

    // ── Demo challan (2 bilties on route-001 → truck-002 which is onTrip) ──
    const challanId = 'challan-001';
    _challans[challanId] = Challan(
      id: challanId,
      userId: 'admin-001',
      challanNo: 'CH-2025-0001',
      routeId: 'route-001',
      biltyIds: const ['bilty-001', 'bilty-005'],
      truckId: 'truck-002',
      status: ChallanStatus.assignedToTrip,
      tripId: 'trip-001',
      createdAt: now.subtract(const Duration(days: 3)),
      createdBy: 'admin-001',
    );
    _bilties['bilty-001'] = _bilties['bilty-001']!.copyWith(status: BiltyStatus.dispatched, challanId: challanId);
    _bilties['bilty-005'] = _bilties['bilty-005']!.copyWith(status: BiltyStatus.dispatched, challanId: challanId);

    // ── Demo trip ─────────────────────────────────────────────────────────
    _trips['trip-001'] = Trip(
      id: 'trip-001', userId: 'admin-001', tripNo: 'TR-2025-0001',
      routeId: 'route-001', truckId: 'truck-002',
      driverId: 'drv-002', challanId: challanId,
      state: TripState.inTransit,
      stateHistory: [
        TripStateEvent(from: TripState.godown, to: TripState.dispatched, timestamp: now.subtract(const Duration(days: 2)), updatedBy: 'admin-001'),
        TripStateEvent(from: TripState.dispatched, to: TripState.inTransit, timestamp: now.subtract(const Duration(hours: 18)), updatedBy: 'admin-001'),
      ],
      scheduledDate: now.subtract(const Duration(days: 3)),
      actualDispatchDate: now.subtract(const Duration(days: 2)),
      createdBy: 'admin-001', createdAt: now.subtract(const Duration(days: 3)),
    );
    _trucks['truck-002'] = _trucks['truck-002']!.copyWith(status: TruckStatus.onTrip);
    _drivers['drv-002']  = _drivers['drv-002']!.copyWith(isAvailable: false);
  }

  // ── Auth ──────────────────────────────────────────────────────────────────
  AppUser? findUserByEmail(String email) =>
      _users.values.where((u) => u.email == email).firstOrNull;

  Future<AppUser> loginUser({required String email, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = findUserByEmail(email);
    if (user == null) throw Exception('No account found for this email.');
    if (password.length < 6) throw Exception('Invalid password.');
    return user;
  }

  Future<AppUser> registerUser({required String email, required String name, required String password}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (_users.values.any((u) => u.email == email)) throw Exception('An account with this email already exists.');
    final user = AppUser(id: uid(), email: email, name: name, role: UserRole.admin, createdAt: DateTime.now());
    _users[user.id] = user;
    return user;
  }

  // ── Trucks ────────────────────────────────────────────────────────────────
  List<Truck> getTrucks() => List.unmodifiable(_trucks.values.toList()..sort((a, b) => a.vehicleNo.compareTo(b.vehicleNo)));
  Truck? getTruck(String id) => _trucks[id];
  Future<Truck> addTruck(Truck t) async { await Future.delayed(const Duration(milliseconds: 200)); _trucks[t.id] = t; return t; }
  Future<void> updateTruck(Truck t) async { await Future.delayed(const Duration(milliseconds: 150)); _trucks[t.id] = t; }
  Future<void> deleteTruck(String id) async { await Future.delayed(const Duration(milliseconds: 150)); _trucks.remove(id); }

  // ── Drivers ───────────────────────────────────────────────────────────────
  List<Driver> getDrivers() => List.unmodifiable(_drivers.values.toList()..sort((a, b) => a.name.compareTo(b.name)));
  Driver? getDriver(String id) => _drivers[id];
  Future<Driver> addDriver(Driver d) async { await Future.delayed(const Duration(milliseconds: 200)); _drivers[d.id] = d; return d; }
  Future<void> updateDriver(Driver d) async { await Future.delayed(const Duration(milliseconds: 150)); _drivers[d.id] = d; }
  Future<void> deleteDriver(String id) async { await Future.delayed(const Duration(milliseconds: 150)); _drivers.remove(id); }

  // ── Routes ────────────────────────────────────────────────────────────────
  List<FreightRoute> getRoutes() => List.unmodifiable(_routes.values.where((r) => r.isActive).toList()..sort((a, b) => a.origin.compareTo(b.origin)));
  FreightRoute? getRoute(String id) => _routes[id];
  Future<FreightRoute> addRoute(FreightRoute r) async { await Future.delayed(const Duration(milliseconds: 200)); _routes[r.id] = r; return r; }
  Future<void> updateRoute(FreightRoute r) async { await Future.delayed(const Duration(milliseconds: 150)); _routes[r.id] = r; }

  // ── Bilties ───────────────────────────────────────────────────────────────
  List<Bilty> getBilties() => List.unmodifiable(_bilties.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  List<Bilty> getPendingBilties() => getBilties().where((b) => b.status == BiltyStatus.pending).toList();
  List<Bilty> getPendingBiltiesForRoute(String routeId) => getPendingBilties().where((b) => b.routeId == routeId).toList();
  Bilty? getBilty(String id) => _bilties[id];
  Future<Bilty> addBilty(Bilty b) async { await Future.delayed(const Duration(milliseconds: 300)); _bilties[b.id] = b; return b; }
  Future<void> updateBilty(Bilty b) async { await Future.delayed(const Duration(milliseconds: 150)); _bilties[b.id] = b; }

  // ── Challans ──────────────────────────────────────────────────────────────
  List<Challan> getChallans() => List.unmodifiable(_challans.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  List<Challan> getOpenChallans() => getChallans().where((c) => c.status == ChallanStatus.open).toList();
  Challan? getChallan(String id) => _challans[id];
  Future<Challan> addChallan(Challan c) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _challans[c.id] = c;
    for (final bId in c.biltyIds) {
      final b = _bilties[bId];
      if (b != null) { _bilties[bId] = b.copyWith(status: BiltyStatus.loadedInChallan, challanId: c.id); }
    }
    return c;
  }
  Future<void> updateChallan(Challan c) async { await Future.delayed(const Duration(milliseconds: 150)); _challans[c.id] = c; }

  // ── Trips ─────────────────────────────────────────────────────────────────
  List<Trip> getTrips() => List.unmodifiable(_trips.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt)));
  Trip? getTrip(String id) => _trips[id];
  Future<Trip> addTrip(Trip t) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _trips[t.id] = t;
    final challan = _challans[t.challanId];
    if (challan != null) { _challans[t.challanId] = challan.copyWith(status: ChallanStatus.assignedToTrip, tripId: t.id); }
    final truck = _trucks[t.truckId];
    if (truck != null) { _trucks[t.truckId] = truck.copyWith(status: TruckStatus.onTrip); }
    final driver = _drivers[t.driverId];
    if (driver != null) { _drivers[t.driverId] = driver.copyWith(isAvailable: false); }
    return t;
  }
  Future<Trip> advanceTripState({required String tripId, required TripState newState, required String updatedBy, String? note}) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final trip = _trips[tripId];
    if (trip == null) throw Exception('Trip not found.');
    if (!TripStateHelper.nextStates(trip.state).contains(newState)) {
      throw Exception('Invalid state transition: ${TripStateHelper.label(trip.state)} → ${TripStateHelper.label(newState)}');
    }
    final event = TripStateEvent(from: trip.state, to: newState, timestamp: DateTime.now(), updatedBy: updatedBy, note: note);
    DateTime? dispatchDate = trip.actualDispatchDate;
    DateTime? deliveryDate = trip.actualDeliveryDate;
    if (newState == TripState.dispatched) dispatchDate = DateTime.now();
    if (newState == TripState.delivered)  deliveryDate = DateTime.now();
    final updated = trip.copyWith(state: newState, stateHistory: [...trip.stateHistory, event], actualDispatchDate: dispatchDate, actualDeliveryDate: deliveryDate);
    _trips[tripId] = updated;
    if (TripStateHelper.isTerminal(newState)) {
      _trucks[trip.truckId] = _trucks[trip.truckId]!.copyWith(status: TruckStatus.available);
      _drivers[trip.driverId] = _drivers[trip.driverId]!.copyWith(isAvailable: true);
      final challan = _challans[trip.challanId];
      if (challan != null) {
        _challans[trip.challanId] = challan.copyWith(status: ChallanStatus.closed);
        if (newState == TripState.delivered) {
          for (final bId in challan.biltyIds) {
            final b = _bilties[bId];
            if (b != null) { _bilties[bId] = b.copyWith(status: BiltyStatus.delivered); }
          }
        }
      }
    }
    return updated;
  }

  Map<String, int> getDashboardStats() => {
    'totalBilties':    _bilties.length,
    'pendingBilties':  getPendingBilties().length,
    'activeTrips':     _trips.values.where((t) => !TripStateHelper.isTerminal(t.state)).length,
    'availableTrucks': _trucks.values.where((t) => t.status == TruckStatus.available).length,
  };
}
