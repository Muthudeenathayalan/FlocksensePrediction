import 'package:cloud_firestore/cloud_firestore.dart';

/// Full Laboratory Diagnostic Sample & Test Lifecycle Status (SIH26128 Phase 7)
enum LabTestStatus {
  requested,
  sample_ready,
  collected,
  dispatched,
  received,
  testing,
  result_available,
  reviewed,
  cancelled,
  rejected,
  inconclusive;

  String get label {
    switch (this) {
      case LabTestStatus.requested:
        return 'Test Requested';
      case LabTestStatus.sample_ready:
        return 'Sample Ready for Pickup';
      case LabTestStatus.collected:
        return 'Sample Collected';
      case LabTestStatus.dispatched:
        return 'In Transit to Lab';
      case LabTestStatus.received:
        return 'Received at Laboratory';
      case LabTestStatus.testing:
        return 'Analysis / PCR in Progress';
      case LabTestStatus.result_available:
        return 'Results Available';
      case LabTestStatus.reviewed:
        return 'Veterinary Reviewed & Confirmed';
      case LabTestStatus.cancelled:
        return 'Test Cancelled';
      case LabTestStatus.rejected:
        return 'Sample Rejected / Unsuitable';
      case LabTestStatus.inconclusive:
        return 'Inconclusive / Repeat Needed';
    }
  }

  static LabTestStatus fromString(String? value) {
    if (value == null) return LabTestStatus.requested;
    final normalized = value.trim().toLowerCase().replaceAll('-', '_');
    for (final status in LabTestStatus.values) {
      if (status.name == normalized) return status;
    }
    // Backward compatibility aliases
    if (normalized == 'completed') return LabTestStatus.result_available;
    return LabTestStatus.requested;
  }
}

/// Standardized Diagnostic Result Categories
enum LabResultCategory {
  positive,
  negative,
  inconclusive,
  invalid;

  String get label {
    switch (this) {
      case LabResultCategory.positive:
        return 'Positive (Pathogen Detected)';
      case LabResultCategory.negative:
        return 'Negative (Not Detected)';
      case LabResultCategory.inconclusive:
        return 'Inconclusive (Equivocal Titers)';
      case LabResultCategory.invalid:
        return 'Invalid / Quality Control Failed';
    }
  }

  static LabResultCategory fromString(String? value) {
    if (value == null) return LabResultCategory.inconclusive;
    final normalized = value.trim().toLowerCase();
    for (final c in LabResultCategory.values) {
      if (c.name == normalized) return c;
    }
    if (normalized.contains('pos')) return LabResultCategory.positive;
    if (normalized.contains('neg')) return LabResultCategory.negative;
    return LabResultCategory.inconclusive;
  }
}

/// Sample Condition upon Laboratory Arrival
enum SampleReceiptCondition {
  acceptable,
  damaged,
  insufficient,
  contaminated,
  other;

  String get label {
    switch (this) {
      case SampleReceiptCondition.acceptable:
        return 'Acceptable (Intact & Cold-Chained)';
      case SampleReceiptCondition.damaged:
        return 'Damaged in Transit';
      case SampleReceiptCondition.insufficient:
        return 'Insufficient Sample Volume';
      case SampleReceiptCondition.contaminated:
        return 'Sample Contaminated / Hemolyzed';
      case SampleReceiptCondition.other:
        return 'Other Irregularity';
    }
  }

  static SampleReceiptCondition fromString(String? value) {
    if (value == null) return SampleReceiptCondition.acceptable;
    final normalized = value.trim().toLowerCase();
    for (final c in SampleReceiptCondition.values) {
      if (c.name == normalized) return c;
    }
    return SampleReceiptCondition.acceptable;
  }
}

/// Comprehensive Laboratory Diagnostic Sample & Test Model (SIH26128 Phase 7)
class LabTestModel {
  final String id;
  final String sampleId;
  final String caseId;
  final String farmId;
  final String batchId;

  final String sampleType; // 'Tracheal Swab', 'Cloacal Swab', 'Serum', 'Tissue Biopsy'
  final String testRequested; // 'RT-PCR Viral Panel', 'ELISA Serology', 'Bacterial Culture'
  final String priority; // 'routine' | 'urgent' | 'emergency'

