import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flock_sense/features/landing/presentation/screens/agriculture_landing_screen.dart';
import 'package:flock_sense/features/landing/presentation/widgets/landing_sections.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestScreen({bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(1440, 1080),
          disableAnimations: disableAnimations,
        ),
        child: const AgricultureLandingScreen(),
      ),
    );
  }

  group('FlockSense Livestock Disease Surveillance Landing Suite', () {
    testWidgets('1. Verify complete semantic section hierarchy & problem statement alignment', (tester) async {
      tester.view.physicalSize = const Size(1440, 2500);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump(const Duration(milliseconds: 1000));

      // Brand Logo & Navigation
      expect(find.byType(LandingNavbar), findsOneWidget);
      expect(find.text('FLOCKSENSE'), findsWidgets);
      expect(find.text('Livestock Health & Outbreak Surveillance'), findsOneWidget);
      expect(find.text('Launch Platform'), findsWidgets);

      // Navigation Items
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Solutions'), findsWidgets);
      expect(find.text('Benefits'), findsOneWidget);
      expect(find.text('How It Works'), findsOneWidget);
      expect(find.text('Trust'), findsOneWidget);
      expect(find.text('Contact'), findsOneWidget);

      // Hero Section: Exact Problem Statement
      expect(find.byType(LandingHeroSection), findsOneWidget);
      expect(find.text('SMART INDIA HACKATHON • SIH26128'), findsOneWidget);
      expect(
        find.text('Efficient Systems for Early Detection, Prevention & Management of Livestock Diseases'),
        findsOneWidget,
      );
      expect(find.text('Explore Surveillance Suite'), findsOneWidget);

      // Measurable Impact Stats
      expect(find.byType(LandingStatsSection), findsOneWidget);
      expect(find.text('-78%'), findsOneWidget);
      expect(find.text('99.4%'), findsOneWidget);
      expect(find.text('3.8M+'), findsOneWidget);
      expect(find.text('< 15 min'), findsOneWidget);

      // About Section
      expect(find.byType(LandingAboutSection), findsOneWidget);
      expect(find.text('SIH PROBLEM STATEMENT ARCHITECTURE'), findsOneWidget);

      // Solutions Section
      expect(find.byType(LandingSolutionsSection), findsOneWidget);
      expect(find.text('CORE SURVEILLANCE MODULES'), findsOneWidget);
      expect(find.text('End-to-End Livestock Disease Prevention Architecture'), findsOneWidget);

      // Benefits Section
      expect(find.byType(LandingBenefitsSection), findsOneWidget);
      expect(find.text('SYSTEM OUTCOMES & BIOSECURITY GAINS'), findsOneWidget);

      // How It Works Section
      expect(find.byType(LandingHowItWorksSection), findsOneWidget);
      expect(find.text('TRI-TIER SURVEILLANCE PIPELINE'), findsOneWidget);

      // Capabilities Section
      expect(find.byType(LandingCapabilitiesSection), findsOneWidget);
      expect(find.text('HEALTHCARE IT INFRASTRUCTURE'), findsOneWidget);

      // Trust & Testimonials Section
      expect(find.byType(LandingTrustSection), findsOneWidget);
      expect(find.text('ACCREDITATION & FIELD VALIDATION'), findsOneWidget);

      // Final CTA Banner
      expect(find.byType(LandingCtaBanner), findsOneWidget);
      expect(find.text('Ready to Implement Early Disease Detection in Your Facilities?'), findsOneWidget);

      // Footer
      expect(find.byType(LandingFooter), findsOneWidget);
      expect(find.text('© 2026 FlockSense Animal Health Intelligence. SIH26128 Prototype.'), findsOneWidget);
    });

    testWidgets('2. Verify smooth navigation interactions and scroll trigger', (tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen());
      await tester.pump(const Duration(milliseconds: 1000));

      // Tap 'Solutions' nav link
      final solutionsLink = find.descendant(
        of: find.byType(LandingNavbar),
        matching: find.text('Solutions'),
      );
      expect(solutionsLink, findsOneWidget);
      await tester.tap(solutionsLink);
      await tester.pump(const Duration(milliseconds: 700));

      // Tap primary hero button
      final exploreBtn = find.text('Explore Surveillance Suite');
      expect(exploreBtn, findsOneWidget);
      await tester.tap(exploreBtn, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 700));

      // Verify page remains stable and mounted
      expect(find.byType(AgricultureLandingScreen), findsOneWidget);
    });

    testWidgets('3. Respects user prefers-reduced-motion setting (disableAnimations: true)', (tester) async {
      tester.view.physicalSize = const Size(1440, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestScreen(disableAnimations: true));
      await tester.pumpAndSettle();

      // Ensure headline and content render immediately
      expect(
        find.text('Efficient Systems for Early Detection, Prevention & Management of Livestock Diseases'),
        findsOneWidget,
      );
      expect(find.text('FLOCKSENSE'), findsWidgets);
    });
  });
}
