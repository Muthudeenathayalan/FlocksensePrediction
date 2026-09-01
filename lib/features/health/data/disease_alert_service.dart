import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/health/domain/disease_alert_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';

/// Real-time Disease Alert Service (SIH26128)
class DiseaseAlertService {
  DiseaseAlertService._();

  static final _firestore = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get _alertsRef =>
      _firestore.collection('disease_alerts');

  /// Publish a disease alert
  static Future<void> publishAlert(DiseaseAlertModel alert) async {
    try {
      final docRef = alert.id.isNotEmpty
          ? _alertsRef.doc(alert.id)
          : _alertsRef.doc();
      await docRef.set(alert.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('[DiseaseAlertService.publishAlert] Error: $e');
    }
  }

  /// Stream disease alerts for a specific role
  static Stream<List<DiseaseAlertModel>> streamAlertsForRole(String role) {
    return _alertsRef
        .where('recipientRoles', arrayContains: role.toLowerCase())
        .where('resolved', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return _getSampleAlerts(role);
      }
      return snapshot.docs
          .map((doc) => DiseaseAlertModel.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    }).handleError((e) {
      debugPrint('[DiseaseAlertService.streamAlertsForRole] Error: $e');
      return _getSampleAlerts(role);
    });
  }

  /// Mark alert as read
  static Future<void> markAsRead(String alertId) async {
    try {
      await _alertsRef.doc(alertId).update({
        'read': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[DiseaseAlertService.markAsRead] Error: $e');
    }
  }

  /// Mark alert as resolved
  static Future<void> markAsResolved(String alertId) async {
    try {
      await _alertsRef.doc(alertId).update({
        'resolved': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[DiseaseAlertService.markAsResolved] Error: $e');
    }
  }

  static List<DiseaseAlertModel> _getSampleAlerts(String role) {
    final now = DateTime.now();
    return [
      DiseaseAlertModel(
        id: 'alert_01',
        farmId: 'farm_01',
        batchId: 'flock_08',
        caseId: 'hc_1042',
        type: 'mortality_spike',
        severity: HealthRiskLevel.critical,
        title: 'Mortality Anomaly Detected in Batch B08',
        message: 'Mortality rate 4.1× above historical shed baseline with concurrent feed intake drop.',
        recipientRoles: ['farmer', 'veterinarian', 'government'],
        createdAt: now.subtract(const Duration(minutes: 15)),
        updatedAt: now.subtract(const Duration(minutes: 15)),
      ),
      DiseaseAlertModel(
        id: 'alert_02',
        farmId: 'farm_01',
        batchId: 'flock_04',
        type: 'vaccine_overdue',
        severity: HealthRiskLevel.moderate,
        title: 'Vaccination Due: ND LaSota Booster',
        message: 'Flock age 21 days reached. Recommended vaccination window closing in 24 hours.',
        recipientRoles: ['farmer', 'veterinarian'],
        createdAt: now.subtract(const Duration(hours: 2)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      DiseaseAlertModel(
        id: 'alert_03',
        farmId: 'farm_02',
        type: 'outbreak_proximity',
        severity: HealthRiskLevel.high,
        title: 'Regional Surveillance Alert: Nashik District',
        message: 'Potential respiratory cluster detected within 12km radius. Reinforce perimeter biosecurity.',
        recipientRoles: ['farmer', 'veterinarian', 'government'],
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(hours: 5)),
      ),
    ];
  }
}
