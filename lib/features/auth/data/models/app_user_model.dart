import '../../domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.id,
    required super.name,
    required super.email,
    super.familyId,
    required super.createdAt,
    required super.emailVerified,
  });

  factory AppUserModel.fromMap(Map<String, dynamic> map, String id) {
    return AppUserModel(
      id: id,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      familyId: map['familyId'],
      createdAt: DateTime.parse(map['createdAt']),
      emailVerified: map['emailVerified'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'familyId': familyId,
      'createdAt': createdAt.toIso8601String(),
      'emailVerified': emailVerified,
    };
  }
}
