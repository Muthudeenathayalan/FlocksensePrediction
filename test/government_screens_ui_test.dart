import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flock_sense/features/health/presentation/screens/government_command_center_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_gis_map_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_outbreak_registry_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_district_surveillance_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_cases_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_vaccination_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_biosecurity_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_vet_response_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/government_lab_surveillance_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget wrapScreen(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(size: Size(1440, 1080)),
            child: child,
          ),
        ),
      ),
    );
  }

  group('Government Surveillance Screens UI Suite', () {
    testWidgets('1. Verify Command Center mounts with DAHD header & KPIs', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapScreen(const GovernmentCommandCenterScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Animal Health Command Center'), findsOneWidget);
      expect(find.text('DAHD • MAHARASHTRA STATE COMMAND'), findsOneWidget);
      expect(find.text('Active Clusters'), findsOneWidget);
      expect(find.text('Critical Cases'), findsOneWidget);
      expect(find.text('Export Report'), findsOneWidget);
    });

    testWidgets('2. Verify GIS Map screen mounts with Live Epidemiology badge', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapScreen(const GovernmentGisMapScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('GIS Disease Surveillance & Spatial Epidemic Map'), findsOneWidget);
      expect(find.text('DAHD • LIVE EPIDEMIOLOGY'), findsOneWidget);
    });

    testWidgets('3. Verify Outbreak Registry mounts with Incident Command badge', (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(wrapScreen(const GovernmentOutbreakRegistryScreen()));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Outbreak Cluster Registry & Quarantine Cordon Management'), findsOneWidget);
      expect(find.text('INCIDENT COMMAND ACTIVE'), findsOneWidget);
    });

    testWidgets('4. Verify District Surveillance mounts with Epidemiological Triage badge', (tester) async {
      await tester.pumpWidget(wrapScreen(const GovernmentDistrictSurveillanceScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('District Surveillance & Epidemiological Triage'), findsOneWidget);
      expect(find.text('DAHD • EPIDEMIOLOGICAL TRIAGE'), findsOneWidget);
    });

    testWidgets('5. Verify Regional Cases screen mounts with Clinical Surveillance badge', (tester) async {
      await tester.pumpWidget(wrapScreen(const GovernmentCasesScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Regional Health Cases & Clinical Surveillance'), findsOneWidget);
      expect(find.text('DAHD • CLINICAL DISEASE SURVEILLANCE'), findsOneWidget);
    });

    testWidgets('6. Verify Vaccination screen mounts with Immunization Surveillance badge', (tester) async {
      await tester.pumpWidget(wrapScreen(const GovernmentVaccinationScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('State Vaccination Surveillance & Immunity Gap Tracking'), findsOneWidget);
      expect(find.text('DAHD • IMMUNIZATION SURVEILLANCE'), findsOneWidget);
    });

    testWidgets('7. Verify Biosecurity screen mounts with Preventive Posture badge', (tester) async {
      await tester.pumpWidget(wrapScreen(const GovernmentBiosecurityScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Biosecurity & Prevention Vulnerability Matrix'), findsOneWidget);
      expect(find.text('DAHD • PREVENTIVE BIOSECURITY POSTURE'), findsOneWidget);
    });

    testWidgets('8. Verify Veterinary Response screen mounts with Clinicians badge', (tester) async {
      await tester.pumpWidget(wrapScreen(const GovernmentVetResponseScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('State Veterinary Surveillance Network'), findsOneWidget);
      expect(find.text('4 Duty Clinicians Deployed'), findsOneWidget);
    });

    testWidgets('9. Verify Lab Surveillance screen mounts with RT-PCR badge', (tester) async {
      await tester.pumpWidget(wrapScreen(const GovernmentLabSurveillanceScreen()));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Laboratory Diagnostic Pipeline & Pathogen Surveillance'), findsOneWidget);
      expect(find.text('DAHD • PATHOGEN DIAGNOSTICS & RT-PCR'), findsOneWidget);
    });
  });
}
