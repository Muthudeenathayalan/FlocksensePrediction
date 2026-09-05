import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/auth/presentation/providers/auth_providers.dart';
import 'package:flock_sense/features/batches/presentation/screens/batch_list_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_record_form_screen.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/farms/data/farm_service.dart';
import 'package:flock_sense/features/farms/presentation/providers/farm_providers.dart';
import 'package:flock_sense/features/feed/presentation/screens/feed_inventory_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_command_center_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/health_screen.dart';
import 'package:flock_sense/features/home/presentation/screens/farmer_dashboard_screen.dart';
import 'package:flock_sense/features/home/presentation/screens/veterinarian_dashboard_screen.dart';
import 'package:flock_sense/features/intelligence/presentation/screens/farm_health_intelligence_screen.dart';
import 'package:flock_sense/features/intelligence/presentation/widgets/visitor_log_dialog.dart';
import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({required Widget child}) {
    return ProviderScope(
      overrides: [
        currentUserProfileProvider.overrideWith((ref) => Stream.value(null)),
        farmListProvider.overrideWith((ref) => Stream.value(FarmService.inMemoryFarms)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('FlockSense Comprehensive Button & Navigation Flow Tests', () {
    testWidgets('1. Test Role Switcher Ribbon Buttons (Farmer -> Veterinarian -> Government)', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const MainShellScreen(initialRole: 'Farmer')));
      await tester.pumpAndSettle();

      // Verify initial Farmer screen
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
      expect(find.text('SIH PROTOTYPE'), findsOneWidget);

      // Click 'Veterinarian' button
      final vetButton = find.text('Veterinarian');
      expect(vetButton, findsOneWidget);
      await tester.tap(vetButton);
      await tester.pumpAndSettle();

      // Verify Veterinarian screen rendered
      expect(find.byType(VeterinarianDashboardScreen), findsOneWidget);

      // Click 'Government' button
      final govButton = find.text('Government');
      expect(govButton, findsOneWidget);
      await tester.tap(govButton);
      await tester.pumpAndSettle();

      // Verify Government screen rendered
      expect(find.byType(GovernmentCommandCenterScreen), findsOneWidget);

      // Click 'Farmer' button to return
      final farmerButton = find.text('Farmer');
      expect(farmerButton, findsOneWidget);
      await tester.tap(farmerButton);
      await tester.pumpAndSettle();

      // Verify back to Farmer
      expect(find.byType(FarmerDashboardScreen), findsOneWidget);
    });

    testWidgets('2. Test Farmer Dashboard 4 Action Buttons', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const MainShellScreen(initialRole: 'Farmer')));
      await tester.pumpAndSettle();

      // Button A: 'Log Daily Record'
      final logDailyBtn = find.text('Log Daily Record');
      expect(logDailyBtn, findsOneWidget);
      await tester.tap(logDailyBtn);
      await tester.pumpAndSettle();
      expect(find.byType(DailyRecordFormScreen), findsOneWidget);

      // Go back
      final NavigatorState navigator = tester.state(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();

      // Button B: 'Report Health Anomaly'
      final reportHealthBtn = find.text('Report Health Anomaly');
      expect(reportHealthBtn, findsOneWidget);
      await tester.tap(reportHealthBtn);
      await tester.pumpAndSettle();
      expect(find.byType(HealthScreen), findsOneWidget);

      // Go back
      final NavigatorState navigator2 = tester.state(find.byType(Navigator).last);
      navigator2.pop();
      await tester.pumpAndSettle();

      // Button C: 'Log Farm Visitor'
      final logVisitorBtn = find.text('Log Farm Visitor');
      expect(logVisitorBtn, findsOneWidget);
      await tester.tap(logVisitorBtn);
      await tester.pumpAndSettle();
      expect(find.byType(VisitorLogDialog), findsOneWidget);

      // Close dialog
      final NavigatorState navigator3 = tester.state(find.byType(Navigator).last);
      navigator3.pop();
      await tester.pumpAndSettle();

      // Button D: 'Intelligence Engine'
      final intelEngineBtn = find.text('Intelligence Engine');
      expect(intelEngineBtn, findsOneWidget);
      await tester.tap(intelEngineBtn);
      await tester.pumpAndSettle();
      expect(find.byType(FarmHealthIntelligenceScreen), findsOneWidget);
    });

    testWidgets('3. Test Farmer Dashboard 4 Metric Cards Taps', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestWidget(child: const MainShellScreen(initialRole: 'Farmer')));
      await tester.pumpAndSettle();

      // Card 1: Farm Health Risk -> opens FarmHealthIntelligenceScreen
      final healthRiskCard = find.text('Farm Health Risk');
      expect(healthRiskCard, findsOneWidget);
      await tester.tap(healthRiskCard);
      await tester.pumpAndSettle();
      expect(find.byType(FarmHealthIntelligenceScreen), findsOneWidget);

      // Go back
      final NavigatorState navigator = tester.state(find.byType(Navigator).last);
      navigator.pop();
      await tester.pumpAndSettle();

      // Card 2: Daily Mortality vs Baseline -> opens DailyRecordsDashboardScreen
      final mortalityCard = find.text('Daily Mortality vs Baseline');
      expect(mortalityCard, findsOneWidget);
      await tester.tap(mortalityCard);
      await tester.pumpAndSettle();
      expect(find.byType(DailyRecordsDashboardScreen), findsOneWidget);

      // Go back
      final NavigatorState navigator2 = tester.state(find.byType(Navigator).last);
      navigator2.pop();
      await tester.pumpAndSettle();

      // Card 3: Feed Intake vs Baseline -> opens FeedInventoryScreen
      final feedCard = find.text('Feed Intake vs Baseline');
      expect(feedCard, findsOneWidget);
      await tester.tap(feedCard);
      await tester.pumpAndSettle();
      expect(find.byType(FeedInventoryScreen), findsOneWidget);

      // Go back
      final NavigatorState navigator3 = tester.state(find.byType(Navigator).last);
      navigator3.pop();
      await tester.pumpAndSettle();

      // Card 4: Water Intake vs Baseline -> opens FeedInventoryScreen
      final waterCard = find.text('Water Intake vs Baseline');
      expect(waterCard, findsOneWidget);
      await tester.tap(waterCard);
      await tester.pumpAndSettle();
      expect(find.byType(FeedInventoryScreen), findsOneWidget);
    });
  });
}
