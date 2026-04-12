import 'package:equatable/equatable.dart';

enum UserRole { admin, viewer }

class AppUser extends Equatable {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.email,
    required this.name,
    this.role = UserRole.admin,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.admin;

  Map<String, dynamic> toMap() => {
    'id': id,
    'email': email,
    'name': name,
    'role': role.index,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
    id: m['id'],
    email: m['email'],
    name: m['name'],
    role: UserRole.values[m['role'] ?? 0],
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['createdAt']),
  );

  @override
  List<Object?> get props => [id, email, role];
}
