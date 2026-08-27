import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/health/domain/disease_alert_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/risk_assessment_model.dart';
import 'package:flock_sense/features/health/domain/vet_assignment_model.dart';
import 'package:flock_sense/features/notifications/data/models/notification_model.dart';

/// Central Health Case Escalation & Alerting Service (SIH26128 Phase 5)
class EscalationService {
  EscalationService._();

  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _casesRef =>
      _firestore.collection('health_cases');
  static CollectionReference<Map<String, dynamic>> get _alertsRef =>
      _firestore.collection('disease_alerts');
  static CollectionReference<Map<String, dynamic>> get _assignmentsRef =>
      _firestore.collection('vet_assignments');
  static CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');
  static CollectionReference<Map<String, dynamic>> get _auditLogsRef =>
      _firestore.collection('audit_logs');

  /// Calculate triage priority score (0-100) and priority level
  static ({int score, VetPriorityLevel level}) calculatePriorityScore({
    required HealthRiskLevel riskLevel,
    required int riskScore,
    required int mortalityCount,
    required int affectedCount,
    List<String> riskReasons = const [],
  }) {
    int score = 0;

    // 1. Base Score from Risk Level
    if (riskLevel == HealthRiskLevel.critical) {
      score += 60;
    } else if (riskLevel == HealthRiskLevel.high) {
      score += 40;
    } else if (riskLevel == HealthRiskLevel.moderate) {
      score += 20;
    } else {
      score += 5;
    }

    // 2. Mortality severity modifier
    if (mortalityCount >= 15) {
      score += 20;
    } else if (mortalityCount >= 10) {
      score += 15;
    } else if (mortalityCount >= 5) {
      score += 10;
    } else if (mortalityCount > 0) {
      score += 5;
    }

    // 3. Affected count modifier
    if (affectedCount >= 100) {
      score += 15;
    } else if (affectedCount >= 50) {
      score += 10;
    } else if (affectedCount >= 20) {
      score += 5;
    }

    // 4. Acute spike modifier
    final hasSpike = riskReasons.any((r) =>
        r.toLowerCase().contains('spike') ||
        r.toLowerCase().contains('anomaly') ||
        r.toLowerCase().contains('critical') ||
        r.toLowerCase().contains('sudden'));
    if (hasSpike || mortalityCount >= 10) {
      score += 10;
    }

    // Bound to 0 - 100
    final finalScore = score.clamp(0, 100);
    final level = VetPriorityLevel.fromRiskAndPriority(riskLevel, finalScore);

    return (score: finalScore, level: level);
  }

