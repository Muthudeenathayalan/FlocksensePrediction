import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/app/app.dart';
import 'package:flock_sense/config/firebase_options.dart';
import 'package:flock_sense/core/services/cache_service.dart';
import 'package:flock_sense/core/services/fcm_token_service.dart';
import 'package:flock_sense/core/services/notification_service.dart';
import 'package:flock_sense/core/services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase core init
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    if (!e.toString().contains('duplicate-app')) {
      debugPrint('Firebase init error: $e');
    }
  }

  // 2. Enable Firestore persistence (Mobile/Desktop)
  if (!kIsWeb) {
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    } catch (e) {
      debugPrint('Firestore settings error: $e');
    }
  }

  // 3. Local Hive cache
  try {
    await CacheService().initialize();
  } catch (e) {
    debugPrint('CacheService init error: $e');
  }

  // 4. SyncService
  try {
    await SyncService().initialize();
  } catch (e) {
    debugPrint('SyncService init error: $e');
  }

  // 5. Notifications & FCM (Mobile/Desktop only)
  if (!kIsWeb) {
    try {
      await NotificationService.initialize();
      await FcmTokenService.saveTokenToFirestore();
    } catch (e) {
      debugPrint('NotificationService error: $e');
    }
  }

  runApp(const ProviderScope(child: App()));
}
