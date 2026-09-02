import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/core/constants/firestore_collections.dart';
import 'package:flock_sense/features/intelligence/data/visitor_exposure_engine.dart';
import 'package:flock_sense/features/intelligence/domain/visitor_event_model.dart';

/// Service for persisting and querying farm visitor events (Part 5)
class VisitorService {
  VisitorService._();

  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _visitorRef =>
      _firestore.collection(FirestoreCollections.visitorEvents);

  /// Streams visitor events for a specific farm
  static Stream<List<VisitorEventModel>> streamVisitorEvents(String farmId) {
    return _visitorRef
        .where('farmId', isEqualTo: farmId)
        .snapshots()
        .map((snap) {
      final events = snap.docs.map((d) {
        final data = d.data();
        return VisitorEventModel.fromJson({
          ...data,
          'id': data['id'] ?? d.id,
        });
      }).toList();

      events.sort((a, b) => b.enteredAt.compareTo(a.enteredAt));
      return events;
    }).handleError((e) {
      debugPrint('[VisitorService.streamVisitorEvents] Error: $e');
      return <VisitorEventModel>[];
    });
  }

  /// Logs a new visitor event and computes exposure score
  static Future<VisitorEventModel> logVisitorEvent({
    required String farmId,
    required String visitorName,
    String visitorType = 'visitor',
    String organization = '',
    required String purpose,
    required DateTime enteredAt,
    DateTime? exitedAt,
    bool visitedLivestockFarmRecently = false,
    bool vehicleEntered = false,
    bool footwearDisinfected = true,
    bool vehicleDisinfected = true,
    bool ppeUsed = true,
    List<String> areasVisited = const ['shed'],
    bool sharedEquipment = false,
    bool newAnimalIntroductionRelated = false,
    String notes = '',
    String createdBy = 'Farmer',
  }) async {
    final docRef = _visitorRef.doc();
    final now = DateTime.now();

    final draft = VisitorEventModel(
      id: docRef.id,
      farmId: farmId,
      visitorName: visitorName,
      visitorType: visitorType,
      organization: organization,
      purpose: purpose,
      enteredAt: enteredAt,
      exitedAt: exitedAt,
      visitedLivestockFarmRecently: visitedLivestockFarmRecently,
      vehicleEntered: vehicleEntered,
      footwearDisinfected: footwearDisinfected,
      vehicleDisinfected: vehicleDisinfected,
      ppeUsed: ppeUsed,
      areasVisited: areasVisited,
      sharedEquipment: sharedEquipment,
      newAnimalIntroductionRelated: newAnimalIntroductionRelated,
      notes: notes,
      createdBy: createdBy,
      createdAt: now,
    );

    final score = VisitorExposureEngine.scoreEvent(draft);
    final eventWithScore = VisitorEventModel(
      id: draft.id,
      farmId: draft.farmId,
      visitorName: draft.visitorName,
      visitorType: draft.visitorType,
      organization: draft.organization,
      purpose: draft.purpose,
      enteredAt: draft.enteredAt,
      exitedAt: draft.exitedAt,
      visitedLivestockFarmRecently: draft.visitedLivestockFarmRecently,
      vehicleEntered: draft.vehicleEntered,
      footwearDisinfected: draft.footwearDisinfected,
      vehicleDisinfected: draft.vehicleDisinfected,
      ppeUsed: draft.ppeUsed,
      areasVisited: draft.areasVisited,
      sharedEquipment: draft.sharedEquipment,
      newAnimalIntroductionRelated: draft.newAnimalIntroductionRelated,
      notes: draft.notes,
      exposureScore: score,
      createdBy: draft.createdBy,
      createdAt: draft.createdAt,
    );

    try {
      await docRef.set(eventWithScore.toJson());
    } catch (e) {
      debugPrint('[VisitorService.logVisitorEvent] Persistence error: $e');
    }

    return eventWithScore;
  }
}
