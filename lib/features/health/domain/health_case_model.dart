import 'package:cloud_firestore/cloud_firestore.dart';

/// Standardized Health Risk Levels (SIH26128)
enum HealthRiskLevel {
  low,
  moderate,
  high,
  critical;

  String get label {
    switch (this) {
      case HealthRiskLevel.low:
        return 'Low Risk';
      case HealthRiskLevel.moderate:
        return 'Moderate Risk';
      case HealthRiskLevel.high:
        return 'High Risk';
      case HealthRiskLevel.critical:
        return 'Critical Danger';
    }
  }

  /// Map score (0-100) to standard Risk Level
  static HealthRiskLevel fromScore(int score) {
    if (score >= 76) return HealthRiskLevel.critical;
    if (score >= 51) return HealthRiskLevel.high;
    if (score >= 31) return HealthRiskLevel.moderate;
    return HealthRiskLevel.low;
  }

  static HealthRiskLevel fromString(String? value) {
    if (value == null) return HealthRiskLevel.low;
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'critical':
      case 'severe':
        return HealthRiskLevel.critical;
      case 'high':
      case 'highrisk':
        return HealthRiskLevel.high;
      case 'moderate':
      case 'medium':
      case 'warning':
        return HealthRiskLevel.moderate;
      case 'low':
      case 'healthy':
      default:
        return HealthRiskLevel.low;
    }
  }
}

/// Standardized Health Case Lifecycle Status (SIH26128)
enum HealthCaseStatus {
  reported,
  risk_assessed,
  vet_required,
  vet_assigned,
  under_investigation,
  sample_requested,
  diagnosis_recorded,
  treatment_started,
  monitoring,
  closed,
  rejected;

  String get label {
    switch (this) {
      case HealthCaseStatus.reported:
        return 'Reported';
      case HealthCaseStatus.risk_assessed:
        return 'Risk Assessed';
      case HealthCaseStatus.vet_required:
        return 'Vet Required';
      case HealthCaseStatus.vet_assigned:
        return 'Vet Assigned';
      case HealthCaseStatus.under_investigation:
        return 'Under Investigation';
      case HealthCaseStatus.sample_requested:
        return 'Lab Sample Requested';
      case HealthCaseStatus.diagnosis_recorded:
        return 'Diagnosis Confirmed';
      case HealthCaseStatus.treatment_started:
        return 'Treatment Active';
      case HealthCaseStatus.monitoring:
        return 'Post-Treatment Monitoring';
      case HealthCaseStatus.closed:
        return 'Resolved & Closed';
      case HealthCaseStatus.rejected:
        return 'Rejected / False Alarm';
    }
  }

  static HealthCaseStatus fromString(String? value) {
    if (value == null) return HealthCaseStatus.reported;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final status in HealthCaseStatus.values) {
      if (status.name == normalized) return status;
    }
    // Backward compatibility aliases
    if (normalized == 'underreview' || normalized == 'under_review') {
      return HealthCaseStatus.under_investigation;
    }
    if (normalized == 'treatmentactive' || normalized == 'treatment_active') {
      return HealthCaseStatus.treatment_started;
    }
    if (normalized == 'resolved') {
      return HealthCaseStatus.closed;
    }
    return HealthCaseStatus.reported;
  }
}

/// Core Health Case Data Model (SIH26128)
class HealthCaseModel {
  final String id;
  final String caseNumber;
  final String farmId;
  final String farmName;
  final String flockId;
  final String flockName;
  final String? farmerId;
  final String? district;

  final int affectedCount;
  final int mortalityCount;
  final List<String> symptoms;
  final String notes;
  final List<String> imageUrls;

  // Environmental & Feed Vital Telemetry
  final double? feedReductionPercent;
  final double? waterReductionPercent;
  final double? temperature;
  final double? humidity;

  // AI & Disease Risk Scoring
  final int riskScore; // 0 - 100
  final HealthRiskLevel riskLevel;
  final List<String> riskReasons;
  final List<String> possibleDiseases;

