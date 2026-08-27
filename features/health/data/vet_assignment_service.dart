import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/health/domain/vet_assignment_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

/// Service for Veterinarian Case Assignments (SIH26128)
class VetAssignmentService {
  VetAssignmentService._();

  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('vet_assignments');

  /// Create a new assignment
  static Future<void> createAssignment(VetAssignmentModel assignment) async {
    try {
      final docRef = assignment.id.isNotEmpty
          ? _assignmentsRef.doc(assignment.id)
          : _assignmentsRef.doc();
      await docRef.set(assignment.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[VetAssignmentService.createAssignment] Error: $e');
    }
  }

  /// Stream assignments for a specific vet
  static Stream<List<VetAssignmentModel>> streamAssignmentsForVet(String vetId) {
    return _assignmentsRef
        .where('vetId', isEqualTo: vetId)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getSampleAssignments(vetId);
      }
      return snapshot.docs
          .map((doc) => VetAssignmentModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((e) {
      debugPrint('[VetAssignmentService.streamAssignmentsForVet] Error: $e');
      return _getSampleAssignments(vetId);
    });
  }

  /// Stream all statewide vet assignments for Government surveillance
  static Stream<List<VetAssignmentModel>> streamAllAssignments() {
    return _assignmentsRef
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getSampleAssignments('vet_all');
      }
      return snapshot.docs
          .map((doc) => VetAssignmentModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((e) {
      debugPrint('[VetAssignmentService.streamAllAssignments] Error: $e');
      return _getSampleAssignments('vet_all');
    });
  }

  /// Accept an assignment
  static Future<void> acceptAssignment(String assignmentId) async {
    try {
      await _assignmentsRef.doc(assignmentId).update({
        'status': VetAssignmentStatus.accepted.name,
        'acceptedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[VetAssignmentService.acceptAssignment] Error: $e');
    }
  }

  /// Complete an assignment
  static Future<void> completeAssignment(String assignmentId, {String? notes}) async {
    try {
      await _assignmentsRef.doc(assignmentId).update({
        'status': VetAssignmentStatus.completed.name,
        'completedAt': FieldValue.serverTimestamp(),
        if (notes != null) 'notes': notes,
      });
    } catch (e) {
      debugPrint('[VetAssignmentService.completeAssignment] Error: $e');
    }
  }

  static List<VetAssignmentModel> _getSampleAssignments(String vetId) {
    final now = DateTime.now();
    return [
      VetAssignmentModel(
        id: 'va_01',
        caseId: 'hc_1042',
        vetId: vetId,
        farmId: 'farm_01',
        farmName: 'Green Valley Poultry Farm',
        priority: HealthRiskLevel.critical,
        status: VetAssignmentStatus.in_progress,
        assignedAt: now.subtract(const Duration(hours: 3)),
        acceptedAt: now.subtract(const Duration(hours: 2)),
        notes: 'Priority clinical inspection requested for respiratory sounds in Shed 2.',
      ),
      VetAssignmentModel(
        id: 'va_02',
        caseId: 'hc_1041',
        vetId: vetId,
        farmId: 'farm_01',
        farmName: 'Green Valley Poultry Farm',
        priority: HealthRiskLevel.moderate,
        status: VetAssignmentStatus.completed,
        assignedAt: now.subtract(const Duration(days: 1)),
        acceptedAt: now.subtract(const Duration(days: 1)),
        completedAt: now.subtract(const Duration(hours: 12)),
        notes: 'Heat stress mitigation protocol provided.',
      ),
    ];
  }
}
