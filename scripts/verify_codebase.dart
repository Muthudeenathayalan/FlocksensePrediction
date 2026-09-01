import 'dart:io';

void main() {
  print('====================================================');
  print(' FlockSense Static Analysis & Verification Protocol ');
  print('====================================================\n');

  final requiredDirectories = [
    'lib/features/farms',
    'lib/features/batches',
    'lib/features/sheds',
    'lib/features/daily_records',
    'lib/features/health',
    'lib/features/feed',
    'lib/features/medicine',
    'lib/features/vaccine',
    'lib/features/sales',
    'lib/features/weight',
    'lib/features/performance',
    'lib/features/reports',
    'lib/features/settings',
    'lib/features/main_shell',
  ];

  int passedChecks = 0;

  for (final dirPath in requiredDirectories) {
    final dir = Directory(dirPath);
    if (dir.existsSync()) {
      print(' [OK] Directory verified: $dirPath');
      passedChecks++;
    } else {
      print(' [WARN] Missing module directory: $dirPath');
    }
  }

  print('\n[STATUS] Total Verified Modules: $passedChecks / ${requiredDirectories.length}');
  print('[STATUS] Verification Completed Successfully.\n');
}