  // Lifecycle, Escalation & Clinical Assignment
  final HealthCaseStatus status;
  final String? escalationStatus; // 'pending' | 'escalated' | 'vet_assigned' | 'district_queued'
  final String? assignedVetId;
  final String? veterinarianAssessment;
  final String? diagnosis;
  final bool labRequired;
  final String? treatmentPlanId;

  // Deduplication & Timestamps
  final String? incidentKey; // Format: farmId_batchId_YYYY-MM-DD
  final DateTime reportedAt;
  final DateTime updatedAt;

  const HealthCaseModel({
    required this.id,
    required this.caseNumber,
    required this.farmId,
    required this.farmName,
    required this.flockId,
    required this.flockName,
    this.farmerId,
    this.district,
    required this.affectedCount,
    required this.mortalityCount,
    required this.symptoms,
    this.notes = '',
    this.imageUrls = const [],
    this.feedReductionPercent,
    this.waterReductionPercent,
    this.temperature,
    this.humidity,
    this.riskScore = 0,
    required this.riskLevel,
    this.riskReasons = const [],
    this.possibleDiseases = const [],
    required this.status,
    this.escalationStatus,
    this.assignedVetId,
    this.veterinarianAssessment,
    this.diagnosis,
    this.labRequired = false,
    this.treatmentPlanId,
    this.incidentKey,
    required this.reportedAt,
    required this.updatedAt,
  });

  // UI Convenience Getters for Backward Compatibility
  String get batchId => flockId;
  String get veterinarianNotes => veterinarianAssessment ?? '';
  String get treatmentPrescribed => diagnosis ?? (notes.isNotEmpty ? notes : 'None');
  String get suspectedDisease => possibleDiseases.isNotEmpty
      ? possibleDiseases.first
      : (notes.isNotEmpty ? notes : 'Syndromic Anomaly');

