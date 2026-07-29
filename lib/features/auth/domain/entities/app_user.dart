import 'package:equatable/equatable.dart';

class AppUser extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? familyId;
  final DateTime createdAt;
  final bool emailVerified;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.familyId,
    required this.createdAt,
    required this.emailVerified,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? familyId,
    DateTime? createdAt,
    bool? emailVerified,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      familyId: familyId ?? this.familyId,
      createdAt: createdAt ?? this.createdAt,
      emailVerified: emailVerified ?? this.emailVerified,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        familyId,
        createdAt,
        emailVerified,
      ];
}
