import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_provider.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/domain/farm_model.dart';

/// Real-time list of the user's farms from Firestore or local cache.
final farmListProvider = StreamProvider.autoDispose<List<FarmModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.value;
  if (user != null) {
    return FarmService.watchFarms(user.uid);
  }
  return FarmService.watchUserFarms();
});

/// Aggregate stats derived from farmListProvider — powers the Home dashboard.
class FarmDashboardStats {
  final int totalFarms;
  final int totalShedCapacity;
  final int currentBirds;
  final int activeBatches;

  const FarmDashboardStats({
    required this.totalFarms,
    required this.totalShedCapacity,
    required this.currentBirds,
    required this.activeBatches,
  });

  static const empty = FarmDashboardStats(
    totalFarms: 0,
    totalShedCapacity: 0,
    currentBirds: 0,
    activeBatches: 0,
  );
}

final farmDashboardStatsProvider = Provider.autoDispose<FarmDashboardStats>((
  ref,
) {
  final farmsAsync = ref.watch(farmListProvider);
  return farmsAsync.when(
    data: (farms) {
      final totalCapacity = farms.fold<int>(
        0,
        (sum, f) => sum + (f.capacity ?? (f.totalSqFt / 1.2).round()),
      );
      return FarmDashboardStats(
        totalFarms: farms.length,
        totalShedCapacity: totalCapacity,
        currentBirds: (totalCapacity * 0.85).round(),
        activeBatches: farms.length,
      );
    },
    loading: () => FarmDashboardStats.empty,
    error: (_, __) => FarmDashboardStats.empty,
  );
});
