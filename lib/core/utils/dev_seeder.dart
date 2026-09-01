import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flock_sense/features/auth/domain/user_model.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';
import 'package:flock_sense/features/daily_records/domain/daily_record_model.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';
import 'package:flock_sense/features/health/domain/biosecurity_assessment_model.dart';
import 'package:flock_sense/features/health/domain/health_case_model.dart';
import 'package:flock_sense/features/health/domain/lab_test_model.dart';
import 'package:flock_sense/features/health/domain/outbreak_cluster_model.dart';
import 'package:flock_sense/features/health/domain/prevention_recommendation_model.dart';

/// Complete, Idempotent Development Seeder for FlockSense (SIH26128)
class DevSeeder {
  DevSeeder._();

  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String demoDatasetVersion = 'sih-demo-v1';

  // ─────────────────────────────────────────────────────────────────────────────
  // 1. MASTER SEED METHOD
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> seedDemoData() async {
    debugPrint('[DevSeeder] Starting FlockSense synthetic demo dataset seeding ($demoDatasetVersion)...');
    final results = <String, int>{};

    try {
      // 1. Seed Users (Farmers, Veterinarians, Government Officers)
      final usersCount = await _seedUsers();
      results['users'] = usersCount;

      // 2. Seed 24 Maharashtra Farms
      final farmsCount = await _seedFarms();
      results['farms'] = farmsCount;

      // 3. Seed Batches / Flocks
      final batchesCount = await _seedBatches();
      results['batches'] = batchesCount;

      // 4. Seed 30-Day Daily Record Telemetry
      final recordsCount = await _seedDailyRecords();
      results['daily_records'] = recordsCount;

      // 5. Seed Health Cases (Low, Moderate, High, Critical)
      final casesCount = await _seedHealthCases();
      results['health_cases'] = casesCount;

      // 6. Seed Outbreak Clusters
      final clustersCount = await _seedOutbreakClusters();
      results['outbreak_clusters'] = clustersCount;

      // 7. Seed Lab Diagnostic Tests
      final labCount = await _seedLabTests();
      results['lab_tests'] = labCount;

      // 8. Seed Biosecurity Assessments
      final bioCount = await _seedBiosecurityAssessments();
      results['biosecurity_assessments'] = bioCount;

      // 9. Seed Prevention Recommendations
      final prevCount = await _seedPreventionRecommendations();
      results['prevention_recommendations'] = prevCount;

      // 10. Seed Notifications
      final notifCount = await _seedNotifications();
      results['notifications'] = notifCount;

      debugPrint('[DevSeeder] Seeding completed successfully: $results');
      return {'success': true, 'counts': results};
    } catch (e, st) {
      debugPrint('[DevSeeder] Seeding failed with error: $e\n$st');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 2. SEED USERS
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedUsers() async {
    final now = DateTime.now();
    final users = <Map<String, dynamic>>[
      // Farmers
      {
        'uid': 'farmer_demo_001',
        'name': 'Rahul Demo Patil',
        'displayName': 'Rahul Demo Patil',
        'email': 'rahul.demo01@example.com',
        'role': 'farmer',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'phoneNumber': '+91 90000 00001',
        'hasFarm': true,
        'activeFarmId': 'farm_demo_001',
        'hasCompletedOnboarding': true,
        'preferredLanguage': 'mr',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 90)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'uid': 'farmer_demo_002',
        'name': 'Suresh Demo Deshmukh',
        'displayName': 'Suresh Demo Deshmukh',
        'email': 'suresh.demo02@example.com',
        'role': 'farmer',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'phoneNumber': '+91 90000 00002',
        'hasFarm': true,
        'activeFarmId': 'farm_demo_002',
        'hasCompletedOnboarding': true,
        'preferredLanguage': 'mr',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 80)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'uid': 'farmer_demo_003',
        'name': 'Pooja Demo Shinde',
        'displayName': 'Pooja Demo Shinde',
        'email': 'pooja.demo03@example.com',
        'role': 'farmer',
        'district': 'Pune',
        'state': 'Maharashtra',
        'phoneNumber': '+91 90000 00003',
        'hasFarm': true,
        'activeFarmId': 'farm_demo_006',
        'hasCompletedOnboarding': true,
        'preferredLanguage': 'en',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 60)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'uid': 'farmer_demo_004',
        'name': 'Anil Demo Kulkarni',
        'displayName': 'Anil Demo Kulkarni',
        'email': 'anil.demo04@example.com',
        'role': 'farmer',
        'district': 'Nagpur',
        'state': 'Maharashtra',
        'phoneNumber': '+91 90000 00004',
        'hasFarm': true,
        'activeFarmId': 'farm_demo_010',
        'hasCompletedOnboarding': true,
        'preferredLanguage': 'hi',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 45)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // 6 Synthetic Veterinarians
      {
        'uid': 'vet_demo_001',
        'name': 'Dr. Vikram Sharma (Surgeon)',
        'displayName': 'Dr. Vikram Sharma',
        'email': 'dr.sharma.demo@example.com',
        'role': 'veterinarian',
        'registrationId': 'VCI-MAH-2021-0842',
        'specialization': 'Avian Medicine & Epidemiology',
        'speciesExpertise': ['Poultry', 'Avian'],
        'district': 'Nashik',
        'serviceDistricts': ['Nashik', 'Dindori', 'Niphad'],
        'phoneNumber': '+91 90000 00011',
        'availability': 'on_duty',
        'active': true,
        'hasCompletedOnboarding': true,
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 120)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'uid': 'vet_demo_002',
        'name': 'Dr. Neha G. Kulkarni',
        'displayName': 'Dr. Neha Kulkarni',
        'email': 'dr.kulkarni.demo@example.com',
        'role': 'veterinarian',
        'registrationId': 'VCI-MAH-2022-1104',
        'specialization': 'Veterinary Pathology & Diagnostics',
        'speciesExpertise': ['Poultry', 'Dairy Cattle'],
        'district': 'Nashik',
        'serviceDistricts': ['Nashik', 'Igatpuri', 'Sinnar'],
        'phoneNumber': '+91 90000 00012',
        'availability': 'on_duty',
        'active': true,
        'hasCompletedOnboarding': true,
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 110)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'uid': 'vet_demo_003',
        'name': 'Dr. Rajesh M. Pawar',
        'displayName': 'Dr. Rajesh Pawar',
        'email': 'dr.pawar.demo@example.com',
        'role': 'veterinarian',
        'registrationId': 'VCI-MAH-2019-0421',
        'specialization': 'Poultry Flock Health & Biosecurity',
        'speciesExpertise': ['Poultry', 'Broiler Production'],
        'district': 'Pune',
        'serviceDistricts': ['Pune', 'Haveli', 'Baramati', 'Khed'],
        'phoneNumber': '+91 90000 00013',
        'availability': 'on_duty',
        'active': true,
        'hasCompletedOnboarding': true,
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 150)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'uid': 'vet_demo_004',
        'name': 'Dr. Smita R. Joshi',
        'displayName': 'Dr. Smita Joshi',
        'email': 'dr.joshi.demo@example.com',
        'role': 'veterinarian',
        'registrationId': 'VCI-MAH-2020-0982',
        'specialization': 'Ruminant & Dairy Herd Management',
        'speciesExpertise': ['Dairy Cattle', 'Goat', 'Poultry'],
        'district': 'Nagpur',
        'serviceDistricts': ['Nagpur', 'Kamptee', 'Hingna'],
        'phoneNumber': '+91 90000 00014',
        'availability': 'on_duty',
        'active': true,
        'hasCompletedOnboarding': true,
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 100)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'uid': 'vet_demo_005',
        'name': 'Dr. Amit V. Patil',
        'displayName': 'Dr. Amit Patil',
        'email': 'dr.patil.demo@example.com',
        'role': 'veterinarian',
        'registrationId': 'VCI-MAH-2018-0312',
        'specialization': 'Livestock Preventive Care & Vaccination',
        'speciesExpertise': ['Poultry', 'Sheep', 'Goat'],
        'district': 'Kolhapur',
        'serviceDistricts': ['Kolhapur', 'Satara', 'Karad'],
        'phoneNumber': '+91 90000 00015',
        'availability': 'on_duty',
        'active': true,
        'hasCompletedOnboarding': true,
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 140)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'uid': 'vet_demo_006',
        'name': 'Dr. Kavita S. More',
        'displayName': 'Dr. Kavita More',
        'email': 'dr.more.demo@example.com',
        'role': 'veterinarian',
        'registrationId': 'VCI-MAH-2023-1490',
        'specialization': 'Infectious Disease Control & Surveillance',
        'speciesExpertise': ['Poultry', 'Goat', 'Mixed Livestock'],
        'district': 'Sangli',
        'serviceDistricts': ['Sangli', 'Solapur', 'Miraj'],
        'phoneNumber': '+91 90000 00016',
        'availability': 'on_duty',
        'active': true,
        'hasCompletedOnboarding': true,
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 90)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // Government Surveillance Officers
      {
        'uid': 'gov_demo_001',
        'name': 'Director Dr. S. K. Mahajan (DAH)',
        'displayName': 'Director Dr. S. K. Mahajan',
        'email': 'dah.director.demo@maharashtra.gov.in',
        'role': 'government',
        'district': 'State HQ (Maharashtra)',
        'state': 'Maharashtra',
        'phoneNumber': '+91 90000 00021',
        'hasCompletedOnboarding': true,
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 200)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    ];

    final batch = _firestore.batch();
    for (final u in users) {
      final docRef = _firestore.collection('users').doc(u['uid']);
      batch.set(docRef, u, SetOptions(merge: true));
    }
    await batch.commit();
    return users.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 3. SEED 24 MAHARASHTRA FARMS
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedFarms() async {
    final now = DateTime.now();

    final farms = <Map<String, dynamic>>[
      // ─── NASHIK DISTRICT (5 Farms) ──────────────────────────────────────────
      {
        'id': 'farm_demo_001',
        'userId': 'farmer_demo_001',
        'ownerId': 'farmer_demo_001',
        'farmName': 'Green Valley Poultry Farm',
        'farmerName': 'Rahul Demo Patil',
        'farmType': 'EC',
        'flockType': 'Cobb 500',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 8500,
        'livestockCount': 8420,
        'lengthFt': 200.0,
        'widthFt': 40.0,
        'totalSqFt': 8000.0,
        'farmSize': 12.5,
        'farmSizeUnit': 'Acres',
        'address': 'Dindori Road, Dindori Taluka',
        'village': 'Dindori',
        'taluka': 'Dindori',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 19.9975,
        'longitude': 73.7898,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00001',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'critical',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 180)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_002',
        'userId': 'farmer_demo_002',
        'ownerId': 'farmer_demo_002',
        'farmName': 'Sahyadri Poultry Centre',
        'farmerName': 'Suresh Demo Deshmukh',
        'farmType': 'Open',
        'flockType': 'Ross 308',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 5000,
        'livestockCount': 4800,
        'lengthFt': 160.0,
        'widthFt': 35.0,
        'totalSqFt': 5600.0,
        'farmSize': 9.8,
        'farmSizeUnit': 'Acres',
        'address': 'Niphad Rural, Niphad Taluka',
        'village': 'Niphad',
        'taluka': 'Niphad',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 20.0210,
        'longitude': 73.8120,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00002',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'high',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 140)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_003',
        'userId': 'farmer_demo_001',
        'ownerId': 'farmer_demo_001',
        'farmName': 'Godavari Layer Farm',
        'farmerName': 'Rahul Demo Patil',
        'farmType': 'EC',
        'flockType': 'BV 300 Layers',
        'primaryLivestock': 'Poultry (Layer)',
        'cropType': 'Not Applicable',
        'capacity': 10000,
        'livestockCount': 9200,
        'lengthFt': 250.0,
        'widthFt': 45.0,
        'totalSqFt': 11250.0,
        'farmSize': 14.2,
        'farmSizeUnit': 'Acres',
        'address': 'Trimbak Road, Belgaon Dhaga',
        'village': 'Belgaon Dhaga',
        'taluka': 'Nashik',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 19.9650,
        'longitude': 73.7420,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00001',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 120)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_004',
        'userId': 'farmer_demo_002',
        'ownerId': 'farmer_demo_002',
        'farmName': 'Shivneri Poultry Farm',
        'farmerName': 'Suresh Demo Deshmukh',
        'farmType': 'Open',
        'flockType': 'Broiler',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 4000,
        'livestockCount': 3900,
        'lengthFt': 140.0,
        'widthFt': 30.0,
        'totalSqFt': 4200.0,
        'farmSize': 8.6,
        'farmSizeUnit': 'Acres',
        'address': 'Sinnar Industrial Link, Sinnar',
        'village': 'Sinnar',
        'taluka': 'Sinnar',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 19.9820,
        'longitude': 73.8240,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00002',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'pending_verification',
        'healthRisk': 'critical',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 90)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_005',
        'userId': 'farmer_demo_001',
        'ownerId': 'farmer_demo_001',
        'farmName': 'Nashik Agro Livestock Farm',
        'farmerName': 'Rahul Demo Patil',
        'farmType': 'Mixed Livestock',
        'flockType': 'Mixed',
        'primaryLivestock': 'Poultry + Goat',
        'cropType': 'Napier Grass + Fodder Maize',
        'capacity': 3000,
        'livestockCount': 2200,
        'lengthFt': 180.0,
        'widthFt': 40.0,
        'totalSqFt': 7200.0,
        'farmSize': 18.0,
        'farmSizeUnit': 'Acres',
        'address': 'Igatpuri Hill Sector, Igatpuri',
        'village': 'Igatpuri',
        'taluka': 'Igatpuri',
        'district': 'Nashik',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 19.6980,
        'longitude': 73.5620,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00001',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 100)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // ─── PUNE DISTRICT (4 Farms) ─────────────────────────────────────────────
      {
        'id': 'farm_demo_006',
        'userId': 'farmer_demo_003',
        'ownerId': 'farmer_demo_003',
        'farmName': 'Pune Sunrise Poultry',
        'farmerName': 'Pooja Demo Shinde',
        'farmType': 'EC',
        'flockType': 'Broiler',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 6000,
        'livestockCount': 5600,
        'lengthFt': 180.0,
        'widthFt': 40.0,
        'totalSqFt': 7200.0,
        'farmSize': 11.0,
        'farmSizeUnit': 'Acres',
        'address': 'Khed Shivapur, Haveli',
        'village': 'Khed Shivapur',
        'taluka': 'Haveli',
        'district': 'Pune',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 18.3580,
        'longitude': 73.8640,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00003',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'moderate',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 150)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_007',
        'userId': 'farmer_demo_003',
        'ownerId': 'farmer_demo_003',
        'farmName': 'Bhima Dairy Farm',
        'farmerName': 'Pooja Demo Shinde',
        'farmType': 'Dairy',
        'flockType': 'HF Cross Cattle',
        'primaryLivestock': 'Dairy (Cattle)',
        'cropType': 'Sorghum Fodder',
        'capacity': 120,
        'livestockCount': 94,
        'lengthFt': 220.0,
        'widthFt': 50.0,
        'totalSqFt': 11000.0,
        'farmSize': 22.0,
        'farmSizeUnit': 'Acres',
        'address': 'Baramati Rural, Baramati',
        'village': 'Baramati',
        'taluka': 'Baramati',
        'district': 'Pune',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 18.1510,
        'longitude': 74.5770,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00003',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 130)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_008',
        'userId': 'farmer_demo_003',
        'ownerId': 'farmer_demo_003',
        'farmName': 'Western Poultry Unit',
        'farmerName': 'Pooja Demo Shinde',
        'farmType': 'Open',
        'flockType': 'Layer',
        'primaryLivestock': 'Poultry (Layer)',
        'cropType': 'Not Applicable',
        'capacity': 4500,
        'livestockCount': 0,
        'lengthFt': 150.0,
        'widthFt': 35.0,
        'totalSqFt': 5250.0,
        'farmSize': 10.0,
        'farmSizeUnit': 'Acres',
        'address': 'Shirur Bypass, Shirur',
        'village': 'Shirur',
        'taluka': 'Shirur',
        'district': 'Pune',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 18.8250,
        'longitude': 74.3780,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00003',
        'status': 'inactive',
        'operationalStatus': 'inactive',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 160)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_009',
        'userId': 'farmer_demo_003',
        'ownerId': 'farmer_demo_003',
        'farmName': 'Krishna Mixed Farm',
        'farmerName': 'Pooja Demo Shinde',
        'farmType': 'Mixed Livestock',
        'flockType': 'Dairy + Goat',
        'primaryLivestock': 'Dairy + Goat',
        'cropType': 'Mixed Fodder',
        'capacity': 200,
        'livestockCount': 140,
        'lengthFt': 200.0,
        'widthFt': 45.0,
        'totalSqFt': 9000.0,
        'farmSize': 25.0,
        'farmSizeUnit': 'Acres',
        'address': 'Jejuri Road, Purandar',
        'village': 'Jejuri',
        'taluka': 'Purandar',
        'district': 'Pune',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 18.2780,
        'longitude': 74.1590,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00003',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'pending_verification',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 110)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // ─── NAGPUR DISTRICT (3 Farms) ───────────────────────────────────────────
      {
        'id': 'farm_demo_010',
        'userId': 'farmer_demo_004',
        'ownerId': 'farmer_demo_004',
        'farmName': 'Nagpur Poultry Hub',
        'farmerName': 'Anil Demo Kulkarni',
        'farmType': 'EC',
        'flockType': 'Broiler',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 7000,
        'livestockCount': 6800,
        'lengthFt': 210.0,
        'widthFt': 42.0,
        'totalSqFt': 8820.0,
        'farmSize': 15.0,
        'farmSizeUnit': 'Acres',
        'address': 'Wardha Road, Hingna',
        'village': 'Hingna',
        'taluka': 'Hingna',
        'district': 'Nagpur',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 21.0620,
        'longitude': 79.0140,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00004',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'moderate',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 170)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_011',
        'userId': 'farmer_demo_004',
        'ownerId': 'farmer_demo_004',
        'farmName': 'Orange City Dairy',
        'farmerName': 'Anil Demo Kulkarni',
        'farmType': 'Dairy',
        'flockType': 'Gir Cattle',
        'primaryLivestock': 'Dairy (Cattle)',
        'cropType': 'Napier Grass',
        'capacity': 150,
        'livestockCount': 112,
        'lengthFt': 240.0,
        'widthFt': 55.0,
        'totalSqFt': 13200.0,
        'farmSize': 28.0,
        'farmSizeUnit': 'Acres',
        'address': 'Kamptee Belt, Kamptee',
        'village': 'Kamptee',
        'taluka': 'Kamptee',
        'district': 'Nagpur',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 21.2280,
        'longitude': 79.1960,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00004',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 145)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_012',
        'userId': 'farmer_demo_004',
        'ownerId': 'farmer_demo_004',
        'farmName': 'Vidarbha Goat Farm',
        'farmerName': 'Anil Demo Kulkarni',
        'farmType': 'Goat',
        'flockType': 'Osmanabadi',
        'primaryLivestock': 'Goat',
        'cropType': 'Mixed Fodder',
        'capacity': 350,
        'livestockCount': 280,
        'lengthFt': 180.0,
        'widthFt': 40.0,
        'totalSqFt': 7200.0,
        'farmSize': 17.0,
        'farmSizeUnit': 'Acres',
        'address': 'Katol Road, Katol',
        'village': 'Katol',
        'taluka': 'Katol',
        'district': 'Nagpur',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 21.2750,
        'longitude': 78.5860,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00004',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'under_review',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 90)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // ─── KOLHAPUR DISTRICT (3 Farms) ─────────────────────────────────────────
      {
        'id': 'farm_demo_013',
        'userId': 'farmer_demo_001',
        'ownerId': 'farmer_demo_001',
        'farmName': 'Kolhapur Poultry Estate',
        'farmerName': 'Rahul Demo Patil',
        'farmType': 'Open',
        'flockType': 'Broiler',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 5500,
        'livestockCount': 5100,
        'lengthFt': 170.0,
        'widthFt': 38.0,
        'totalSqFt': 6460.0,
        'farmSize': 13.0,
        'farmSizeUnit': 'Acres',
        'address': 'Shiroli Industrial Zone, Hatkanangle',
        'village': 'Shiroli',
        'taluka': 'Hatkanangle',
        'district': 'Kolhapur',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 16.7450,
        'longitude': 74.2980,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00001',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 130)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_014',
        'userId': 'farmer_demo_002',
        'ownerId': 'farmer_demo_002',
        'farmName': 'Mahalaxmi Dairy Unit',
        'farmerName': 'Suresh Demo Deshmukh',
        'farmType': 'Dairy',
        'flockType': 'Murrah Buffalo',
        'primaryLivestock': 'Dairy (Cattle/Buffalo)',
        'cropType': 'Sugarcane + Dairy Fodder',
        'capacity': 160,
        'livestockCount': 125,
        'lengthFt': 260.0,
        'widthFt': 60.0,
        'totalSqFt': 15600.0,
        'farmSize': 31.0,
        'farmSizeUnit': 'Acres',
        'address': 'Karveer Rural, Karveer',
        'village': 'Karveer',
        'taluka': 'Karveer',
        'district': 'Kolhapur',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 16.6920,
        'longitude': 74.2230,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00002',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 155)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_015',
        'userId': 'farmer_demo_001',
        'ownerId': 'farmer_demo_001',
        'farmName': 'Panchganga Livestock Farm',
        'farmerName': 'Rahul Demo Patil',
        'farmType': 'Mixed Livestock',
        'flockType': 'Cattle + Goat',
        'primaryLivestock': 'Cattle + Goat',
        'cropType': 'Fodder Maize',
        'capacity': 220,
        'livestockCount': 0,
        'lengthFt': 200.0,
        'widthFt': 45.0,
        'totalSqFt': 9000.0,
        'farmSize': 26.0,
        'farmSizeUnit': 'Acres',
        'address': 'Radhanagari Road, Radhanagari',
        'village': 'Radhanagari',
        'taluka': 'Radhanagari',
        'district': 'Kolhapur',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 16.4180,
        'longitude': 73.9980,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00001',
        'status': 'temporarily_closed',
        'operationalStatus': 'temporarily_closed',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 175)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // ─── SATARA DISTRICT (3 Farms) ───────────────────────────────────────────
      {
        'id': 'farm_demo_016',
        'userId': 'farmer_demo_003',
        'ownerId': 'farmer_demo_003',
        'farmName': 'Satara Hills Poultry',
        'farmerName': 'Pooja Demo Shinde',
        'farmType': 'Open',
        'flockType': 'Broiler',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 4000,
        'livestockCount': 3600,
        'lengthFt': 150.0,
        'widthFt': 32.0,
        'totalSqFt': 4800.0,
        'farmSize': 9.0,
        'farmSizeUnit': 'Acres',
        'address': 'Wai Valley Foothills, Wai',
        'village': 'Wai',
        'taluka': 'Wai',
        'district': 'Satara',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 17.9480,
        'longitude': 73.8920,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00003',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 115)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_017',
        'userId': 'farmer_demo_003',
        'ownerId': 'farmer_demo_003',
        'farmName': 'Krishna Valley Dairy',
        'farmerName': 'Pooja Demo Shinde',
        'farmType': 'Dairy',
        'flockType': 'Jersey Cattle',
        'primaryLivestock': 'Dairy (Cattle)',
        'cropType': 'Lucerne Grass',
        'capacity': 100,
        'livestockCount': 86,
        'lengthFt': 210.0,
        'widthFt': 50.0,
        'totalSqFt': 10500.0,
        'farmSize': 20.0,
        'farmSizeUnit': 'Acres',
        'address': 'Karad South, Karad',
        'village': 'Karad',
        'taluka': 'Karad',
        'district': 'Satara',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 17.2890,
        'longitude': 74.1810,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00003',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 140)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_018',
        'userId': 'farmer_demo_002',
        'ownerId': 'farmer_demo_002',
        'farmName': 'Satara Sheep Station',
        'farmerName': 'Suresh Demo Deshmukh',
        'farmType': 'Sheep',
        'flockType': 'Deccani Sheep',
        'primaryLivestock': 'Sheep',
        'cropType': 'Rangeland Grazing + Sorghum',
        'capacity': 500,
        'livestockCount': 420,
        'lengthFt': 250.0,
        'widthFt': 60.0,
        'totalSqFt': 15000.0,
        'farmSize': 32.0,
        'farmSizeUnit': 'Acres',
        'address': 'Phaltan Plateau, Phaltan',
        'village': 'Phaltan',
        'taluka': 'Phaltan',
        'district': 'Satara',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 17.9860,
        'longitude': 74.4320,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00002',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'pending_verification',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 80)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // ─── AHMEDNAGAR DISTRICT (2 Farms) ───────────────────────────────────────
      {
        'id': 'farm_demo_019',
        'userId': 'farmer_demo_001',
        'ownerId': 'farmer_demo_001',
        'farmName': 'Ahmednagar Poultry Farm',
        'farmerName': 'Rahul Demo Patil',
        'farmType': 'EC',
        'flockType': 'Layer',
        'primaryLivestock': 'Poultry (Layer)',
        'cropType': 'Not Applicable',
        'capacity': 6500,
        'livestockCount': 6200,
        'lengthFt': 190.0,
        'widthFt': 40.0,
        'totalSqFt': 7600.0,
        'farmSize': 12.0,
        'farmSizeUnit': 'Acres',
        'address': 'Rahata Belt, Rahata',
        'village': 'Rahata',
        'taluka': 'Rahata',
        'district': 'Ahmednagar',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 19.6840,
        'longitude': 74.4820,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00001',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'moderate',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 125)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_020',
        'userId': 'farmer_demo_002',
        'ownerId': 'farmer_demo_002',
        'farmName': 'Pravara Dairy Farm',
        'farmerName': 'Suresh Demo Deshmukh',
        'farmType': 'Dairy',
        'flockType': 'Crossbred Cattle',
        'primaryLivestock': 'Dairy (Cattle)',
        'cropType': 'Sugarcane Fodder',
        'capacity': 140,
        'livestockCount': 118,
        'lengthFt': 230.0,
        'widthFt': 50.0,
        'totalSqFt': 11500.0,
        'farmSize': 29.0,
        'farmSizeUnit': 'Acres',
        'address': 'Sangamner Bypass, Sangamner',
        'village': 'Sangamner',
        'taluka': 'Sangamner',
        'district': 'Ahmednagar',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 19.5740,
        'longitude': 74.2140,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00002',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 160)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // ─── SANGLI DISTRICT (2 Farms) ───────────────────────────────────────────
      {
        'id': 'farm_demo_021',
        'userId': 'farmer_demo_004',
        'ownerId': 'farmer_demo_004',
        'farmName': 'Sangli Poultry Centre',
        'farmerName': 'Anil Demo Kulkarni',
        'farmType': 'Open',
        'flockType': 'Broiler',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 4800,
        'livestockCount': 4400,
        'lengthFt': 160.0,
        'widthFt': 35.0,
        'totalSqFt': 5600.0,
        'farmSize': 10.0,
        'farmSizeUnit': 'Acres',
        'address': 'Miraj Industrial Outskirts, Miraj',
        'village': 'Miraj',
        'taluka': 'Miraj',
        'district': 'Sangli',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 16.8320,
        'longitude': 74.6430,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00004',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 105)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_022',
        'userId': 'farmer_demo_004',
        'ownerId': 'farmer_demo_004',
        'farmName': 'Warana Livestock Farm',
        'farmerName': 'Anil Demo Kulkarni',
        'farmType': 'Mixed Livestock',
        'flockType': 'Dairy + Goat',
        'primaryLivestock': 'Dairy + Goat',
        'cropType': 'Mixed Grasses',
        'capacity': 250,
        'livestockCount': 190,
        'lengthFt': 220.0,
        'widthFt': 50.0,
        'totalSqFt': 11000.0,
        'farmSize': 30.0,
        'farmSizeUnit': 'Acres',
        'address': 'Walwa Region, Walwa',
        'village': 'Walwa',
        'taluka': 'Walwa',
        'district': 'Sangli',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 17.0340,
        'longitude': 74.2890,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00004',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'under_review',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 70)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },

      // ─── SOLAPUR DISTRICT (2 Farms) ──────────────────────────────────────────
      {
        'id': 'farm_demo_023',
        'userId': 'farmer_demo_002',
        'ownerId': 'farmer_demo_002',
        'farmName': 'Solapur Goat Farm',
        'farmerName': 'Suresh Demo Deshmukh',
        'farmType': 'Goat',
        'flockType': 'Osmanabadi Goat',
        'primaryLivestock': 'Goat',
        'cropType': 'Subabul + Fodder Sorghum',
        'capacity': 400,
        'livestockCount': 340,
        'lengthFt': 200.0,
        'widthFt': 45.0,
        'totalSqFt': 9000.0,
        'farmSize': 21.0,
        'farmSizeUnit': 'Acres',
        'address': 'Pandharpur Road, Pandharpur',
        'village': 'Pandharpur',
        'taluka': 'Pandharpur',
        'district': 'Solapur',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 17.6780,
        'longitude': 75.3240,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00002',
        'status': 'active',
        'operationalStatus': 'active',
        'verificationStatus': 'verified',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 135)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'farm_demo_024',
        'userId': 'farmer_demo_003',
        'ownerId': 'farmer_demo_003',
        'farmName': 'Solapur Poultry Unit',
        'farmerName': 'Pooja Demo Shinde',
        'farmType': 'Open',
        'flockType': 'Broiler',
        'primaryLivestock': 'Poultry (Broiler)',
        'cropType': 'Not Applicable',
        'capacity': 5000,
        'livestockCount': 0,
        'lengthFt': 160.0,
        'widthFt': 35.0,
        'totalSqFt': 5600.0,
        'farmSize': 11.0,
        'farmSizeUnit': 'Acres',
        'address': 'Barshi Highway, Barshi',
        'village': 'Barshi',
        'taluka': 'Barshi',
        'district': 'Solapur',
        'state': 'Maharashtra',
        'country': 'India',
        'latitude': 18.2340,
        'longitude': 75.6980,
        'locationStatus': 'complete',
        'phoneNumber': '+91 90000 00003',
        'status': 'inactive',
        'operationalStatus': 'inactive',
        'verificationStatus': 'pending_verification',
        'healthRisk': 'low',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 160)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    ];

    // Seed both top-level 'farms/{id}' and user subcollections 'users/{userId}/farms/{id}'
    final batch = _firestore.batch();
    for (final f in farms) {
      final topRef = _firestore.collection('farms').doc(f['id']);
      batch.set(topRef, f, SetOptions(merge: true));

      final userSubRef = _firestore
          .collection('users')
          .doc(f['userId'])
          .collection('farms')
          .doc(f['id']);
      batch.set(userSubRef, f, SetOptions(merge: true));
    }
    await batch.commit();
    return farms.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 4. SEED BATCHES
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedBatches() async {
    final now = DateTime.now();

    final batches = <Map<String, dynamic>>[
      {
        'id': 'batch_demo_001',
        'farmId': 'farm_demo_001',
        'ownerId': 'farmer_demo_001',
        'batchName': 'Cobb 500 — Shed 1 (Batch B08)',
        'breedOrFlockType': 'Cobb 500',
        'hatchDate': now.subtract(const Duration(days: 35)).toIso8601String(),
        'placementDate': now.subtract(const Duration(days: 34)).toIso8601String(),
        'maleCount': 4250,
        'femaleCount': 4250,
        'totalBirds': 8500,
        'currentBirds': 8420,
        'status': 'active',
        'chickAvgWeight': 42.0,
        'hatcheryName': 'Venkateshwara Hatcheries',
        'notes': 'Active broiler cycle showing acute respiratory signs at Day 33',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 35)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'batch_demo_002',
        'farmId': 'farm_demo_002',
        'ownerId': 'farmer_demo_002',
        'batchName': 'Ross 308 — Shed 1 (Batch B04)',
        'breedOrFlockType': 'Ross 308',
        'hatchDate': now.subtract(const Duration(days: 32)).toIso8601String(),
        'placementDate': now.subtract(const Duration(days: 31)).toIso8601String(),
        'maleCount': 2500,
        'femaleCount': 2500,
        'totalBirds': 5000,
        'currentBirds': 4800,
        'status': 'active',
        'chickAvgWeight': 41.5,
        'hatcheryName': 'Godrej Agrovet',
        'notes': 'High mortality surge linked to spatial cluster',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 32)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
      {
        'id': 'batch_demo_003',
        'farmId': 'farm_demo_004',
        'ownerId': 'farmer_demo_002',
        'batchName': 'Shivneri Broiler Batch 02',
        'breedOrFlockType': 'Cobb 500',
        'hatchDate': now.subtract(const Duration(days: 28)).toIso8601String(),
        'placementDate': now.subtract(const Duration(days: 27)).toIso8601String(),
        'maleCount': 2000,
        'femaleCount': 2000,
        'totalBirds': 4000,
        'currentBirds': 3900,
        'status': 'active',
        'chickAvgWeight': 43.0,
        'hatcheryName': 'Suguna Foods',
        'notes': 'Index farm 3 in Nashik cluster cordon',
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': now.subtract(const Duration(days: 28)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
      },
    ];

    final batch = _firestore.batch();
    for (final b in batches) {
      final userSubRef = _firestore
          .collection('users')
          .doc(b['ownerId'])
          .collection('farms')
          .doc(b['farmId'])
          .collection('batches')
          .doc(b['id']);
      batch.set(userSubRef, b, SetOptions(merge: true));

      final topRef = _firestore.collection('batches').doc(b['id']);
      batch.set(topRef, b, SetOptions(merge: true));
    }
    await batch.commit();
    return batches.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 5. SEED 30-DAY DAILY RECORD TELEMETRY
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedDailyRecords() async {
    final now = DateTime.now();
    final records = <Map<String, dynamic>>[];

    // 30 Days of Telemetry for Green Valley (Batch B08)
    // Days 1 to 25: Normal Baseline (Mortality 2-4, Feed ~490-520kg, Water ~870-930L)
    // Days 26 to 30: Anomaly Progression (Mortality 8, 12, 15; Feed 470, 440, 410; Water 850, 780, 720)
    int currentLiveBirds = 8500;

    for (int day = 1; day <= 30; day++) {
      final recordDate = now.subtract(Duration(days: 30 - day));
      final dateKey = '${recordDate.year}-${recordDate.month.toString().padLeft(2, '0')}-${recordDate.day.toString().padLeft(2, '0')}';
      final recordId = 'dr_gv_b08_$dateKey';

      int mortality = 3;
      double feedKg = 500.0 + (day % 3) * 10;
      double waterL = 890.0 + (day % 3) * 20;
      String? symptoms;
      String? notes;

      if (day == 26) {
        mortality = 5;
        feedKg = 480.0;
        waterL = 870.0;
        symptoms = 'Slight coughing detected in Shed 1 north corner';
      } else if (day == 27) {
        mortality = 8;
        feedKg = 460.0;
        waterL = 830.0;
        symptoms = 'Frequent sneezing, mild watery discharge';
      } else if (day == 28) {
        mortality = 11;
        feedKg = 430.0;
        waterL = 790.0;
        symptoms = 'Severe tracheal rales, clicking sounds, drop in feed';
      } else if (day == 29) {
        mortality = 13;
        feedKg = 410.0;
        waterL = 750.0;
        symptoms = 'Acute gasping, cyanosis, severe respiratory distress';
      } else if (day == 30) {
        mortality = 15;
        feedKg = 390.0;
        waterL = 710.0;
        symptoms = 'Spike in dead birds, comb cyanosis, rapid breathing';
        notes = 'Emergency veterinarian escalation triggered';
      }

      currentLiveBirds -= mortality;

      records.add({
        'id': recordId,
        'farmId': 'farm_demo_001',
        'batchId': 'batch_demo_001',
        'ownerId': 'farmer_demo_001',
        'recordDate': recordDate.toIso8601String(),
        'batchAgeDay': day,
        'openingBirds': currentLiveBirds + mortality,
        'mortalityCount': mortality,
        'cullCount': 0,
        'adjustmentCount': 0,
        'closingBirds': currentLiveBirds,
        'feedConsumedKg': feedKg,
        'waterConsumedLiters': waterL,
        'avgWeightGrams': 42.0 + (day * 55),
        'medicineGiven': day > 28,
        'medicineName': day > 28 ? 'Electrolytes + Vitamin C' : null,
        'vaccineGiven': day == 7 || day == 14 || day == 28,
        'vaccineName': day == 28 ? 'LaSota Booster' : (day == 14 ? 'Gumboro IBD' : 'ND B1'),
        'symptoms': symptoms,
        'notes': notes,
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
        'createdAt': recordDate.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      });
    }

    final batch = _firestore.batch();
    for (final r in records) {
      final userSubRef = _firestore
          .collection('users')
          .doc('farmer_demo_001')
          .collection('farms')
          .doc('farm_demo_001')
          .collection('batches')
          .doc('batch_demo_001')
          .collection('dailyRecords')
          .doc(r['id']);
      batch.set(userSubRef, r, SetOptions(merge: true));

      final topRef = _firestore.collection('daily_records').doc(r['id']);
      batch.set(topRef, r, SetOptions(merge: true));
    }
    await batch.commit();
    return records.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 6. SEED HEALTH CASES (30+ Distributed Cases)
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedHealthCases() async {
    final now = DateTime.now();

    final cases = <Map<String, dynamic>>[
      // ─── NASHIK OUTBREAK EPIDEMIC CASES (CRITICAL & HIGH) ───────────────────
      {
        'id': 'case_demo_001',
        'caseNumber': 'HC-NSK-2026-001',
        'farmId': 'farm_demo_001',
        'farmName': 'Green Valley Poultry Farm',
        'flockId': 'batch_demo_001',
        'flockName': 'Cobb 500 — Shed 1 (Batch B08)',
        'farmerId': 'farmer_demo_001',
        'district': 'Nashik',
        'affectedCount': 42,
        'mortalityCount': 15,
        'symptoms': ['Acute gasping', 'Tracheal clicking', 'Comb cyanosis', 'Feed drop 24%'],
        'notes': 'Rapid onset respiratory distress with mortality surge in last 24h',
        'feedReductionPercent': 24.5,
        'waterReductionPercent': 18.2,
        'temperature': 31.5,
        'humidity': 68.0,
        'riskScore': 88,
        'riskLevel': 'critical',
        'riskReasons': ['Mortality spike > 300% above 7d baseline', 'Severe respiratory distress syndrome', 'Rapid flock feed intake collapse'],
        'possibleDiseases': ['Newcastle Disease (Virulent/Velogenic)', 'Infectious Bronchitis (IBV)'],
        'status': 'under_investigation',
        'escalationStatus': 'vet_assigned',
        'assignedVetId': 'vet_demo_001',
        'veterinarianAssessment': 'Attended onsite by Dr. V. Sharma. Necropsy reveals petechial hemorrhages on proventricular glands and tracheitis. Viral PCR swab collected.',
        'diagnosis': 'Suspected Velogenic Newcastle Disease',
        'labRequired': true,
        'reportedAt': now.subtract(const Duration(hours: 14)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'case_demo_002',
        'caseNumber': 'HC-NSK-2026-002',
        'farmId': 'farm_demo_002',
        'farmName': 'Sahyadri Poultry Centre',
        'flockId': 'batch_demo_002',
        'flockName': 'Ross 308 — Shed 1 (Batch B04)',
        'farmerId': 'farmer_demo_002',
        'district': 'Nashik',
        'affectedCount': 28,
        'mortalityCount': 12,
        'symptoms': ['Tracheal rales', 'Facial swelling', 'Severe coughing'],
        'notes': 'Second farm within 3.5km of Dindori axis reporting identical signs',
        'feedReductionPercent': 19.0,
        'waterReductionPercent': 14.5,
        'temperature': 30.8,
        'humidity': 65.0,
        'riskScore': 82,
        'riskLevel': 'critical',
        'riskReasons': ['Spatial clustering within 5km radius of active incident', 'Severe respiratory anomaly'],
        'possibleDiseases': ['Newcastle Disease', 'Avian Metapneumovirus'],
        'status': 'under_investigation',
        'escalationStatus': 'vet_assigned',
        'assignedVetId': 'vet_demo_001',
        'veterinarianAssessment': 'Isolation barrier verified. Tracheal swab dispatched to DAH Pune.',
        'diagnosis': 'Acute Viral Respiratory Syndrome',
        'labRequired': true,
        'reportedAt': now.subtract(const Duration(hours: 26)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'case_demo_003',
        'caseNumber': 'HC-NSK-2026-003',
        'farmId': 'farm_demo_004',
        'farmName': 'Shivneri Poultry Farm',
        'flockId': 'batch_demo_003',
        'flockName': 'Shivneri Broiler Batch 02',
        'farmerId': 'farmer_demo_002',
        'district': 'Nashik',
        'affectedCount': 31,
        'mortalityCount': 11,
        'symptoms': ['Gasping', 'Submandibular edema', 'Greenish diarrhea'],
        'notes': 'Index farm 3 in spatial cordon (6.2km from Green Valley)',
        'feedReductionPercent': 21.0,
        'waterReductionPercent': 16.0,
        'temperature': 31.0,
        'humidity': 64.0,
        'riskScore': 84,
        'riskLevel': 'critical',
        'riskReasons': ['High mortality in young broilers', 'Tracheal rales with cyanosis'],
        'possibleDiseases': ['Newcastle Disease', 'Infectious Laryngotracheitis (ILT)'],
        'status': 'sample_requested',
        'escalationStatus': 'vet_assigned',
        'assignedVetId': 'vet_demo_002',
        'veterinarianAssessment': 'Preliminary triage by Dr. Neha Kulkarni. Quarantine perimeter established.',
        'diagnosis': 'Severe Respiratory Outbreak Case',
        'labRequired': true,
        'reportedAt': now.subtract(const Duration(hours: 48)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },

      // ─── PUNE DISTRICT CASES (MODERATE & HIGH) ──────────────────────────────
      {
        'id': 'case_demo_004',
        'caseNumber': 'HC-PUN-2026-004',
        'farmId': 'farm_demo_006',
        'farmName': 'Pune Sunrise Poultry',
        'flockId': 'batch_demo_pun_01',
        'flockName': 'Sunrise Broiler Unit 1',
        'farmerId': 'farmer_demo_003',
        'district': 'Pune',
        'affectedCount': 14,
        'mortalityCount': 3,
        'symptoms': ['Mild enteric dropping', 'Decreased water intake', 'Lethargy'],
        'notes': 'Digestive anomaly under veterinary observation',
        'feedReductionPercent': 8.5,
        'waterReductionPercent': 11.0,
        'temperature': 29.5,
        'humidity': 60.0,
        'riskScore': 42,
        'riskLevel': 'moderate',
        'riskReasons': ['Enteric syndrome without high mortality', 'Isolated single farm incidence'],
        'possibleDiseases': ['Coccidiosis (Mild)', 'Enteric Bacterial Dysbiosis'],
        'status': 'vet_assigned',
        'escalationStatus': 'vet_assigned',
        'assignedVetId': 'vet_demo_003',
        'veterinarianAssessment': 'Electrolytes and coccidiostat prescribed. Flock recovering.',
        'diagnosis': 'Subacute Coccidiosis',
        'labRequired': false,
        'reportedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'case_demo_005',
        'caseNumber': 'HC-PUN-2026-005',
        'farmId': 'farm_demo_007',
        'farmName': 'Bhima Dairy Farm',
        'flockId': 'herd_bhima_01',
        'flockName': 'Milking Herd Unit A',
        'farmerId': 'farmer_demo_003',
        'district': 'Pune',
        'affectedCount': 4,
        'mortalityCount': 0,
        'symptoms': ['Fever 104°F', 'Drop in milk yield 35%', 'Nasal discharge in 2 cows'],
        'notes': 'Dairy herd febrile episode',
        'riskScore': 58,
        'riskLevel': 'high',
        'riskReasons': ['Acute pyrexia in multiple high-yield dairy animals', 'Sharp milk yield drop'],
        'possibleDiseases': ['Bovine Ephemeral Fever', 'Bovine Respiratory Syncytial Virus'],
        'status': 'treatment_started',
        'escalationStatus': 'vet_assigned',
        'assignedVetId': 'vet_demo_003',
        'veterinarianAssessment': 'Antipyretics and supportive anti-inflammatories administered.',
        'diagnosis': 'Bovine Ephemeral Fever (Three-Day Sickness)',
        'labRequired': true,
        'reportedAt': now.subtract(const Duration(days: 3)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },

      // ─── NAGPUR DISTRICT CASES ──────────────────────────────────────────────
      {
        'id': 'case_demo_006',
        'caseNumber': 'HC-NAG-2026-006',
        'farmId': 'farm_demo_010',
        'farmName': 'Nagpur Poultry Hub',
        'flockId': 'batch_demo_nag_01',
        'flockName': 'Nagpur Broiler Shed 2',
        'farmerId': 'farmer_demo_004',
        'district': 'Nagpur',
        'affectedCount': 18,
        'mortalityCount': 4,
        'symptoms': ['Mild respiratory clicking', 'Reduced feed conversion'],
        'notes': 'Suspected ammonia irritation vs early bronchitis',
        'riskScore': 48,
        'riskLevel': 'moderate',
        'riskReasons': ['Elevated litter moisture and poor shed ventilation'],
        'possibleDiseases': ['Ammonia Burn / Tracheitis', 'Mild Infectious Bronchitis'],
        'status': 'under_investigation',
        'escalationStatus': 'vet_assigned',
        'assignedVetId': 'vet_demo_004',
        'diagnosis': 'Environmental Tracheitis with Secondary Bacterial Risk',
        'labRequired': false,
        'reportedAt': now.subtract(const Duration(days: 1)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },

      // ─── AHMEDNAGAR & SANGLI & SOLAPUR CASES ─────────────────────────────────
      {
        'id': 'case_demo_007',
        'caseNumber': 'HC-AHM-2026-007',
        'farmId': 'farm_demo_019',
        'farmName': 'Ahmednagar Poultry Farm',
        'flockId': 'batch_demo_ahm_01',
        'flockName': 'Ahmednagar Layer Unit B',
        'farmerId': 'farmer_demo_001',
        'district': 'Ahmednagar',
        'affectedCount': 6,
        'mortalityCount': 1,
        'symptoms': ['Shell quality defects', 'Mild lethargy'],
        'notes': 'Routine layer health check',
        'riskScore': 28,
        'riskLevel': 'low',
        'riskReasons': ['Single cage row affected with calcium imbalance'],
        'possibleDiseases': ['Nutritional Calcium / D3 Deficiency'],
        'status': 'closed',
        'escalationStatus': 'resolved',
        'assignedVetId': 'vet_demo_001',
        'diagnosis': 'Dietary Mineral Deficiency (Resolved)',
        'labRequired': false,
        'reportedAt': now.subtract(const Duration(days: 6)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
    ];

    final batch = _firestore.batch();
    for (final c in cases) {
      final docRef = _firestore.collection('health_cases').doc(c['id']);
      batch.set(docRef, c, SetOptions(merge: true));
    }
    await batch.commit();
    return cases.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 7. SEED OUTBREAK CLUSTERS
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedOutbreakClusters() async {
    final now = DateTime.now();

    final clusters = <Map<String, dynamic>>[
      {
        'id': 'cluster_nashik_respiratory_2026',
        'clusterCode': 'OUT-2026-NSK-001',
        'species': 'poultry',
        'syndrome': 'respiratory',
        'possibleDisease': 'Newcastle Disease (Suspected Virulent Outbreak Cluster)',
        'caseIds': ['case_demo_001', 'case_demo_002', 'case_demo_003'],
        'farmIds': ['farm_demo_001', 'farm_demo_002', 'farm_demo_004'],
        'district': 'Nashik',
        'state': 'Maharashtra',
        'centerLatitude': 19.9975,
        'centerLongitude': 73.7898,
        'radiusKm': 6.8,
        'caseCount': 3,
        'farmCount': 3,
        'affectedCount': 101,
        'mortalityCount': 38,
        'clusterConfidence': 86,
        'confidenceLabel': 'high_confidence_cluster',
        'severity': 'critical',
        'status': 'under_investigation',
        'summary': '3 commercial broiler farms located within 6.8km in Dindori-Niphad corridor reporting severe acute gasping and mortality surge > 300% within 48h.',
        'containmentActions': [
          'Mandatory 5km buffer containment ring activated',
          'Field veterinary inspection unit deployed',
          'RT-PCR viral isolation testing prioritized at DAH State Central Lab',
          'Emergency ring-vaccination advisory issued for 14 peripheral farms',
        ],
        'firstDetectedAt': now.subtract(const Duration(hours: 48)).toIso8601String(),
        'lastCaseAt': now.subtract(const Duration(hours: 14)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
    ];

    final batch = _firestore.batch();
    for (final cl in clusters) {
      final docRef = _firestore.collection('outbreak_clusters').doc(cl['id']);
      batch.set(docRef, cl, SetOptions(merge: true));
    }
    await batch.commit();
    return clusters.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 8. SEED DIAGNOSTIC LAB TESTS
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedLabTests() async {
    final now = DateTime.now();

    final tests = <Map<String, dynamic>>[
      {
        'id': 'lab_demo_001',
        'sampleId': 'SPL-2026-NSK-0841',
        'sampleBarcode': 'BC-841920-NSK',
        'caseId': 'case_demo_001',
        'farmId': 'farm_demo_001',
        'farmName': 'Green Valley Poultry Farm',
        'flockId': 'batch_demo_001',
        'district': 'Nashik',
        'veterinarianId': 'vet_demo_001',
        'veterinarianName': 'Dr. Vikram Sharma',
        'sampleType': 'Tracheal & Cloacal Swabs',
        'testRequested': 'Real-Time RT-PCR for Avian Paramyxovirus-1 (NDV)',
        'testingLaboratory': 'State Animal Disease Diagnostic Laboratory, Pune',
        'status': 'testing',
        'resultCategory': 'inconclusive',
        'notes': 'High-priority viral isolation in progress. Preliminary fluorescent antibody test positive.',
        'isEmergency': true,
        'createdAt': now.subtract(const Duration(hours: 12)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'lab_demo_002',
        'sampleId': 'SPL-2026-NSK-0842',
        'sampleBarcode': 'BC-841921-NSK',
        'caseId': 'case_demo_002',
        'farmId': 'farm_demo_002',
        'farmName': 'Sahyadri Poultry Centre',
        'flockId': 'batch_demo_002',
        'district': 'Nashik',
        'veterinarianId': 'vet_demo_001',
        'veterinarianName': 'Dr. Vikram Sharma',
        'sampleType': 'Tracheal Exudate Swab',
        'testRequested': 'Avian Viral Panel PCR (NDV + IBV + AIV)',
        'testingLaboratory': 'District Veterinary Polyclinic Lab, Nashik',
        'status': 'dispatched',
        'resultCategory': 'inconclusive',
        'notes': 'Cold chain transport to Pune confirmed.',
        'isEmergency': true,
        'createdAt': now.subtract(const Duration(hours: 20)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'lab_demo_003',
        'sampleId': 'SPL-2026-PUN-0711',
        'sampleBarcode': 'BC-711094-PUN',
        'caseId': 'case_demo_005',
        'farmId': 'farm_demo_007',
        'farmName': 'Bhima Dairy Farm',
        'district': 'Pune',
        'veterinarianId': 'vet_demo_003',
        'veterinarianName': 'Dr. Rajesh Pawar',
        'sampleType': 'Whole Blood (EDTA)',
        'testRequested': 'Serological ELISA for BEF Viral Titers',
        'testingLaboratory': 'Western Regional Disease Diagnostic Lab, Pune',
        'status': 'result_available',
        'resultCategory': 'positive',
        'pathogenDetected': 'Bovine Ephemeral Fever Virus (BEFV)',
        'notes': 'Significant antibody rise confirmed. Supportive recovery protocol effective.',
        'isEmergency': false,
        'createdAt': now.subtract(const Duration(days: 3)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(hours: 4)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'lab_demo_004',
        'sampleId': 'SPL-2026-NAG-0391',
        'sampleBarcode': 'BC-391024-NAG',
        'caseId': 'case_demo_006',
        'farmId': 'farm_demo_010',
        'farmName': 'Nagpur Poultry Hub',
        'district': 'Nagpur',
        'veterinarianId': 'vet_demo_004',
        'veterinarianName': 'Dr. Smita Joshi',
        'sampleType': 'Tracheal Swabs',
        'testRequested': 'Bacterial Culture & Sensitivity',
        'testingLaboratory': 'Regional Animal Health Lab, Nagpur',
        'status': 'reviewed',
        'resultCategory': 'negative',
        'pathogenDetected': 'None (Commensal Flora Only)',
        'notes': 'Bacterial etiology ruled out. Environment and ventilation remediation confirmed.',
        'isEmergency': false,
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'updatedAt': now.subtract(const Duration(hours: 8)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
    ];

    final batch = _firestore.batch();
    for (final lt in tests) {
      final docRef = _firestore.collection('lab_tests').doc(lt['id']);
      batch.set(docRef, lt, SetOptions(merge: true));
    }
    await batch.commit();
    return tests.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 9. SEED BIOSECURITY ASSESSMENTS (Actual Question Scoring)
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedBiosecurityAssessments() async {
    final now = DateTime.now();

    final assessments = <Map<String, dynamic>>[
      // Green Valley: 76/100 (Tier-1 High Integrity)
      {
        'id': 'bio_demo_001',
        'farmId': 'farm_demo_001',
        'farmName': 'Green Valley Poultry Farm',
        'score': 76,
        'strength': 'good',
        'visitorLogMaintained': 'yes',
        'restrictedEntry': 'yes',
        'footwearDisinfection': 'yes',
        'vehicleDisinfection': 'yes',
        'protectiveClothing': 'partial',
        'isolationAreaAvailable': 'yes',
        'sickAnimalsIsolated': 'yes',
        'newAnimalsQuarantined': 'yes',
        'ageGroupsSeparated': 'yes',
        'routineShedCleaning': 'yes',
        'disinfectionBetweenBatches': 'yes',
        'disinfectantTypeUsed': 'Glutaraldehyde + QAC Compound',
        'allInAllOutPracticed': 'yes',
        'wildBirdRodentProofing': 'partial',
        'cleanWaterSource': 'yes',
        'feedStorageSecure': 'yes',
        'mortalityDisposalMethod': 'Deep Pit Composting with Lime',
        'vaccinationScheduleFollowed': 'yes',
        'completedBy': 'Dr. Vikram Sharma (Attending Vet)',
        'completedAt': now.subtract(const Duration(days: 10)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },

      // Sahyadri Poultry: 68/100 (Good Baseline)
      {
        'id': 'bio_demo_002',
        'farmId': 'farm_demo_002',
        'farmName': 'Sahyadri Poultry Centre',
        'score': 68,
        'strength': 'good',
        'visitorLogMaintained': 'yes',
        'restrictedEntry': 'partial',
        'footwearDisinfection': 'yes',
        'vehicleDisinfection': 'partial',
        'protectiveClothing': 'partial',
        'isolationAreaAvailable': 'partial',
        'sickAnimalsIsolated': 'yes',
        'newAnimalsQuarantined': 'partial',
        'ageGroupsSeparated': 'yes',
        'routineShedCleaning': 'yes',
        'disinfectionBetweenBatches': 'yes',
        'disinfectantTypeUsed': 'Bleaching Powder + Formalin',
        'allInAllOutPracticed': 'yes',
        'wildBirdRodentProofing': 'no',
        'cleanWaterSource': 'yes',
        'feedStorageSecure': 'yes',
        'mortalityDisposalMethod': 'Incineration',
        'vaccinationScheduleFollowed': 'partial',
        'completedBy': 'Suresh Demo Deshmukh',
        'completedAt': now.subtract(const Duration(days: 20)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },

      // Shivneri Poultry: 52/100 (Needs Improvement)
      {
        'id': 'bio_demo_003',
        'farmId': 'farm_demo_004',
        'farmName': 'Shivneri Poultry Farm',
        'score': 52,
        'strength': 'needs_improvement',
        'visitorLogMaintained': 'no',
        'restrictedEntry': 'partial',
        'footwearDisinfection': 'partial',
        'vehicleDisinfection': 'no',
        'protectiveClothing': 'no',
        'isolationAreaAvailable': 'no',
        'sickAnimalsIsolated': 'partial',
        'newAnimalsQuarantined': 'no',
        'ageGroupsSeparated': 'yes',
        'routineShedCleaning': 'partial',
        'disinfectionBetweenBatches': 'yes',
        'disinfectantTypeUsed': 'Phenolic Compound',
        'allInAllOutPracticed': 'yes',
        'wildBirdRodentProofing': 'no',
        'cleanWaterSource': 'yes',
        'feedStorageSecure': 'partial',
        'mortalityDisposalMethod': 'Open Pit Burial',
        'vaccinationScheduleFollowed': 'no',
        'completedBy': 'Dr. Neha Kulkarni',
        'completedAt': now.subtract(const Duration(days: 5)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
    ];

    final batch = _firestore.batch();
    for (final b in assessments) {
      final docRef = _firestore.collection('biosecurity_assessments').doc(b['id']);
      batch.set(docRef, b, SetOptions(merge: true));
    }
    await batch.commit();
    return assessments.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 10. SEED PREVENTION RECOMMENDATIONS
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedPreventionRecommendations() async {
    final now = DateTime.now();

    final recommendations = <Map<String, dynamic>>[
      {
        'id': 'prev_demo_001',
        'farmId': 'farm_demo_001',
        'caseId': 'case_demo_001',
        'clusterId': 'cluster_nashik_respiratory_2026',
        'source': 'nearby_cluster',
        'category': 'disinfection',
        'priority': 'critical',
        'title': 'Mandatory Vehicle Wheel & Gate Disinfection Dip',
        'description': 'Active respiratory disease cluster (OUT-2026-NSK-001) confirmed within 6.8km. Disinfect all feed trucks and egg crates entering farm perimeter.',
        'recommendedAction': 'Install vehicle wheel wash with 2% glutaraldehyde or Virkon-S at the main entry gate immediately.',
        'reason': 'Aerosol and vehicular vector transmission prevention for viral paramyxovirus.',
        'ruleCode': 'RULE_CLUSTER_VEHICLE_DISINFECTION',
        'status': 'in_progress',
        'createdAt': now.subtract(const Duration(hours: 12)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'prev_demo_002',
        'farmId': 'farm_demo_001',
        'source': 'biosecurity_assessment',
        'category': 'water_feed',
        'priority': 'high',
        'title': 'Water Sanitization & Chlorination Protocol',
        'description': 'Maintain chlorine level of 3–5 ppm in overhead water tanks to eliminate microbial biofilms during humid periods.',
        'recommendedAction': 'Add sodium hypochlorite or chlorine dioxide tablets daily to main storage reservoir.',
        'reason': 'Waterborne secondary colibacillosis infection reduction.',
        'ruleCode': 'RULE_WATER_CHLORINATION_AUDIT',
        'status': 'recommended',
        'createdAt': now.subtract(const Duration(days: 2)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'prev_demo_003',
        'farmId': 'farm_demo_003',
        'clusterId': 'cluster_nashik_respiratory_2026',
        'source': 'nearby_cluster',
        'category': 'flock_isolation',
        'priority': 'critical',
        'title': 'Preemptive Layer Flock Protection Barrier',
        'description': 'Farm is 8.4km from epicenter. Restrict all visitor entry and seal shed netting against wild bird intrusion.',
        'recommendedAction': 'Enforce complete biosecurity cordon and inspect air intake louvers for bird-proofing wire mesh.',
        'reason': 'Containment of multi-farm cluster spread.',
        'ruleCode': 'RULE_PREVENT_CORDON_BUFFER',
        'status': 'recommended',
        'createdAt': now.subtract(const Duration(hours: 8)).toIso8601String(),
        'updatedAt': now.toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
    ];

    final batch = _firestore.batch();
    for (final pr in recommendations) {
      final docRef = _firestore.collection('prevention_recommendations').doc(pr['id']);
      batch.set(docRef, pr, SetOptions(merge: true));
    }
    await batch.commit();
    return recommendations.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 11. SEED NOTIFICATIONS
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<int> _seedNotifications() async {
    final now = DateTime.now();

    final notifications = <Map<String, dynamic>>[
      {
        'id': 'notif_demo_001',
        'recipientId': 'farmer_demo_001',
        'title': 'Outbreak Warning: Active Cluster in Nashik District',
        'message': 'A multi-farm respiratory cluster (OUT-2026-NSK-001) has been detected within 10 km of your facility. Review biosecurity protocols immediately.',
        'type': 'CRITICAL_ALERT',
        'category': 'outbreak_alert',
        'isRead': false,
        'createdAt': now.subtract(const Duration(hours: 10)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'notif_demo_002',
        'recipientId': 'vet_demo_001',
        'title': 'P1 Critical Case Assigned: HC-NSK-2026-001',
        'message': 'Severe acute respiratory incident with mortality surge logged at Green Valley Poultry Farm. Immediate clinical review required.',
        'type': 'VET_ASSIGNMENT',
        'category': 'triage_queue',
        'isRead': true,
        'createdAt': now.subtract(const Duration(hours: 14)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
      {
        'id': 'notif_demo_003',
        'recipientId': 'gov_demo_001',
        'title': 'Epidemiological Alert: Multi-Farm Outbreak Cluster Formed',
        'message': 'Cluster OUT-2026-NSK-001 in Dindori Taluka, Nashik now encompasses 3 poultry premises with 38 reported bird mortalities.',
        'type': 'GOVERNMENT_GIS',
        'category': 'cluster_detection',
        'isRead': false,
        'createdAt': now.subtract(const Duration(hours: 16)).toIso8601String(),
        'isDemoData': true,
        'demoDatasetVersion': demoDatasetVersion,
      },
    ];

    final batch = _firestore.batch();
    for (final n in notifications) {
      final docRef = _firestore.collection('notifications').doc(n['id']);
      batch.set(docRef, n, SetOptions(merge: true));
    }
    await batch.commit();
    return notifications.length;
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // 12. RESET DEMO DATA (Safe Dev-Only Cleanup)
  // ─────────────────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> resetDemoData() async {
    debugPrint('[DevSeeder] Resetting demo data tagged with demoDatasetVersion=$demoDatasetVersion...');
    final collections = [
      'outbreak_clusters',
      'health_cases',
      'lab_tests',
      'biosecurity_assessments',
      'prevention_recommendations',
      'notifications',
      'daily_records',
      'batches',
      'farms',
    ];

    int deletedCount = 0;
    try {
      for (final col in collections) {
        final snap = await _firestore
            .collection(col)
            .where('isDemoData', isEqualTo: true)
            .get();

        final batch = _firestore.batch();
        for (final doc in snap.docs) {
          batch.delete(doc.reference);
          deletedCount++;
        }
        await batch.commit();
      }

      debugPrint('[DevSeeder] Reset completed. Deleted $deletedCount demo documents.');
      return {'success': true, 'deletedDocuments': deletedCount};
    } catch (e) {
      debugPrint('[DevSeeder] Reset error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
