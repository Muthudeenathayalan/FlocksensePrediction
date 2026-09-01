import 'package:cloud_firestore/cloud_firestore.dart';

/// Standardized User Roles for FlockSense (SIH26128)
enum UserRole {
  farmer,
  veterinarian,
  government,
  admin;

  String get label {
    switch (this) {
      case UserRole.farmer:
        return 'Farmer';
      case UserRole.veterinarian:
        return 'Veterinarian';
      case UserRole.government:
        return 'Government Officer';
      case UserRole.admin:
        return 'System Administrator';
    }
  }

  static UserRole fromString(String? value) {
    if (value == null || value.isEmpty) return UserRole.farmer;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'veterinarian':
      case 'vet':
        return UserRole.veterinarian;
      case 'government':
      case 'gov':
      case 'officer':
        return UserRole.government;
      case 'admin':
      case 'administrator':
        return UserRole.admin;
      case 'farmer':
      default:
        return UserRole.farmer;
    }
  }
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.hasCompletedOnboarding,
    this.hasFarm = false,
    this.activeFarmId,
    this.district,
    this.state,
    this.phoneNumber,
    this.active = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool hasCompletedOnboarding;
  final bool hasFarm;
  final String? activeFarmId;
  final String? district;
  final String? state;
  final String? phoneNumber;
  final bool active;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get roleString => role.name;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String && v.isNotEmpty) {
        return DateTime.tryParse(v) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return UserModel(
      uid: json['uid'] as String? ?? '',
      name: json['name'] as String? ?? json['displayName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromString(json['role'] as String?),
      hasCompletedOnboarding: json['hasCompletedOnboarding'] as bool? ?? false,
      hasFarm: json['hasFarm'] as bool? ?? false,
      activeFarmId: json['activeFarmId'] as String?,
      district: json['district'] as String?,
      state: json['state'] as String?,
      phoneNumber: json['phoneNumber'] as String? ?? json['phone'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.name,
      'hasCompletedOnboarding': hasCompletedOnboarding,
      'hasFarm': hasFarm,
      if (activeFarmId != null) 'activeFarmId': activeFarmId,
      if (district != null) 'district': district,
      if (state != null) 'state': state,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      'active': active,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    bool? hasCompletedOnboarding,
    bool? hasFarm,
    String? activeFarmId,
    String? district,
    String? state,
    String? phoneNumber,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      hasCompletedOnboarding:
          hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      hasFarm: hasFarm ?? this.hasFarm,
      activeFarmId: activeFarmId ?? this.activeFarmId,
      district: district ?? this.district,
      state: state ?? this.state,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
