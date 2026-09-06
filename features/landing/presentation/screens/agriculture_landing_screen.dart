import 'package:flutter/material.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/features/landing/presentation/widgets/landing_sections.dart';

/// Production-Quality Agriculture Landing Page
/// Inspired by the visual direction, typography, and smooth transitions of Agronex.
class AgricultureLandingScreen extends StatefulWidget {
  const AgricultureLandingScreen({super.key});

  @override
  State<AgricultureLandingScreen> createState() => _AgricultureLandingScreenState();
}

class _AgricultureLandingScreenState extends State<AgricultureLandingScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  // Section GlobalKeys for smooth programmatic scrolling
  final GlobalKey _homeKey = GlobalKey();
  final GlobalKey _aboutKey = GlobalKey();
  final GlobalKey _solutionsKey = GlobalKey();
  final GlobalKey _benefitsKey = GlobalKey();
  final GlobalKey _howItWorksKey = GlobalKey();
  final GlobalKey _trustKey = GlobalKey();
  final GlobalKey _contactKey = GlobalKey();

  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // Trigger hero entrance after initial frame render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bool disableAnimations = MediaQuery.of(context).disableAnimations;
        if (disableAnimations) {
          _entranceController.value = 1.0;
        } else {
          _entranceController.forward();
        }
      }
    });
  }

  void _onScroll() {
    final bool scrolled = _scrollController.offset > 40;
    if (scrolled != _isScrolled) {
      setState(() => _isScrolled = scrolled);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _scrollToSection(GlobalKey key) {
    final BuildContext? targetContext = key.currentContext;
    if (targetContext != null) {
      final bool disableAnimations = MediaQuery.of(context).disableAnimations;
      Scrollable.ensureVisible(
        targetContext,
        duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.slate50,
      body: Stack(
        children: [
          // Main Scrollable Landing Page Content
          SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                // Top spacing to prevent floating navbar overlap
                const SizedBox(height: 84),

                // 1. Hero Section
                Container(
                  key: _homeKey,
                  child: LandingHeroSection(
                    entranceAnimation: _entranceAnimation,
                    onExploreTap: () => _scrollToSection(_solutionsKey),
                    onLiveDemoTap: () => _scrollToSection(_howItWorksKey),
                  ),
                ),

                // 2. Measurable Impact Statistics
                const LandingStatsSection(),

                // 3. About & Vision Section
                Container(
                  key: _aboutKey,
                  child: const LandingAboutSection(),
                ),

                // 4. Solutions Suite (4 Modular Cards)
                Container(
                  key: _solutionsKey,
                  child: const LandingSolutionsSection(),
                ),

                // 5. Benefits & Outcomes
                Container(
                  key: _benefitsKey,
                  child: const LandingBenefitsSection(),
                ),

                // 6. How It Works (3-Step Pipeline)
                Container(
                  key: _howItWorksKey,
                  child: const LandingHowItWorksSection(),
                ),

                // 7. Technology & Edge Architecture
                const LandingCapabilitiesSection(),

                // 8. Trust, Certifications & Testimonials
                Container(
                  key: _trustKey,
                  child: const LandingTrustSection(),
                ),

                // 9. High-Impact Call to Action Banner
                Container(
                  key: _contactKey,
                  child: const LandingCtaBanner(),
                ),

                // 10. Complete Brand Footer
                LandingFooter(
                  onBackToTop: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                ),
              ],
            ),
          ),

          // Floating Sticky Agronex Pill Navbar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LandingNavbar(
              isScrolled: _isScrolled,
              onHomeTap: () => _scrollToSection(_homeKey),
              onAboutTap: () => _scrollToSection(_aboutKey),
              onSolutionsTap: () => _scrollToSection(_solutionsKey),
              onBenefitsTap: () => _scrollToSection(_benefitsKey),
              onHowItWorksTap: () => _scrollToSection(_howItWorksKey),
              onTrustTap: () => _scrollToSection(_trustKey),
              onContactTap: () => _scrollToSection(_contactKey),
            ),
          ),
        ],
      ),
    );
  }
}
