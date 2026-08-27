import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/core/platform/connectivity_mobile.dart'
    if (dart.library.html) 'package:flock_sense/core/platform/connectivity_web.dart'
    as platform;

/// Emits whether this device currently has a working internet connection.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  yield await platform.checkInternetConnection();
  yield* Stream.periodic(
    const Duration(seconds: 6),
  ).asyncMap((_) => platform.checkInternetConnection());
});
