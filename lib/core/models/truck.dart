import 'package:equatable/equatable.dart';

enum TruckStatus { available, onTrip, maintenance }

class TruckStatusHelper {
  static const Map<TruckStatus, String> _labels = {
    TruckStatus.available:   'Available',
    TruckStatus.onTrip:      'On Trip',
    TruckStatus.maintenance: 'Maintenance',
  };
  static String label(TruckStatus s) => _labels[s]!;
}

class Truck extends Equatable {
  final String id;
  final String userId;
  final String vehicleNo;
  final String make;
  final String model;
  final double capacityKg;
  final TruckStatus status;
  final DateTime createdAt;

  const Truck({
    required this.id,
    required this.userId,
    required this.vehicleNo,
    required this.make,
    required this.model,
    required this.capacityKg,
    this.status = TruckStatus.available,
    required this.createdAt,
  });

  Truck copyWith({
    String? vehicleNo,
    String? make,
    String? model,
    double? capacityKg,
    TruckStatus? status,
  }) {
    return Truck(
      id: id,
      userId: userId,
      vehicleNo:  vehicleNo  ?? this.vehicleNo,
      make:       make       ?? this.make,
      model:      model      ?? this.model,
      capacityKg: capacityKg ?? this.capacityKg,
      status:     status     ?? this.status,
      createdAt:  createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id, 'userId': userId, 'vehicleNo': vehicleNo, 'make': make, 'model': model,
    'capacityKg': capacityKg, 'status': status.index,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Truck.fromMap(Map<String, dynamic> m) => Truck(
    id: m['id'], userId: m['userId'] ?? '', vehicleNo: m['vehicleNo'], make: m['make'], model: m['model'],
    capacityKg: (m['capacityKg'] as num).toDouble(),
    status: TruckStatus.values[m['status'] ?? 0],
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
  );

  @override
  List<Object?> get props => [id, vehicleNo, make, model, capacityKg, status];
}
