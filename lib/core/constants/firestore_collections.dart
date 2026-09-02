/// Canonical Firestore Collection and Subcollection Names for FlockSense
/// Standardizes naming across Farmer, Veterinarian, and Government surveillance systems.
class FirestoreCollections {
  FirestoreCollections._();

  // Root & User Scoped Collections
  static const String users = 'users';
  static const String farms = 'farms';
  static const String batches = 'batches';
  static const String sheds = 'sheds';
  static const String dailyRecords = 'dailyRecords';
  static const String dailyRecordsSnake = 'daily_records';
  static const String vaccineRecords = 'vaccineRecords';
  static const String medicineRecords = 'medicineRecords';
  static const String weightRecords = 'weightRecords';
  static const String feedTransactions = 'feedTransactions';
  static const String salesRecords = 'salesRecords';
  static const String inventoryItems = 'inventoryItems';
  static const String stockMovements = 'stockMovements';

  // Collaborative Health & Surveillance Collections (Dominant snake_case)
  static const String healthCases = 'health_cases';
  static const String healthCasesLegacy = 'healthCases';
  static const String riskAssessments = 'risk_assessments';
  static const String aiHealthAssessments = 'ai_health_assessments';
  static const String diseaseAlerts = 'disease_alerts';
  static const String vetAssignments = 'vet_assignments';
  static const String vetClinicalAssessments = 'vet_clinical_assessments';
  static const String caseFollowUps = 'case_follow_ups';
  static const String labTests = 'lab_tests';
  static const String treatmentPlans = 'treatment_plans';
  static const String outbreakClusters = 'outbreak_clusters';
  static const String biosecurityAssessments = 'biosecurity_assessments';
  static const String preventionRecommendations = 'prevention_recommendations';
  static const String notifications = 'notifications';
  static const String auditLogs = 'audit_logs';

  // Central Farm Health Intelligence Collections
  static const String visitorEvents = 'visitor_events';
  static const String environmentalTargets = 'environmental_targets';
  static const String farmIntelligence = 'farm_intelligence';
  static const String thermalReadings = 'thermal_readings';
}