  /// Format dynamic waiting duration for UI presentation
  static String formatWaitingTime(DateTime? time) {
    if (time == null) return '0 min';
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) {
      return '${diff.inDays}d ${diff.inHours % 24}h';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h ${diff.inMinutes % 60}m';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min';
    }
    return 'Just now';
  }

  /// Evaluates and persists automatic escalation for a health case
  static Future<VetAssignmentModel?> evaluateAndEscalateCase({
    required HealthCaseModel healthCase,
    RiskAssessmentModel? riskAssessment,
    String? district,
  }) async {
    final effectiveRisk = riskAssessment?.riskLevel ?? healthCase.riskLevel;
    final effectiveScore = riskAssessment?.score ?? healthCase.riskScore;
    final effectiveReasons = riskAssessment?.reasons ?? healthCase.riskReasons;
    final effectiveDistrict = (district ?? healthCase.district ?? 'Nashik').trim();

    final priorityResult = calculatePriorityScore(
      riskLevel: effectiveRisk,
      riskScore: effectiveScore,
      mortalityCount: healthCase.mortalityCount,
      affectedCount: healthCase.affectedCount,
      riskReasons: effectiveReasons,
    );

    // 1. Policy: LOW risk -> monitoring only
    if (effectiveRisk == HealthRiskLevel.low) {
      debugPrint('[EscalationService] Case ${healthCase.id} is LOW risk. No escalation.');
      return null;
    }

    // 2. Policy: MODERATE risk -> farmer warning notification only
    if (effectiveRisk == HealthRiskLevel.moderate) {
      debugPrint('[EscalationService] Case ${healthCase.id} is MODERATE risk. Farmer advisory notification.');
      if (healthCase.farmerId != null && healthCase.farmerId!.isNotEmpty) {
        final notifId = 'notif_${healthCase.id}_mod_${DateTime.now().millisecondsSinceEpoch}';
        await _usersRef
            .doc(healthCase.farmerId)
            .collection('notifications')
            .doc(notifId)
            .set({
          'id': notifId,
          'title': 'Flock Health Advisory: ${healthCase.flockName}',
          'body': 'Moderate health risk score ($effectiveScore/100) detected. Continue active twice-daily monitoring.',
          'type': NotificationType.ai.name,
          'priority': NotificationPriority.normal.name,
          'status': NotificationStatus.unread.name,
          'createdAt': Timestamp.now(),
          'relatedFarmId': healthCase.farmId,
          'relatedBatchId': healthCase.flockId,
          'actionUrl': '/health/cases/${healthCase.id}',
          'metadata': {
            'caseId': healthCase.id,
            'riskScore': effectiveScore,
            'riskLevel': effectiveRisk.name,
          },
        }, SetOptions(merge: true));
      }
      return null;
    }

    // 3. HIGH or CRITICAL -> Full Escalation Pipeline
    debugPrint('[EscalationService] Escalating case ${healthCase.id} (${effectiveRisk.name.toUpperCase()}, Priority: ${priorityResult.score} ${priorityResult.level.name})');

    // Step A: Discover Veterinarian in District
    String assignedVetId = '';
    String assignedVetName = '';

    try {
      final vetQuery = await _usersRef
          .where('role', isEqualTo: 'veterinarian')
          .where('active', isEqualTo: true)
          .limit(10)
          .get();

      for (final doc in vetQuery.docs) {
        final data = doc.data();
        final vetDistrict = data['district'] as String?;
        if (vetDistrict != null &&
            vetDistrict.toLowerCase() == effectiveDistrict.toLowerCase()) {
          assignedVetId = doc.id;
          assignedVetName = data['displayName'] as String? ??
              data['name'] as String? ??
              'Dr. District Veterinarian';
          break;
        }
      }
    } catch (e) {
      debugPrint('[EscalationService] Vet discovery error: $e');
    }

    final isAssigned = assignedVetId.isNotEmpty;
    final assignmentMethod = isAssigned ? 'automatic_district' : 'queue';
    final updatedCaseStatus = isAssigned
        ? HealthCaseStatus.vet_assigned
        : HealthCaseStatus.vet_required;

    // Step B: Create / Update Disease Alert
    final alertId = 'alert_${healthCase.id}_${effectiveRisk.name}_escalation-v1';
    final cleanReasons = effectiveReasons.take(3).join(' • ');
    final alertTitle = effectiveRisk == HealthRiskLevel.critical
        ? 'CRITICAL ANIMAL HEALTH ALERT'
        : 'High Health Risk Detected';
    final alertMessage = '${healthCase.farmName} • Batch ${healthCase.flockName} — Risk Score: $effectiveScore/100. $cleanReasons. Veterinary review recommended.';

    final diseaseAlert = DiseaseAlertModel(
      id: alertId,
      farmId: healthCase.farmId,
      batchId: healthCase.flockId,
      caseId: healthCase.id,
      type: effectiveRisk == HealthRiskLevel.critical
          ? 'critical_health_risk'
          : 'health_risk',
      severity: effectiveRisk,
      title: alertTitle,
      message: alertMessage,
      recipientRoles: const ['farmer', 'veterinarian', 'government'],
      read: false,
      resolved: false,
      deduplicationKey: '${healthCase.id}_${effectiveRisk.name}_escalation-v1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Step C: Create / Update Vet Assignment (Enforce ONE active assignment)
    final assignmentId = 'va_${healthCase.id}_escalation-v1';
    final vetAssignment = VetAssignmentModel(
      id: assignmentId,
      caseId: healthCase.id,
      caseNumber: healthCase.caseNumber,
      vetId: assignedVetId,
      vetName: isAssigned ? assignedVetName : 'Unassigned (District Queue)',
      farmId: healthCase.farmId,
      farmName: healthCase.farmName,
      flockId: healthCase.flockId,
      flockName: healthCase.flockName,
      district: effectiveDistrict,
      districtQueue: isAssigned ? null : effectiveDistrict,
      priority: effectiveRisk,
      priorityScore: priorityResult.score,
      priorityLevel: priorityResult.level,
      status: isAssigned
          ? VetAssignmentStatus.pending
          : VetAssignmentStatus.unassigned,
      assignmentMethod: assignmentMethod,
      mortalityCount: healthCase.mortalityCount,
      affectedCount: healthCase.affectedCount,
      symptoms: healthCase.symptoms,
      assignedAt: DateTime.now(),
      deduplicationKey: '${healthCase.id}_assignment_escalation-v1',
    );

    // Step D: Write to Firestore atomically via Batch
    try {
      final batch = _firestore.batch();

      // 1. Update HealthCase
      batch.update(_casesRef.doc(healthCase.id), {
        'status': updatedCaseStatus.name,
        'escalationStatus': isAssigned ? 'vet_assigned' : 'district_queued',
        'assignedVetId': assignedVetId.isNotEmpty ? assignedVetId : null,
        'district': effectiveDistrict,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Write DiseaseAlert
      batch.set(_alertsRef.doc(alertId), diseaseAlert.toJson(),
          SetOptions(merge: true));

      // 3. Write VetAssignment
      batch.set(_assignmentsRef.doc(assignmentId), vetAssignment.toJson(),
          SetOptions(merge: true));

      // 4. Write Farmer Notification
      if (healthCase.farmerId != null && healthCase.farmerId!.isNotEmpty) {
        final farmerNotifId = 'notif_${healthCase.id}_farmer_escalation-v1';
        final notifTitle = effectiveRisk == HealthRiskLevel.critical
            ? '🚨 Critical Health Case Escalated'
            : '⚠️ Health Case Escalated for Review';
        final notifBody = isAssigned
            ? 'Your health report for ${healthCase.flockName} ($effectiveScore/100) has been assigned to $assignedVetName for veterinary triage.'
            : 'Your health report for ${healthCase.flockName} ($effectiveScore/100) has been queued for district veterinary review.';

        final farmerNotifRef = _usersRef
            .doc(healthCase.farmerId)
            .collection('notifications')
            .doc(farmerNotifId);

        batch.set(farmerNotifRef, {
          'id': farmerNotifId,
          'title': notifTitle,
          'body': notifBody,
          'type': NotificationType.ai.name,
          'priority': effectiveRisk == HealthRiskLevel.critical
              ? NotificationPriority.critical.name
              : NotificationPriority.high.name,
          'status': NotificationStatus.unread.name,
          'createdAt': Timestamp.now(),
          'relatedFarmId': healthCase.farmId,
          'relatedBatchId': healthCase.flockId,
          'actionUrl': '/health/cases/${healthCase.id}',
          'metadata': {
            'caseId': healthCase.id,
            'riskScore': effectiveScore,
            'riskLevel': effectiveRisk.name,
            'assignedVetName': isAssigned ? assignedVetName : null,
          },
        }, SetOptions(merge: true));
      }

      // 5. Write Vet Notification (if assigned)
      if (isAssigned) {
        final vetNotifId = 'notif_${healthCase.id}_vet_escalation-v1';
        final vetTitle = effectiveRisk == HealthRiskLevel.critical
            ? '🚨 CRITICAL CASE: ${healthCase.farmName}'
            : '⚠️ High Risk Case: ${healthCase.farmName}';
        final vetBody = 'Batch ${healthCase.flockName} reported with $effectiveScore/100 risk (${healthCase.mortalityCount} mortality, ${healthCase.affectedCount} affected). Priority: ${priorityResult.level.label}.';

        final vetNotifRef = _usersRef
            .doc(assignedVetId)
            .collection('notifications')
            .doc(vetNotifId);

        batch.set(vetNotifRef, {
          'id': vetNotifId,
          'title': vetTitle,
          'body': vetBody,
          'type': NotificationType.ai.name,
          'priority': effectiveRisk == HealthRiskLevel.critical
              ? NotificationPriority.critical.name
              : NotificationPriority.high.name,
          'status': NotificationStatus.unread.name,
          'createdAt': Timestamp.now(),
          'relatedFarmId': healthCase.farmId,
          'relatedBatchId': healthCase.flockId,
          'actionUrl': '/health/cases/${healthCase.id}',
          'metadata': {
            'caseId': healthCase.id,
            'riskScore': effectiveScore,
            'riskLevel': effectiveRisk.name,
            'priorityScore': priorityResult.score,
            'priorityLevel': priorityResult.level.name,
          },
        }, SetOptions(merge: true));
      }

      await batch.commit();

      // Write Audit Log
      await _auditLogsRef.add({
        'operation': 'dataSync',
        'resourceType': 'HealthEscalation',
        'resourceId': healthCase.id,
        'timestamp': FieldValue.serverTimestamp(),
        'changes': {
          'action': isAssigned ? 'HEALTH_CASE_ESCALATED' : 'VET_QUEUE_ESCALATED',
          'caseId': healthCase.id,
          'riskLevel': effectiveRisk.name,
          'priorityScore': priorityResult.score,
          'priorityLevel': priorityResult.level.name,
          'assignedVetId': isAssigned ? assignedVetId : 'district_queue',
          'district': effectiveDistrict,
        },
      });

      debugPrint('[EscalationService] Successfully committed escalation for case ${healthCase.id}');
      return vetAssignment;
    } catch (e) {
      debugPrint('[EscalationService] Error committing escalation: $e');
      return vetAssignment;
    }
  }

  /// Stream live priority queue for a specific veterinarian or district
  static Stream<List<VetAssignmentModel>> streamVetPriorityQueue({
    String? vetId,
    String? district,
  }) {
    Query<Map<String, dynamic>> query = _assignmentsRef;

    if (vetId != null && vetId.isNotEmpty) {
      query = query.where('vetId', isEqualTo: vetId);
    } else if (district != null && district.isNotEmpty) {
      query = query.where('district', isEqualTo: district);
    }

    return query.snapshots().map((snap) {
      if (snap.docs.isEmpty) {
        return _getSamplePriorityQueue(vetId: vetId, district: district);
      }

      final list = snap.docs.map((doc) {
        return VetAssignmentModel.fromJson({
          ...doc.data(),
          'id': doc.id,
        });
      }).toList();

      // In-memory compound sort: CRITICAL first, then oldest waiting duration first
      list.sort((a, b) {
        // 1. Priority score descending
        final scoreComp = b.priorityScore.compareTo(a.priorityScore);
        if (scoreComp != 0) return scoreComp;
        // 2. Assigned time ascending (oldest waiting first)
        return a.assignedAt.compareTo(b.assignedAt);
      });

      return list;
    }).handleError((e) {
      debugPrint('[EscalationService.streamVetPriorityQueue] Error: $e');
      return _getSamplePriorityQueue(vetId: vetId, district: district);
    });
  }

  /// Stream unassigned district queue cases
  static Stream<List<VetAssignmentModel>> streamUnassignedDistrictQueue(String district) {
    return _assignmentsRef
        .where('districtQueue', isEqualTo: district)
        .where('status', isEqualTo: VetAssignmentStatus.unassigned.name)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map((doc) => VetAssignmentModel.fromJson({
        ...doc.data(),
        'id': doc.id,
      })).toList();

      list.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
      return list;
    }).handleError((e) {
      debugPrint('[EscalationService.streamUnassignedDistrictQueue] Error: $e');
      return [];
    });
  }

  /// Fallback demo/mock queue
  static List<VetAssignmentModel> _getSamplePriorityQueue({String? vetId, String? district}) {
    final now = DateTime.now();
    return [
      VetAssignmentModel(
        id: 'va_demo_01',
        caseId: 'hc_2026_00128',
        caseNumber: 'HC-2026-00128',
        vetId: vetId ?? 'vet_dr_sharma',
        vetName: 'Dr. V. Sharma (Surgeon)',
        farmId: 'farm_green_valley',
        farmName: 'Green Valley Poultry Farm',
        flockId: 'flock_b07',
        flockName: 'Cobb 500 (Batch B07)',
        district: district ?? 'Nashik',
        priority: HealthRiskLevel.critical,
        priorityScore: 92,
        priorityLevel: VetPriorityLevel.critical,
        status: VetAssignmentStatus.pending,
        assignmentMethod: 'automatic_district',
        mortalityCount: 15,
        affectedCount: 120,
        symptoms: const ['Coughing', 'Respiratory Difficulty', 'Weakness'],
        assignedAt: now.subtract(const Duration(minutes: 8)),
        notes: 'Acute respiratory rales, gasping, and elevated morning mortality in Shed 2.',
      ),
      VetAssignmentModel(
        id: 'va_demo_02',
        caseId: 'hc_2026_00125',
        caseNumber: 'HC-2026-00125',
        vetId: vetId ?? 'vet_dr_sharma',
        vetName: 'Dr. V. Sharma (Surgeon)',
        farmId: 'farm_sunrise',
        farmName: 'Sunrise Agro Broilers',
        flockId: 'flock_s02',
        flockName: 'Ross 308 (Batch S02)',
        district: district ?? 'Nashik',
        priority: HealthRiskLevel.high,
        priorityScore: 68,
        priorityLevel: VetPriorityLevel.urgent,
        status: VetAssignmentStatus.in_progress,
        assignmentMethod: 'automatic_district',
        mortalityCount: 6,
        affectedCount: 45,
        symptoms: const ['Sneezing', 'Reduced Feed Intake'],
        assignedAt: now.subtract(const Duration(minutes: 45)),
        acceptedAt: now.subtract(const Duration(minutes: 30)),
        notes: 'Feed consumption drop of 14% with localized sneezing.',
      ),
      VetAssignmentModel(
        id: 'va_demo_03',
        caseId: 'hc_2026_00119',
        caseNumber: 'HC-2026-00119',
        vetId: '',
        vetName: 'Unassigned (District Queue)',
        farmId: 'farm_apex',
        farmName: 'Apex Poultry Unit',
        flockId: 'flock_a01',
        flockName: 'Cobb 430 (Batch A01)',
        district: district ?? 'Nashik',
        districtQueue: district ?? 'Nashik',
        priority: HealthRiskLevel.high,
        priorityScore: 58,
        priorityLevel: VetPriorityLevel.urgent,
        status: VetAssignmentStatus.unassigned,
        assignmentMethod: 'queue',
        mortalityCount: 4,
        affectedCount: 28,
        symptoms: const ['Diarrhoea', 'Lethargy'],
        assignedAt: now.subtract(const Duration(hours: 2)),
        notes: 'Watery reddish droppings noted in Shed 1.',
      ),
    ];
  }
}
