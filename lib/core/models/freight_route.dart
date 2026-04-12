import 'package:equatable/equatable.dart';

class FreightRoute extends Equatable {
  final String id;
  final String userId;
  final String origin;
  final String destination;
  final double distanceKm;
  final double baseRatePerKg;  // ₹ per kg for this specific route
  final bool isActive;
  final DateTime createdAt;

  const FreightRoute({
    required this.id,
    required this.userId,
    required this.origin,
    required this.destination,
    required this.distanceKm,
    required this.baseRatePerKg,
    this.isActive = true,
    required this.createdAt,
  });

  String get displayName => '$origin → $destination';

  FreightRoute copyWith({
    String? origin,
    String? destination,
    double? distanceKm,
    double? baseRatePerKg,
    bool? isActive,
  }) {
    return FreightRoute(
      id: id,
      userId: userId,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      distanceKm: distanceKm ?? this.distanceKm,
      baseRatePerKg: baseRatePerKg ?? this.baseRatePerKg,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'origin': origin,
    'destination': destination,
    'distanceKm': distanceKm,
    'baseRatePerKg': baseRatePerKg,
    'isActive': isActive,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory FreightRoute.fromMap(Map<String, dynamic> m) => FreightRoute(
    id: m['id'],
    userId: m['userId'] ?? '',
    origin: m['origin'],
    destination: m['destination'],
    distanceKm: (m['distanceKm'] as num).toDouble(),
    baseRatePerKg: (m['baseRatePerKg'] as num).toDouble(),
    isActive: m['isActive'] ?? true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
  );

  @override
  List<Object?> get props => [id, origin, destination, distanceKm, baseRatePerKg];
}