  factory HealthCaseModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    double? parseOptionalDouble(dynamic v) {
      if (v == null) return null;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    final riskScore = parseInt(json['riskScore']);
    final parsedRisk = json['riskLevel'] != null
        ? HealthRiskLevel.fromString(json['riskLevel'].toString())
        : (riskScore > 0 ? HealthRiskLevel.fromScore(riskScore) : HealthRiskLevel.low);

    return HealthCaseModel(
      id: json['id'] as String? ?? '',
      caseNumber: json['caseNumber'] as String? ??
          'HC-${json['id']?.toString().substring(0, 6) ?? "1001"}',
      farmId: json['farmId'] as String? ?? '',
      farmName: json['farmName'] as String? ?? 'Primary Farm',
      flockId: json['flockId'] as String? ?? json['batchId'] as String? ?? '',
      flockName: json['flockName'] as String? ?? json['batchName'] as String? ?? 'Flock',
      farmerId: json['farmerId'] as String? ?? json['userId'] as String?,
      district: json['district'] as String?,
      affectedCount: parseInt(json['affectedCount'] ?? json['affectedBirds']),
      mortalityCount: parseInt(json['mortalityCount'] ?? json['mortality']),
      symptoms: parseList(json['symptoms']),
      notes: json['notes'] as String? ?? '',
      imageUrls: parseList(json['imageUrls'] ?? json['images']),
      feedReductionPercent: parseOptionalDouble(json['feedReductionPercent']),
      waterReductionPercent: parseOptionalDouble(json['waterReductionPercent']),
      temperature: parseOptionalDouble(json['temperature']),
      humidity: parseOptionalDouble(json['humidity']),
      riskScore: riskScore,
      riskLevel: parsedRisk,
      riskReasons: parseList(json['riskReasons']),
      possibleDiseases: parseList(json['possibleDiseases'] ?? json['differentialDiagnosis']),
      status: HealthCaseStatus.fromString(json['status'] as String?),
      escalationStatus: json['escalationStatus'] as String?,
      assignedVetId: json['assignedVetId'] as String?,
      veterinarianAssessment: json['veterinarianAssessment'] as String? ??
          json['veterinarianNotes'] as String?,
      diagnosis: json['diagnosis'] as String? ?? json['treatmentPrescribed'] as String?,
      labRequired: json['labRequired'] as bool? ?? false,
      treatmentPlanId: json['treatmentPlanId'] as String?,
      incidentKey: json['incidentKey'] as String?,
      reportedAt: parseDate(json['reportedAt'] ?? json['createdAt']),
      updatedAt: parseDate(json['updatedAt'] ?? json['reportedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caseNumber': caseNumber,
      'farmId': farmId,
      'farmName': farmName,
      'flockId': flockId,
      'flockName': flockName,
      if (farmerId != null) 'farmerId': farmerId,
      if (district != null) 'district': district,
      'affectedCount': affectedCount,
      'mortalityCount': mortalityCount,
      'symptoms': symptoms,
      'notes': notes,
      'imageUrls': imageUrls,
      if (feedReductionPercent != null)
        'feedReductionPercent': feedReductionPercent,
      if (waterReductionPercent != null)
        'waterReductionPercent': waterReductionPercent,
      if (temperature != null) 'temperature': temperature,
      if (humidity != null) 'humidity': humidity,
      'riskScore': riskScore,
      'riskLevel': riskLevel.name,
      'riskReasons': riskReasons,
      'possibleDiseases': possibleDiseases,
      'status': status.name,
      if (escalationStatus != null) 'escalationStatus': escalationStatus,
      if (assignedVetId != null) 'assignedVetId': assignedVetId,
      if (veterinarianAssessment != null)
        'veterinarianAssessment': veterinarianAssessment,
      if (diagnosis != null) 'diagnosis': diagnosis,
      'labRequired': labRequired,
      if (treatmentPlanId != null) 'treatmentPlanId': treatmentPlanId,
      if (incidentKey != null) 'incidentKey': incidentKey,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  HealthCaseModel copyWith({
    String? id,
    String? caseNumber,
    String? farmId,
    String? farmName,
    String? flockId,
    String? flockName,
    String? farmerId,
    String? district,
    int? affectedCount,
    int? mortalityCount,
    List<String>? symptoms,
    String? notes,
    List<String>? imageUrls,
    double? feedReductionPercent,
    double? waterReductionPercent,
    double? temperature,
    double? humidity,
    int? riskScore,
    HealthRiskLevel? riskLevel,
    List<String>? riskReasons,
    List<String>? possibleDiseases,
    HealthCaseStatus? status,
    String? escalationStatus,
    String? assignedVetId,
    String? veterinarianAssessment,
    String? diagnosis,
    bool? labRequired,
    String? treatmentPlanId,
    String? incidentKey,
    DateTime? reportedAt,
    DateTime? updatedAt,
  }) {
    return HealthCaseModel(
      id: id ?? this.id,
      caseNumber: caseNumber ?? this.caseNumber,
      farmId: farmId ?? this.farmId,
      farmName: farmName ?? this.farmName,
      flockId: flockId ?? this.flockId,
      flockName: flockName ?? this.flockName,
      farmerId: farmerId ?? this.farmerId,
      district: district ?? this.district,
      affectedCount: affectedCount ?? this.affectedCount,
      mortalityCount: mortalityCount ?? this.mortalityCount,
      symptoms: symptoms ?? this.symptoms,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      feedReductionPercent: feedReductionPercent ?? this.feedReductionPercent,
      waterReductionPercent:
          waterReductionPercent ?? this.waterReductionPercent,
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      riskScore: riskScore ?? this.riskScore,
      riskLevel: riskLevel ?? this.riskLevel,
      riskReasons: riskReasons ?? this.riskReasons,
      possibleDiseases: possibleDiseases ?? this.possibleDiseases,
      status: status ?? this.status,
      escalationStatus: escalationStatus ?? this.escalationStatus,
      assignedVetId: assignedVetId ?? this.assignedVetId,
      veterinarianAssessment:
          veterinarianAssessment ?? this.veterinarianAssessment,
      diagnosis: diagnosis ?? this.diagnosis,
      labRequired: labRequired ?? this.labRequired,
      treatmentPlanId: treatmentPlanId ?? this.treatmentPlanId,
      incidentKey: incidentKey ?? this.incidentKey,
      reportedAt: reportedAt ?? this.reportedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
