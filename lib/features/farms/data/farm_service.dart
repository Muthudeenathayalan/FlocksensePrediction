import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/core/exceptions/app_exceptions.dart';
import 'package:flock_sense/core/utils/input_sanitizer.dart';
import 'package:flock_sense/core/services/audit_service.dart';
import 'package:flock_sense/core/services/cache_service.dart';

/// Service for managing farm operations with enhanced error handling, validation, and caching.
class FarmService {
  FarmService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;
  static final _auditService = AuditService();
  static final _cacheService = CacheService();

  // In-memory fallback repository to ensure instantaneous reactivity
  static final List<FarmModel> _inMemoryFarms = [
    FarmModel(
      id: 'farm_01',
      userId: 'farmer_demo_user',
      ownerId: 'farmer_demo_user',
      farmName: 'Green Valley Poultry Farm',
      farmerName: 'Muthu Deenathayalan',
      farmType: 'EC',
      flockType: 'Broiler',
      address: 'Paramathi Velur, Namakkal, Tamil Nadu, India',
      areaName: 'Paramathi Velur',
      district: 'Namakkal',
      state: 'Tamil Nadu',
      country: 'India',
      lengthFt: 250,
      widthFt: 40,
      totalSqFt: 10000,
      capacity: 8500,
      status: 'active',
      isLocationAuto: true,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now(),
    ),
    FarmModel(
      id: 'farm_02',
      userId: 'farmer_demo_user',
      ownerId: 'farmer_demo_user',
      farmName: 'Sunrise Layer Facility',
      farmerName: 'Muthu Deenathayalan',
      farmType: 'Open',
      flockType: 'Layer',
      address: 'Udumalpet Highway, Pollachi, Coimbatore, Tamil Nadu, India',
      areaName: 'Pollachi',
      district: 'Coimbatore',
      state: 'Tamil Nadu',
      country: 'India',
      lengthFt: 180,
      widthFt: 35,
      totalSqFt: 6300,
      capacity: 5000,
      status: 'active',
      isLocationAuto: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
      updatedAt: DateTime.now(),
    ),
  ];

  static final StreamController<List<FarmModel>> _farmsStreamController =
      StreamController<List<FarmModel>>.broadcast();

  static String _getEffectiveUserId() {
    return _auth.currentUser?.uid ?? 'farmer_demo_user';
  }

  static void _notifyStream() {
    if (!_farmsStreamController.isClosed) {
      _farmsStreamController.add(List<FarmModel>.from(_inMemoryFarms));
    }
  }

  /// Creates a farm in Firestore or local cache
  static Future<FarmModel> createFarm({
    required String farmName,
    required String farmType,
    String flockType = 'Broiler',
    String address = '',
    String? areaName,
    String? district,
    String? state,
    String? country,
    String? farmerName,
    String? phoneNumber,
    String? notes,
    double lengthFt = 0,
    double widthFt = 0,
    double? totalSqFt,
    String sizeUnit = 'ft',
    bool isLocationAuto = true,
    int? capacity,
  }) async {
    debugPrint('[FarmService.createFarm] Registering new farm: $farmName');

    // Auto sign-in anonymously if currentUser is null and Firebase is initialized
    if (_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
      } catch (e) {
        debugPrint('[FarmService] Anonymous auth note: $e');
      }
    }

    final userId = _getEffectiveUserId();

    // Validate inputs
    if (!InputSanitizer.isValidFarmName(farmName)) {
      throw ValidationException(
        'Farm name must be between 2 and 100 characters',
      );
    }
    if (farmType.trim().isEmpty) {
      throw ValidationException('Farm type is required.');
    }

    final farmId = 'farm_${DateTime.now().millisecondsSinceEpoch}';
    final resolvedTotalSqFt = (totalSqFt != null && totalSqFt > 0)
        ? totalSqFt
        : (lengthFt > 0 && widthFt > 0
            ? lengthFt * widthFt
            : (capacity != null ? capacity * 1.2 : 5000.0));

    final effectiveAddress = address.trim().isNotEmpty
        ? address.trim()
        : [areaName, district, state ?? 'Tamil Nadu', country ?? 'India']
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(', ');