  // 1. Request Stage
  final String requestedBy;
  final DateTime requestedAt;
  final String? assignedLabId;
  final String? labName;
  final LabTestStatus status;

  // 2. Sample Collection Stage
  final String? collectedBy;
  final DateTime? collectedAt;
  final String? collectionLocation;
  final String? sampleQuantity;
  final String? packagingCondition;
  final String? collectionNotes;

  // 3. Dispatch & Transit Stage
  final DateTime? dispatchedAt;
  final String? destinationLab;
  final String? trackingReference;
  final String? transportNotes;

  // 4. Lab Receipt & Quality Control
  final DateTime? receivedAt;
  final String? receivedBy;
  final SampleReceiptCondition? conditionAtReceipt;
  final String? rejectionReason;

  // 5. Testing Stage
  final DateTime? testingStartedAt;

  // 6. Diagnostic Results & Report Evidence
  final String? result; // 'Positive' | 'Negative' | 'Inconclusive'
  final LabResultCategory? resultCategory;
  final String? resultNotes;
  final String? resultEnteredBy;
  final DateTime? resultAt;
  final List<String> attachments; // Laboratory PDF reports / microscopic images

  // 7. Veterinarian Interpretation & Clinical Confirmation
  final String? reviewedByVet;
  final DateTime? reviewedAt;
  final String? vetInterpretationNotes;
  final String? diagnosisDecision; // 'confirmed' | 'ruled_out' | 'provisional' | 'inconclusive'
  final String? confirmationBasis;

  final DateTime createdAt;
  final DateTime updatedAt;

