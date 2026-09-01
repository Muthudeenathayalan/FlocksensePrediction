import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/batches/data/batch_service.dart';
import 'package:flock_sense/features/batches/domain/batch_model.dart';

final batchListProvider = StreamProvider.autoDispose
    .family<List<BatchModel>, String>((ref, farmId) {
      return BatchService.watchBatches(farmId);
    });
