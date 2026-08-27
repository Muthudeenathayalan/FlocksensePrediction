import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/data/user_state_service.dart';
import 'package:flock_sense/features/auth/domain/user_model.dart';

/// Provider for UserStateService instance
final userStateServiceProvider = Provider<UserStateService>((ref) {
  return UserStateService();
});

/// Provider for current user state (single value)
final userStateProvider = FutureProvider<UserState>((ref) async {
  final service = ref.watch(userStateServiceProvider);
  return service.getUserState();
});

/// Provider for user state stream (reactive)
final userStateStreamProvider = StreamProvider<UserState>((ref) {
  final service = ref.watch(userStateServiceProvider);
  return service.getUserStateStream();
});

/// Authoritative Firestore User Profile stream provider
final currentUserProfileProvider = StreamProvider<UserModel?>((ref) {
  final service = ref.watch(userStateServiceProvider);
  return service.watchCurrentUserProfile();
});

/// Authoritative UserRole provider (defaults to farmer safely)
final currentUserRoleProvider = Provider<UserRole>((ref) {
  final profile = ref.watch(currentUserProfileProvider).value;
  return profile?.role ?? UserRole.farmer;
});
