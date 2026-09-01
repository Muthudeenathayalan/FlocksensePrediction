import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/sheds/data/shed_service.dart';
import 'package:flock_sense/features/sheds/domain/shed_model.dart';
import 'package:flock_sense/core/models/sync_status.dart';

/// Family provider: pass farmId to get its sheds as a real-time stream.
final shedListProvider = StreamProvider.autoDispose
    .family<List<ShedModel>, String>((ref, farmId) {
      return ShedService.watchSheds(farmId);
    });

/// Sync status for a specific farm's sheds collection.
final shedSyncStatusProvider = StreamProvider.autoDispose
    .family<SyncStatus, String>((ref, farmId) {
      return ShedService.watchSyncStatus(farmId);
    });