    final effectiveCapacity = capacity ?? (resolvedTotalSqFt / 1.2).round();

    final farm = FarmModel(
      id: farmId,
      userId: userId,
      ownerId: userId,
      farmName: farmName.trim(),
      farmerName: farmerName?.trim() ?? _auth.currentUser?.displayName ?? 'Farm Owner',
      farmType: farmType.trim(),
      flockType: flockType.trim(),
      address: effectiveAddress,
      lengthFt: lengthFt,
      widthFt: widthFt,
      totalSqFt: resolvedTotalSqFt,
      areaName: areaName?.trim() ?? (district != null ? district.trim() : null),
      capacity: effectiveCapacity,
      district: district?.trim() ?? 'Namakkal',
      state: state?.trim() ?? 'Tamil Nadu',
      country: country?.trim() ?? 'India',
      sizeUnit: sizeUnit,
      phoneNumber: phoneNumber?.trim() ?? _auth.currentUser?.phoneNumber,
      notes: notes?.trim(),
      isLocationAuto: isLocationAuto,
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Save to Firestore if user session is active
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final farmRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('farms')
            .doc(farmId);
        final userRef = _firestore.collection('users').doc(user.uid);

        final batch = _firestore.batch();
        batch.set(farmRef, farm.toJson());
        batch.set(userRef, {
          'hasFarm': true,
          'activeFarmId': farmId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        await batch.commit();
        debugPrint('[FarmService.createFarm] Saved to Firestore');
      }
    } catch (e) {
      debugPrint('[FarmService.createFarm] Firestore sync note: $e');
    }

    // Always update in-memory & Hive cache
    _inMemoryFarms.removeWhere((f) => f.id == farmId);
    _inMemoryFarms.insert(0, farm);
    _notifyStream();

    try {
      if (_cacheService.isInitialized) {
        await _cacheService.cacheFarm(userId, farm);
        await _cacheService.cacheFarms(userId, _inMemoryFarms);
      }
    } catch (e) {
      debugPrint('[FarmService.createFarm] Cache update note: $e');
    }

    // Log the operation
    try {
      await _auditService.logFarmCreate(
        farmId: farmId,
        farmName: farmName,
        farmType: farmType,
        additionalData: {'flockType': flockType, 'capacity': effectiveCapacity},
      );
    } catch (_) {}

    debugPrint('[FarmService.createFarm] Farm created successfully: ${farm.farmName}');
    return farm;
  }

