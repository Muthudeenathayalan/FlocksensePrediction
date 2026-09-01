import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flock_sense/features/auth/domain/user_model.dart';

enum UserState { unauthenticated, onboarding, farmSetup, authenticated }

class UserStateService {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  /// Resolves the current user's position and profile from Firestore.
  Future<UserState> getUserState() async {
    final user = _auth.currentUser;
    if (user == null) return UserState.unauthenticated;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      if (!doc.exists || doc.data() == null) return UserState.onboarding;

      final data = doc.data()!;
      final onboarded = data['hasCompletedOnboarding'] as bool? ?? false;
      if (!onboarded) return UserState.onboarding;

      final hasFarm = data['hasFarm'] as bool? ?? false;
      final activeFarmId = data['activeFarmId'] as String?;
      if (!hasFarm || (activeFarmId?.isEmpty ?? true)) {
        return UserState.farmSetup;
      }

      return UserState.authenticated;
    } catch (_) {
      if (_auth.currentUser != null) return UserState.authenticated;
      return UserState.unauthenticated;
    }
  }

  /// Get current user profile with role from Firestore
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson({'uid': user.uid, ...doc.data()!});
      }
    } catch (_) {}

    return UserModel(
      uid: user.uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      role: UserRole.farmer,
      hasCompletedOnboarding: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Watch authoritative user model stream from Firestore
  Stream<UserModel?> watchCurrentUserProfile() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield null;
      } else {
        yield* _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .map((snap) {
          if (!snap.exists || snap.data() == null) {
            return UserModel(
              uid: user.uid,
              name: user.displayName ?? '',
              email: user.email ?? '',
              role: UserRole.farmer,
              hasCompletedOnboarding: true,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
          }
          return UserModel.fromJson({'uid': user.uid, ...snap.data()!});
        });
      }
    });
  }

  Stream<UserState> getUserStateStream() {
    return _auth.authStateChanges().asyncExpand((user) async* {
      if (user == null) {
        yield UserState.unauthenticated;
      } else {
        yield* _firestore
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .asyncMap((_) => getUserState());
      }
    });
  }

  bool isAuthenticated() => _auth.currentUser != null;
  User? getCurrentUser() => _auth.currentUser;
  Future<void> signOut() => _auth.signOut();
}
