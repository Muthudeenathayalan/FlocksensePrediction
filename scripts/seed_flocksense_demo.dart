import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flock_sense/firebase_options.dart';
import 'package:flock_sense/core/utils/dev_seeder.dart';

/// Standalone CLI / Entrypoint for Seeding FlockSense Demo Dataset
/// Usage: dart run lib/scripts/seed_flocksense_demo.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('====================================================');
  print(' FLOCKSENSE SYNTHETIC DATA SEEDER (SIH26128)        ');
  print('====================================================');

  try {
    print('Initializing Firebase connection...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully.');

    print('Starting idempotent demo dataset seeding...');
    final result = await DevSeeder.seedDemoData();

    if (result['success'] == true) {
      print('Seeding completed successfully!');
      print('Summary: ${result['counts']}');
    } else {
      print('Seeding failed: ${result['error']}');
    }
  } catch (e, st) {
    print('Fatal error during seeding: $e\n$st');
  }
}
