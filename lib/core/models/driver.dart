import 'package:equatable/equatable.dart';

class Driver extends Equatable {
  final String id;
  final String userId;
  final String name;
  final String licenseNo;
  final String phone;
  final bool isAvailable;
  final DateTime createdAt;

  const Driver({
    required this.id,
    required this.userId,
    required this.name,
    required this.licenseNo,
    required this.phone,
    this.isAvailable = true,
    required this.createdAt,
  });

  Driver copyWith({
    String? name,
    String? licenseNo,
    String? phone,
    bool? isAvailable,
  }) {
    return Driver(
      id: id,
      userId: userId,
      name: name ?? this.name,
      licenseNo: licenseNo ?? this.licenseNo,
      phone: phone ?? this.phone,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'licenseNo': licenseNo,
    'phone': phone,
    'isAvailable': isAvailable,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory Driver.fromMap(Map<String, dynamic> m) => Driver(
    id: m['id'],
    userId: m['userId'] ?? '',
    name: m['name'],
    licenseNo: m['licenseNo'],
    phone: m['phone'],
    isAvailable: m['isAvailable'] ?? true,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
  );

  @override
  List<Object?> get props => [id, name, licenseNo, phone, isAvailable];
}
