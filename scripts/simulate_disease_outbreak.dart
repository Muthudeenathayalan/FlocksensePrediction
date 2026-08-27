/// Simulation script to test cluster anomaly detection with sudden mortality jumps
void main() {
  const farmIds = ['farm_north_01', 'farm_north_02', 'farm_north_03', 'farm_central_01'];
  print('Running simulated outbreak cluster evaluation for regional surveillance:');

  for (final farmId in farmIds) {
    final isOutbreak = farmId.startsWith('farm_north');
    final mortality = isOutbreak ? 120 : 5;
    final riskScore = isOutbreak ? 94.5 : 12.0;

    print('Farm: $farmId -> Daily Mortality: $mortality -> Risk Score: $riskScore -> Status: ${isOutbreak ? "CRITICAL OUTBREAK DETECTED" : "NORMAL"}');
  }
}
