import 'package:equatable/equatable.dart';

enum TripState { godown, dispatched, inTransit, delivered, cancelled }

class TripStateHelper {
  static const Map<TripState, String> _labels = {
    TripState.godown: 'At Godown', TripState.dispatched: 'Dispatched',
    TripState.inTransit: 'In Transit', TripState.delivered: 'Delivered',
    TripState.cancelled: 'Cancelled',
  };
  static const Map<TripState, int> _stepIndex = {
    TripState.godown: 0, TripState.dispatched: 1, TripState.inTransit: 2,
    TripState.delivered: 3, TripState.cancelled: -1,
  };
  static const Map<TripState, List<TripState>> _nextStates = {
    TripState.godown:     [TripState.dispatched, TripState.cancelled],
    TripState.dispatched: [TripState.inTransit, TripState.cancelled],
    TripState.inTransit:  [TripState.delivered],
    TripState.delivered:  [],
    TripState.cancelled:  [],
  };
  static String label(TripState s) => _labels[s]!;
  static int stepIndex(TripState s) => _stepIndex[s]!;
  static List<TripState> nextStates(TripState s) => _nextStates[s]!;
  static bool isTerminal(TripState s) =>
      s == TripState.delivered || s == TripState.cancelled;
}

class TripLatLng {
  final double latitude;
  final double longitude;
  const TripLatLng(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};
  factory TripLatLng.fromJson(Map<String, dynamic> j) =>
      TripLatLng((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());

  @override
  String toString() =>
      '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
}

class TripStateEvent {
  final TripState from;
  final TripState to;
  final DateTime timestamp;
  final String updatedBy;
  final String? note;
  final TripLatLng? location;

  const TripStateEvent({
    required this.from, required this.to, required this.timestamp,
    required this.updatedBy, this.note, this.location,
  });

  Map<String, dynamic> toJson() => {
    'from': from.index, 'to': to.index,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'updatedBy': updatedBy, 'note': note,
    'location': location?.toJson(),
  };
  Map<String, dynamic> toMap() => toJson();

  factory TripStateEvent.fromJson(Map<String, dynamic> m) => TripStateEvent(
    from: TripState.values[m['from'] as int],
    to: TripState.values[m['to'] as int],
    timestamp: DateTime.fromMillisecondsSinceEpoch(m['timestamp'] as int),
    updatedBy: m['updatedBy'] as String? ?? '',
    note: m['note'] as String?,
    location: m['location'] != null
        ? TripLatLng.fromJson(Map<String, dynamic>.from(m['location'] as Map))
        : null,
  );
  factory TripStateEvent.fromMap(Map<String, dynamic> m) =>
      TripStateEvent.fromJson(m);
}

class Trip extends Equatable {
  final String id, userId, tripNo, routeId, truckId, driverId, challanId, createdBy;
  final TripState state;
  final List<TripStateEvent> stateHistory;
  final DateTime scheduledDate, createdAt;
  final DateTime? actualDispatchDate, actualDeliveryDate;
  final TripLatLng? currentLocation;

  const Trip({
    required this.id, required this.userId, required this.tripNo, required this.routeId,
    required this.truckId, required this.driverId, required this.challanId,
    this.state = TripState.godown, this.stateHistory = const [],
    required this.scheduledDate, this.actualDispatchDate,
    this.actualDeliveryDate, required this.createdBy, required this.createdAt,
    this.currentLocation,
  });

  Trip copyWith({
    TripState? state, List<TripStateEvent>? stateHistory,
    DateTime? actualDispatchDate, DateTime? actualDeliveryDate,
    TripLatLng? currentLocation,
  }) => Trip(
    id: id, userId: userId, tripNo: tripNo, routeId: routeId, truckId: truckId,
    driverId: driverId, challanId: challanId,
    state: state ?? this.state,
    stateHistory: stateHistory ?? this.stateHistory,
    scheduledDate: scheduledDate,
    actualDispatchDate: actualDispatchDate ?? this.actualDispatchDate,
    actualDeliveryDate: actualDeliveryDate ?? this.actualDeliveryDate,
    createdBy: createdBy, createdAt: createdAt,
    currentLocation: currentLocation ?? this.currentLocation,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'userId': userId, 'tripNo': tripNo, 'routeId': routeId, 'truckId': truckId,
    'driverId': driverId, 'challanId': challanId, 'state': state.index,
    'stateHistory': stateHistory.map((e) => e.toJson()).toList(),
    'scheduledDate': scheduledDate.millisecondsSinceEpoch,
    'actualDispatchDate': actualDispatchDate?.millisecondsSinceEpoch,
    'actualDeliveryDate': actualDeliveryDate?.millisecondsSinceEpoch,
    'createdBy': createdBy, 'createdAt': createdAt.millisecondsSinceEpoch,
    'currentLocation': currentLocation?.toJson(),
  };
  Map<String, dynamic> toMap() => toJson();

  factory Trip.fromJson(Map<String, dynamic> m) => Trip(
    id: m['id'] as String, userId: m['userId'] as String? ?? '', tripNo: m['tripNo'] as String,
    routeId: m['routeId'] as String, truckId: m['truckId'] as String,
    driverId: m['driverId'] as String, challanId: m['challanId'] as String,
    state: TripState.values[m['state'] as int? ?? 0],
    stateHistory: (m['stateHistory'] as List? ?? [])
        .map((e) => TripStateEvent.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList(),
    scheduledDate:
        DateTime.fromMillisecondsSinceEpoch(m['scheduledDate'] as int),
    actualDispatchDate: m['actualDispatchDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['actualDispatchDate'] as int)
        : null,
    actualDeliveryDate: m['actualDeliveryDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(m['actualDeliveryDate'] as int)
        : null,
    createdBy: m['createdBy'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
    currentLocation: m['currentLocation'] != null
        ? TripLatLng.fromJson(
            Map<String, dynamic>.from(m['currentLocation'] as Map))
        : null,
  );
  factory Trip.fromMap(Map<String, dynamic> m) => Trip.fromJson(m);

  @override
  List<Object?> get props =>
      [id, tripNo, state, challanId, currentLocation];
}