  /// Updates an existing farm
  static Future<FarmModel> updateFarm({
    required String farmId,
    required String farmName,
    required String farmType,
    String flockType = 'Broiler',
    String? areaName,
    String? district,
    String? state,
    String? country,
    String address = '',
    required double lengthFt,
    required double widthFt,
    String sizeUnit = 'ft',
    bool isLocationAuto = true,
    int? capacity,
    String? notes,
  }) async {
    final userId = _getEffectiveUserId();

    if (!InputSanitizer.isValidFarmName(farmName)) {
      throw ValidationException(
        'Farm name must be between 2 and 100 characters',
      );
    }

    final totalSqFt = (lengthFt > 0 && widthFt > 0)
        ? lengthFt * widthFt
        : (capacity != null ? capacity * 1.2 : 5000.0);

    final effectiveAddress = address.trim().isNotEmpty
        ? address.trim()
        : [areaName, district, state ?? 'Tamil Nadu', country ?? 'India']
            .where((s) => s != null && s.trim().isNotEmpty)
            .join(', ');

    // Try Firestore update
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final farmRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('farms')
            .doc(farmId);

        await farmRef.set({
          'farmName': farmName,
          'farmType': farmType,
          'flockType': flockType,
          'address': effectiveAddress,
          'areaName': areaName,
          'district': district,
          'state': state,
          'country': country,
          'lengthFt': lengthFt,
          'widthFt': widthFt,
          'totalSqFt': totalSqFt,
          'sizeUnit': sizeUnit,
          if (capacity != null) 'capacity': capacity,
          if (notes != null) 'notes': notes,
          'isLocationAuto': isLocationAuto,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint('[FarmService.updateFarm] Firestore update note: $e');
    }

    final existingIndex = _inMemoryFarms.indexWhere((f) => f.id == farmId);
    FarmModel updated;
    if (existingIndex >= 0) {
      updated = _inMemoryFarms[existingIndex].copyWith(
        farmName: farmName,
        farmType: farmType,
        flockType: flockType,
        address: effectiveAddress,
        areaName: areaName,
        district: district,
        state: state,
        country: country,
        lengthFt: lengthFt,
        widthFt: widthFt,
        totalSqFt: totalSqFt,
        sizeUnit: sizeUnit,
        capacity: capacity ?? _inMemoryFarms[existingIndex].capacity,
        notes: notes ?? _inMemoryFarms[existingIndex].notes,
        isLocationAuto: isLocationAuto,
        updatedAt: DateTime.now(),
      );
      _inMemoryFarms[existingIndex] = updated;
    } else {
      updated = FarmModel(
        id: farmId,
        userId: userId,
        farmName: farmName,
        farmType: farmType,
        flockType: flockType,
        address: effectiveAddress,
        lengthFt: lengthFt,
        widthFt: widthFt,
        totalSqFt: totalSqFt,
        sizeUnit: sizeUnit,
        areaName: areaName,
        district: district,
        state: state,
        country: country,
        capacity: capacity,
        notes: notes,
        isLocationAuto: isLocationAuto,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      _inMemoryFarms.insert(0, updated);
    }

    _notifyStream();

    try {
      if (_cacheService.isInitialized) {
        await _cacheService.cacheFarm(userId, updated);
      }
    } catch (_) {}

    return updated;
  }

  /// Updates farm status (active/inactive)
  static Future<void> setFarmStatus({
    required String farmId,
    required bool isActive,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('farms')
            .doc(farmId)
            .set({
              'status': isActive ? 'active' : 'inactive',
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      } catch (_) {}
    }

    final index = _inMemoryFarms.indexWhere((f) => f.id == farmId);
    if (index >= 0) {
      _inMemoryFarms[index] = _inMemoryFarms[index].copyWith(
        status: isActive ? 'active' : 'inactive',
        updatedAt: DateTime.now(),
      );
      _notifyStream();
    }
  }

  /// Retrieves all farms for the current user
  static Future<List<FarmModel>> getUserFarms({
    bool forceRefresh = false,
  }) async {
    final userId = _getEffectiveUserId();

    // Check in-memory list first if not forcing Firestore refresh
    if (!forceRefresh && _inMemoryFarms.isNotEmpty) {
      return List<FarmModel>.from(_inMemoryFarms);
    }

    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('farms')
            .orderBy('createdAt', descending: true)
            .get();

        if (snapshot.docs.isNotEmpty) {
          final firestoreFarms = snapshot.docs.map((doc) {
            final data = doc.data();
            return FarmModel.fromJson({'id': doc.id, ...data, 'userId': user.uid});
          }).toList();

          // Merge with in-memory list
          for (final f in firestoreFarms) {
            if (!_inMemoryFarms.any((m) => m.id == f.id)) {
              _inMemoryFarms.add(f);
            }
          }
          return firestoreFarms;
        }
      } catch (e) {
        debugPrint('[FarmService.getUserFarms] Firestore fetch note: $e');
      }
    }

    // Check Hive cache
    try {
      if (_cacheService.isInitialized) {
        final cached = await _cacheService.getCachedFarms(userId);
        if (cached.isNotEmpty) {
          for (final f in cached) {
            if (!_inMemoryFarms.any((m) => m.id == f.id)) {
              _inMemoryFarms.add(f);
            }
          }
          return cached;
        }
      }
    } catch (_) {}

    return List<FarmModel>.from(_inMemoryFarms);
  }

  /// Returns the total area across all farms owned by the user
  static Future<double> getUserFarmArea(String uid) async {
    final farms = await getUserFarms();
    return farms.fold<double>(0.0, (acc, farm) => acc + farm.totalSqFt);
  }

  /// Real-time farm stream for a user
  static Stream<List<FarmModel>> watchFarms(String uid) {
    StreamController<List<FarmModel>>? controller;

    controller = StreamController<List<FarmModel>>(
      onListen: () {
        // 1. Emit current in-memory / cache data immediately
        controller?.add(List<FarmModel>.from(_inMemoryFarms));

        // 2. Listen to Firestore if authenticated
        final user = _auth.currentUser;
        if (user != null) {
          try {
            _firestore
                .collection('users')
                .doc(user.uid)
                .collection('farms')
                .orderBy('createdAt', descending: true)
                .snapshots()
                .listen(
              (snapshot) {
                if (snapshot.docs.isNotEmpty) {
                  final farms = snapshot.docs
                      .map((doc) => FarmModel.fromJson(
                          {'id': doc.id, ...doc.data(), 'userId': user.uid}))
                      .toList();
                  
                  // Update in-memory
                  for (final f in farms) {
                    final idx = _inMemoryFarms.indexWhere((m) => m.id == f.id);
                    if (idx >= 0) {
                      _inMemoryFarms[idx] = f;
                    } else {
                      _inMemoryFarms.add(f);
                    }
                  }
                  controller?.add(List<FarmModel>.from(_inMemoryFarms));
                }
              },
              onError: (err) {
                debugPrint('[FarmService.watchFarms] Firestore listener note: $err');
                // Emit in-memory fallback on error
                controller?.add(List<FarmModel>.from(_inMemoryFarms));
              },
            );
          } catch (_) {
            controller?.add(List<FarmModel>.from(_inMemoryFarms));
          }
        }
      },
    );

    return controller.stream;
  }

  /// Real-time farm stream for the currently signed-in user
  static Stream<List<FarmModel>> watchUserFarms() {
    return watchFarms(_getEffectiveUserId());
  }

  /// Retrieves a specific farm by ID
  static Future<FarmModel?> getFarmById(String farmId) async {
    // 1. Check in-memory
    final found = _inMemoryFarms.cast<FarmModel?>().firstWhere(
          (f) => f?.id == farmId,
          orElse: () => null,
        );
    if (found != null) return found;

    // 2. Check Firestore
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final snapshot = await _firestore
            .collection('users')
            .doc(user.uid)
            .collection('farms')
            .doc(farmId)
            .get();

        if (snapshot.exists && snapshot.data() != null) {
          final farm = FarmModel.fromJson(
              {'id': snapshot.id, ...snapshot.data()!, 'userId': user.uid});
          _inMemoryFarms.add(farm);
          return farm;
        }
      } catch (_) {}
    }

