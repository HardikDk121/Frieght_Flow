import 'package:equatable/equatable.dart';

enum ChallanStatus { open, assignedToTrip, closed }

class ChallanStatusHelper {
  static const Map<ChallanStatus, String> _labels = {
    ChallanStatus.open:           'Open',
    ChallanStatus.assignedToTrip: 'Assigned to Trip',
    ChallanStatus.closed:         'Closed',
  };
  static String label(ChallanStatus s) => _labels[s]!;
}

class Challan extends Equatable {
  final String id;
  final String userId;
  final String challanNo;
  final String routeId;
  final List<String> biltyIds;
  final String? truckId;        // truck assigned at challan creation
  final ChallanStatus status;
  final String? tripId;
  final DateTime createdAt;
  final String createdBy;

  const Challan({
    required this.id,
    required this.userId,
    required this.challanNo,
    required this.routeId,
    required this.biltyIds,
    this.truckId,
    this.status = ChallanStatus.open,
    this.tripId,
    required this.createdAt,
    required this.createdBy,
  });

  int get totalBilties => biltyIds.length;

  Challan copyWith({
    List<String>? biltyIds,
    ChallanStatus? status,
    String? tripId,
    String? truckId,
  }) {
    return Challan(
      id: id, userId: userId, challanNo: challanNo, routeId: routeId,
      biltyIds:  biltyIds  ?? this.biltyIds,
      truckId:   truckId   ?? this.truckId,
      status:    status    ?? this.status,
      tripId:    tripId    ?? this.tripId,
      createdAt: createdAt, createdBy: createdBy,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'challanNo': challanNo, 'routeId': routeId,
    'biltyIds': biltyIds, 'truckId': truckId,
    'status': status.index, 'tripId': tripId,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'createdBy': createdBy,
  };

  factory Challan.fromMap(Map<String, dynamic> m) => Challan(
    id: m['id'], userId: m['userId'] ?? '', challanNo: m['challanNo'], routeId: m['routeId'],
    biltyIds: List<String>.from(m['biltyIds'] ?? []),
    truckId:  m['truckId'],
    status:   ChallanStatus.values[m['status'] ?? 0],
    tripId:   m['tripId'],
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
    createdBy: m['createdBy'] ?? '',
  );

  @override
  List<Object?> get props => [id, challanNo, biltyIds, status, tripId, truckId];
}