  const LabTestModel({
    required this.id,
    required this.sampleId,
    required this.caseId,
    this.farmId = '',
    this.batchId = '',
    required this.sampleType,
    this.testRequested = 'RT-PCR Viral Panel',
    this.priority = 'urgent',
    required this.requestedBy,
    required this.requestedAt,
    this.assignedLabId,
    this.labName = 'Central Poultry Disease Diagnostic Lab, Pune',
    required this.status,
    this.collectedBy,
    this.collectedAt,
    this.collectionLocation,
    this.sampleQuantity,
    this.packagingCondition,
    this.collectionNotes,
    this.dispatchedAt,
    this.destinationLab,
    this.trackingReference,
    this.transportNotes,
    this.receivedAt,
    this.receivedBy,
    this.conditionAtReceipt,
    this.rejectionReason,
    this.testingStartedAt,
    this.result,
    this.resultCategory,
    this.resultNotes,
    this.resultEnteredBy,
    this.resultAt,
    this.attachments = const [],
    this.reviewedByVet,
    this.reviewedAt,
    this.vetInterpretationNotes,
    this.diagnosisDecision,
    this.confirmationBasis,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? requestedAt,
        updatedAt = updatedAt ?? requestedAt;

  /// Human-readable diagnostic turnaround duration
  String get turnaroundTimeFormatted {
    if (resultAt == null) {
      final elapsed = DateTime.now().difference(requestedAt);
      if (elapsed.inHours < 1) return '${elapsed.inMinutes}m (in progress)';
      if (elapsed.inHours < 24) return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m (in progress)';
      return '${elapsed.inDays}d ${elapsed.inHours % 24}h (in progress)';
    }
    final diff = resultAt!.difference(requestedAt);
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inDays}d ${diff.inHours % 24}h';
  }

  /// Flag indicating if an urgent test is beyond standard response target
  bool get isDelayed {
    if (status == LabTestStatus.result_available || status == LabTestStatus.reviewed || status == LabTestStatus.cancelled) {
      return false;
    }
    final elapsed = DateTime.now().difference(requestedAt);
    if (priority == 'emergency' && elapsed.inHours > 12) return true;
    if (priority == 'urgent' && elapsed.inHours > 24) return true;
    if (elapsed.inHours > 48) return true;
    return false;
  }

  factory LabTestModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseOptionalDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    List<String> parseList(dynamic v) {
      if (v is List) {
        return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    return LabTestModel(
      id: json['id'] as String? ?? '',
      sampleId: json['sampleId'] as String? ?? 'SMP-${json['id']?.toString().substring(0, 6) ?? "0001"}',
      caseId: json['caseId'] as String? ?? '',
      farmId: json['farmId'] as String? ?? '',
      batchId: json['batchId'] as String? ?? json['flockId'] as String? ?? '',
      sampleType: json['sampleType'] as String? ?? 'Tracheal & Cloacal Swabs',
      testRequested: json['testRequested'] as String? ?? 'RT-PCR Viral Panel',
      priority: json['priority'] as String? ?? 'urgent',
      requestedBy: json['requestedBy'] as String? ?? 'District Veterinarian',
      requestedAt: parseDate(json['requestedAt'] ?? json['createdAt']),
      assignedLabId: json['assignedLabId'] as String?,
      labName: json['labName'] as String? ?? 'Central Poultry Disease Diagnostic Lab, Pune',
      status: LabTestStatus.fromString(json['status'] as String?),
      collectedBy: json['collectedBy'] as String?,
      collectedAt: parseOptionalDate(json['collectedAt']),
      collectionLocation: json['collectionLocation'] as String?,
      sampleQuantity: json['sampleQuantity'] as String?,
      packagingCondition: json['packagingCondition'] as String?,
      collectionNotes: json['collectionNotes'] as String?,
      dispatchedAt: parseOptionalDate(json['dispatchedAt']),
      destinationLab: json['destinationLab'] as String?,
      trackingReference: json['trackingReference'] as String?,
      transportNotes: json['transportNotes'] as String?,
      receivedAt: parseOptionalDate(json['receivedAt']),
      receivedBy: json['receivedBy'] as String?,
      conditionAtReceipt: json['conditionAtReceipt'] != null ? SampleReceiptCondition.fromString(json['conditionAtReceipt'] as String?) : null,
      rejectionReason: json['rejectionReason'] as String?,
      testingStartedAt: parseOptionalDate(json['testingStartedAt']),
      result: json['result'] as String?,
      resultCategory: json['resultCategory'] != null ? LabResultCategory.fromString(json['resultCategory'] as String?) : (json['result'] != null ? LabResultCategory.fromString(json['result'] as String?) : null),
      resultNotes: json['resultNotes'] as String?,
      resultEnteredBy: json['resultEnteredBy'] as String?,
      resultAt: parseOptionalDate(json['resultAt'] ?? json['resultDate']),
      attachments: parseList(json['attachments']),
      reviewedByVet: json['reviewedByVet'] as String?,
      reviewedAt: parseOptionalDate(json['reviewedAt']),
      vetInterpretationNotes: json['vetInterpretationNotes'] as String?,
      diagnosisDecision: json['diagnosisDecision'] as String?,
      confirmationBasis: json['confirmationBasis'] as String?,
      createdAt: parseDate(json['createdAt'] ?? json['requestedAt']),
      updatedAt: parseDate(json['updatedAt'] ?? json['requestedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sampleId': sampleId,
      'caseId': caseId,
      'farmId': farmId,
      'batchId': batchId,
      'sampleType': sampleType,
      'testRequested': testRequested,
      'priority': priority,
      'requestedBy': requestedBy,
      'requestedAt': Timestamp.fromDate(requestedAt),
      if (assignedLabId != null) 'assignedLabId': assignedLabId,
      if (labName != null) 'labName': labName,
      'status': status.name,
      if (collectedBy != null) 'collectedBy': collectedBy,
      if (collectedAt != null) 'collectedAt': Timestamp.fromDate(collectedAt!),
      if (collectionLocation != null) 'collectionLocation': collectionLocation,
      if (sampleQuantity != null) 'sampleQuantity': sampleQuantity,
      if (packagingCondition != null) 'packagingCondition': packagingCondition,
      if (collectionNotes != null) 'collectionNotes': collectionNotes,
      if (dispatchedAt != null) 'dispatchedAt': Timestamp.fromDate(dispatchedAt!),
      if (destinationLab != null) 'destinationLab': destinationLab,
      if (trackingReference != null) 'trackingReference': trackingReference,
      if (transportNotes != null) 'transportNotes': transportNotes,
      if (receivedAt != null) 'receivedAt': Timestamp.fromDate(receivedAt!),
      if (receivedBy != null) 'receivedBy': receivedBy,
      if (conditionAtReceipt != null) 'conditionAtReceipt': conditionAtReceipt!.name,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (testingStartedAt != null) 'testingStartedAt': Timestamp.fromDate(testingStartedAt!),
      if (result != null) 'result': result,
      if (resultCategory != null) 'resultCategory': resultCategory!.name,
      if (resultNotes != null) 'resultNotes': resultNotes,
      if (resultEnteredBy != null) 'resultEnteredBy': resultEnteredBy,
      if (resultAt != null) 'resultAt': Timestamp.fromDate(resultAt!),
      'attachments': attachments,
      if (reviewedByVet != null) 'reviewedByVet': reviewedByVet,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      if (vetInterpretationNotes != null) 'vetInterpretationNotes': vetInterpretationNotes,
      if (diagnosisDecision != null) 'diagnosisDecision': diagnosisDecision,
      if (confirmationBasis != null) 'confirmationBasis': confirmationBasis,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  LabTestModel copyWith({
    String? id,
    String? sampleId,
    String? caseId,
    String? farmId,
    String? batchId,
    String? sampleType,
    String? testRequested,
    String? priority,
    String? requestedBy,
    DateTime? requestedAt,
    String? assignedLabId,
    String? labName,
    LabTestStatus? status,
    String? collectedBy,
    DateTime? collectedAt,
    String? collectionLocation,
    String? sampleQuantity,
    String? packagingCondition,
    String? collectionNotes,
    DateTime? dispatchedAt,
    String? destinationLab,
    String? trackingReference,
    String? transportNotes,
    DateTime? receivedAt,
    String? receivedBy,
    SampleReceiptCondition? conditionAtReceipt,
    String? rejectionReason,
    DateTime? testingStartedAt,
    String? result,
    LabResultCategory? resultCategory,
    String? resultNotes,
    String? resultEnteredBy,
    DateTime? resultAt,
    List<String>? attachments,
    String? reviewedByVet,
    DateTime? reviewedAt,
    String? vetInterpretationNotes,
    String? diagnosisDecision,
    String? confirmationBasis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LabTestModel(
      id: id ?? this.id,
      sampleId: sampleId ?? this.sampleId,
      caseId: caseId ?? this.caseId,
      farmId: farmId ?? this.farmId,
      batchId: batchId ?? this.batchId,
      sampleType: sampleType ?? this.sampleType,
      testRequested: testRequested ?? this.testRequested,
      priority: priority ?? this.priority,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedAt: requestedAt ?? this.requestedAt,
      assignedLabId: assignedLabId ?? this.assignedLabId,
      labName: labName ?? this.labName,
      status: status ?? this.status,
      collectedBy: collectedBy ?? this.collectedBy,
      collectedAt: collectedAt ?? this.collectedAt,
      collectionLocation: collectionLocation ?? this.collectionLocation,
      sampleQuantity: sampleQuantity ?? this.sampleQuantity,
      packagingCondition: packagingCondition ?? this.packagingCondition,
      collectionNotes: collectionNotes ?? this.collectionNotes,
      dispatchedAt: dispatchedAt ?? this.dispatchedAt,
      destinationLab: destinationLab ?? this.destinationLab,
      trackingReference: trackingReference ?? this.trackingReference,
      transportNotes: transportNotes ?? this.transportNotes,
      receivedAt: receivedAt ?? this.receivedAt,
      receivedBy: receivedBy ?? this.receivedBy,
      conditionAtReceipt: conditionAtReceipt ?? this.conditionAtReceipt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      testingStartedAt: testingStartedAt ?? this.testingStartedAt,
      result: result ?? this.result,
      resultCategory: resultCategory ?? this.resultCategory,
      resultNotes: resultNotes ?? this.resultNotes,
      resultEnteredBy: resultEnteredBy ?? this.resultEnteredBy,
      resultAt: resultAt ?? this.resultAt,
      attachments: attachments ?? this.attachments,
      reviewedByVet: reviewedByVet ?? this.reviewedByVet,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      vetInterpretationNotes: vetInterpretationNotes ?? this.vetInterpretationNotes,
      diagnosisDecision: diagnosisDecision ?? this.diagnosisDecision,
      confirmationBasis: confirmationBasis ?? this.confirmationBasis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