    return null;
  }

  /// Sets the active farm for the current user
  static Future<void> setActiveFarm(String farmId) async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).set({
          'activeFarmId': farmId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (_) {}
    }
  }

  /// Deletes a farm from user's collection
  static Future<void> deleteFarm(String farmId) async {
    final farm = await getFarmById(farmId);
    final user = _auth.currentUser;

    if (user != null) {
      try {
        final farmRef = _firestore
            .collection('users')
            .doc(user.uid)
            .collection('farms')
            .doc(farmId);
        await farmRef.delete();
      } catch (_) {}
    }

    _inMemoryFarms.removeWhere((f) => f.id == farmId);
    _notifyStream();

    if (farm != null) {
      try {
        await _auditService.logFarmDelete(
          farmId: farmId,
          farmName: farm.farmName,
        );
      } catch (_) {}
    }
  }

  /// Formats farm type for display
  static String getFormattedFarmType(String farmType) {
    const Map<String, String> farmTypes = {'ec': 'EC', 'open': 'Open'};
    return farmTypes[farmType.toLowerCase()] ?? farmType;
  }

  /// Get raw user document
  static Future<Map<String, dynamic>?> getUserDoc(String uid) async {
    try {
      final snap = await _firestore.collection('users').doc(uid).get();
      return snap.data();
    } catch (_) {
      return null;
    }
  }

  /// Clears local cache
  static Future<void> clearCache() async {
    try {
      if (_cacheService.isInitialized) {
        await _cacheService.clearAll();
      }
    } catch (_) {}
  }
}
