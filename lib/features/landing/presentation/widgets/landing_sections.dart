import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_design.dart';

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE PROFESSIONAL LIGHT THEME COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

/// High-Contrast Light Theme Pill Badge
class AgronexBadge extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color backgroundColor;
  final Color textColor;
  final Color? borderColor;

  const AgronexBadge({
    super.key,
    required this.text,
    this.icon,
    this.backgroundColor = const Color(0xFFF0FDF4),
    this.textColor = const Color(0xFF166534),
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppDesign.radiusPill),
        border: Border.all(
          color: borderColor ?? const Color(0xFFBBF7D0),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Clean White Enterprise Hover Card
class AgronexHoverCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double borderRadius;
  final Color? backgroundColor;
  final Border? border;
  final List<BoxShadow>? shadows;
  final EdgeInsetsGeometry padding;

  const AgronexHoverCard({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = AppDesign.radiusLg,
    this.backgroundColor,
    this.border,
    this.shadows,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<AgronexHoverCard> createState() => _AgronexHoverCardState();
}

class _AgronexHoverCardState extends State<AgronexHoverCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final bool disableAnimations = MediaQuery.of(context).disableAnimations;

    return MouseRegion(
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(0, (_isHovered && !disableAnimations) ? -5 : 0, 0),
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? Colors.white,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: _isHovered
                ? Border.all(color: const Color(0xFF166534), width: 1.5)
                : (widget.border ?? Border.all(color: const Color(0xFFE2E8F0), width: 1.0)),
            boxShadow: _isHovered
                ? [
                    const BoxShadow(
                      color: Color(0x18166534),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                    const BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : (widget.shadows ??
                    const [
                      BoxShadow(
                        color: Color(0x06000000),
                        blurRadius: 12,
                        offset: Offset(0, 3),
                      ),
                    ]),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Accessible Image with Clean Skeleton Loader
class AgronexImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final String altText;

  const AgronexImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = AppDesign.radiusMd,
    required this.altText,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: altText,
      image: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: const Color(0xFFF1F5F9),
              child: const Center(
                child: SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF166534)),
                  ),
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.health_and_safety_rounded, color: Color(0xFF166534), size: 36),
                  const SizedBox(height: 8),
                  Text(
                    altText,
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. FLOATING CLEAN LIGHT NAVBAR
// ─────────────────────────────────────────────────────────────────────────────

class LandingNavbar extends StatefulWidget {
  final VoidCallback onHomeTap;
  final VoidCallback onAboutTap;
  final VoidCallback onSolutionsTap;
  final VoidCallback onBenefitsTap;
  final VoidCallback onHowItWorksTap;
  final VoidCallback onTrustTap;
  final VoidCallback onContactTap;
  final bool isScrolled;

  const LandingNavbar({
    super.key,
    required this.onHomeTap,
    required this.onAboutTap,
    required this.onSolutionsTap,
    required this.onBenefitsTap,
    required this.onHowItWorksTap,
    required this.onTrustTap,
    required this.onContactTap,
    required this.isScrolled,
  });

  @override
  State<LandingNavbar> createState() => _LandingNavbarState();
}

class _LandingNavbarState extends State<LandingNavbar> {
  bool _mobileMenuOpen = false;

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1080;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 24.0 : 16.0,
        vertical: 12.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1320),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 22.0 : 16.0,
              vertical: isDesktop ? 12.0 : 10.0,
            ),
            decoration: BoxDecoration(
              color: widget.isScrolled
                  ? const Color(0xF7FFFFFF)
                  : const Color(0xFFFFFFFF),
              borderRadius: BorderRadius.circular(AppDesign.radiusPill),
              border: Border.all(
                color: widget.isScrolled
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: widget.isScrolled ? 0.08 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Brand Logo
                    InkWell(
                      onTap: widget.onHomeTap,
                      borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534),
                              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.health_and_safety_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'FLOCKSENSE',
                                style: GoogleFonts.inter(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Livestock Health & Outbreak Surveillance',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                  color: const Color(0xFF166534),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Desktop Navigation Links
                    if (isDesktop) ...[
                      Flexible(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _NavLink(label: 'Home', onTap: widget.onHomeTap),
                              _NavLink(label: 'About', onTap: widget.onAboutTap),
                              _NavLink(label: 'Solutions', onTap: widget.onSolutionsTap),
                              _NavLink(label: 'Benefits', onTap: widget.onBenefitsTap),
                              _NavLink(label: 'How It Works', onTap: widget.onHowItWorksTap),
                              _NavLink(label: 'Trust', onTap: widget.onTrustTap),
                              _NavLink(label: 'Contact', onTap: widget.onContactTap),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Call to action button
                      InkWell(
                        onTap: () => Navigator.pushNamed(context, AppRoutes.main),
                        borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF166534),
                            borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x2E166534),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Launch Platform',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Mobile Hamburger Button
                      IconButton(
                        icon: Icon(
                          _mobileMenuOpen ? Icons.close_rounded : Icons.menu_rounded,
                          color: const Color(0xFF0F172A),
                          size: 26,
                        ),
                        onPressed: () => setState(() => _mobileMenuOpen = !_mobileMenuOpen),
                      ),
                    ],
                  ],
                ),

                // Mobile Dropdown Menu
                if (!isDesktop && _mobileMenuOpen) ...[
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _MobileNavLink(label: 'Home', onTap: () { widget.onHomeTap(); setState(() => _mobileMenuOpen = false); }),
                      _MobileNavLink(label: 'About', onTap: () { widget.onAboutTap(); setState(() => _mobileMenuOpen = false); }),
                      _MobileNavLink(label: 'Solutions', onTap: () { widget.onSolutionsTap(); setState(() => _mobileMenuOpen = false); }),
                      _MobileNavLink(label: 'Benefits', onTap: () { widget.onBenefitsTap(); setState(() => _mobileMenuOpen = false); }),
                      _MobileNavLink(label: 'How It Works', onTap: () { widget.onHowItWorksTap(); setState(() => _mobileMenuOpen = false); }),
                      _MobileNavLink(label: 'Trust', onTap: () { widget.onTrustTap(); setState(() => _mobileMenuOpen = false); }),
                      _MobileNavLink(label: 'Contact', onTap: () { widget.onContactTap(); setState(() => _mobileMenuOpen = false); }),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF166534),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        setState(() => _mobileMenuOpen = false);
                        Navigator.pushNamed(context, AppRoutes.main);
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: Text(
                        'Launch Platform',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink({required this.label, required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: _isHovered ? FontWeight.w700 : FontWeight.w500,
              color: _isHovered ? const Color(0xFF166534) : const Color(0xFF334155),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileNavLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _MobileNavLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesign.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(AppDesign.radiusPill),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 2. HERO SECTION (PROFESSIONAL LIGHT THEME + PROBLEM STATEMENT)
// ─────────────────────────────────────────────────────────────────────────────

class LandingHeroSection extends StatelessWidget {
  final Animation<double> entranceAnimation;
  final VoidCallback onExploreTap;
  final VoidCallback onLiveDemoTap;

  const LandingHeroSection({
    super.key,
    required this.entranceAnimation,
    required this.onExploreTap,
    required this.onLiveDemoTap,
  });

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1080;
    final bool isTablet = screenWidth >= 700 && screenWidth < 1080;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: isDesktop ? 40.0 : 20.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDesign.radiusXl),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0C0F172A),
                  blurRadius: 32,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 56.0 : (isTablet ? 36.0 : 20.0),
                vertical: isDesktop ? 60.0 : 36.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Problem Statement Badge
                  FadeTransition(
                    opacity: entranceAnimation,
                    child: const AgronexBadge(
                      text: 'SMART INDIA HACKATHON • SIH26128',
                      icon: Icons.shield_rounded,
                      backgroundColor: Color(0xFFF0FDF4),
                      textColor: Color(0xFF166534),
                      borderColor: Color(0xFFBBF7D0),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Headline: Exact Problem Statement Representation
                  FadeTransition(
                    opacity: entranceAnimation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.12),
                        end: Offset.zero,
                      ).animate(entranceAnimation),
                      child: Text(
                        'Efficient Systems for Early Detection, Prevention & Management of Livestock Diseases',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 48 : (isTablet ? 36 : 27),
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -1.0,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Problem-Focused Narrative Supporting Copy
                  FadeTransition(
                    opacity: entranceAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 820),
                      child: Text(
                        'A unified digital health intelligence platform connecting poultry & livestock farmers, field veterinarians, and state animal husbandry situation rooms. Detect syndromic anomalies 5–7 days before mortality spikes, enforce biosecurity cordons, and streamline clinical triage.',
                        style: GoogleFonts.inter(
                          fontSize: isDesktop ? 17.5 : 15,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Call to Action Buttons
                  FadeTransition(
                    opacity: entranceAnimation,
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Primary CTA Button
                        InkWell(
                          onTap: onExploreTap,
                          borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534),
                              borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33166534),
                                  blurRadius: 16,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Explore Surveillance Suite',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_downward_rounded,
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Secondary CTA Button
                        InkWell(
                          onTap: onLiveDemoTap,
                          borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                              border: Border.all(color: const Color(0xFF15803D), width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.biotech_rounded,
                                  size: 18,
                                  color: Color(0xFF15803D),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Clinical Triage Engine',
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Direct Launch Shortcut
                        InkWell(
                          onTap: () => Navigator.pushNamed(context, AppRoutes.main),
                          borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Text(
                              'Open Live Prototype Console →',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF15803D),
                                decoration: TextDecoration.underline,
                                decorationColor: const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // High-Contrast Real-World Telemetry Ticker Strip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                      border: Border.all(color: const Color(0xFFDCFCE7)),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Wrap(
                          spacing: 24,
                          runSpacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 9,
                                  height: 9,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFF15803D),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Color(0xFF15803D),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'LIVE SHED TELEMETRY BUS',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            const _TelemetryPill(
                              icon: Icons.thermostat_rounded,
                              label: 'Shed Temp',
                              value: '26.8°C',
                            ),
                            const _TelemetryPill(
                              icon: Icons.water_drop_rounded,
                              label: 'Humidity',
                              value: '62.4%',
                            ),
                            const _TelemetryPill(
                              icon: Icons.air_rounded,
                              label: 'Ammonia (NH3)',
                              value: '11 ppm',
                            ),
                            const _TelemetryPill(
                              icon: Icons.trending_down_rounded,
                              label: 'Daily Mortality',
                              value: '0.12% (Normal)',
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TelemetryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TelemetryPill({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: const Color(0xFF166534)),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B)),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. STATS & IMPACT SECTION (LIVESTOCK SURVEILLANCE IMPACT)
// ─────────────────────────────────────────────────────────────────────────────

class LandingStatsSection extends StatelessWidget {
  const LandingStatsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;
    final bool isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 36.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const AgronexBadge(
                          text: 'MEASURABLE LIVESTOCK HEALTH IMPACT',
                          icon: Icons.analytics_rounded,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Early Disease Warning & Rapid Containment Outcomes',
                          style: GoogleFonts.inter(
                            fontSize: isDesktop ? 26 : 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDesktop) ...[
                    const SizedBox(width: 16),
                    Text(
                      '* Operational metrics validated in pilot poultry & cattle facilities [Placeholder]',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Responsive 4-Card Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop
                      ? (constraints.maxWidth - 48) / 4
                      : (isTablet
                          ? (constraints.maxWidth - 16) / 2
                          : constraints.maxWidth);

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _StatCard(
                        width: cardWidth,
                        metric: '-78%',
                        metricColor: const Color(0xFF15803D),
                        label: 'Reporting Lag Eliminated',
                        description: 'Replaces 5–12 day manual paper transmission with instant cloud telemetry. [Placeholder]',
                        tag: 'Detection Speed',
                      ),
                      _StatCard(
                        width: cardWidth,
                        metric: '99.4%',
                        metricColor: const Color(0xFF16A34A),
                        label: 'Pathogen Anomaly Accuracy',
                        description: 'Early warning triggered 5-7 days prior to catastrophic mortality spread. [Placeholder]',
                        tag: 'Prevention',
                      ),
                      _StatCard(
                        width: cardWidth,
                        metric: '3.8M+',
                        metricColor: const Color(0xFF166534),
                        label: 'Birds & Animals Protected',
                        description: 'Continuous syndromic coverage across sheds, hatcheries, and corrals. [Placeholder]',
                        tag: 'Capacity',
                      ),
                      _StatCard(
                        width: cardWidth,
                        metric: '< 15 min',
                        metricColor: const Color(0xFF15803D),
                        label: 'Emergency Triage Dispatch',
                        description: 'Automated GPS cordon notification to veterinarians and situation room. [Placeholder]',
                        tag: 'Containment',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final String metric;
  final Color metricColor;
  final String label;
  final String description;
  final String tag;

  const _StatCard({
    required this.width,
    required this.metric,
    required this.metricColor,
    required this.label,
    required this.description,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AgronexHoverCard(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    tag.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15803D),
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
                Icon(Icons.health_and_safety_outlined, color: metricColor, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              metric,
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: metricColor,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                height: 1.5,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 4. ABOUT / MISSION (EARLY DETECTION & PREVENTION CORE)
// ─────────────────────────────────────────────────────────────────────────────

class LandingAboutSection extends StatelessWidget {
  const LandingAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 40.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Container(
            padding: EdgeInsets.all(isDesktop ? 48.0 : 24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDesign.radiusXl),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x080F172A),
                  blurRadius: 24,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 5, child: _buildAboutText(context)),
                      const SizedBox(width: 48),
                      Expanded(flex: 5, child: _buildAboutVisuals()),
                    ],
                  )
                : Column(
                    children: [
                      _buildAboutText(context),
                      const SizedBox(height: 36),
                      _buildAboutVisuals(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutText(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AgronexBadge(
          text: 'SIH PROBLEM STATEMENT ARCHITECTURE',
          icon: Icons.crisis_alert_rounded,
        ),
        const SizedBox(height: 16),
        Text(
          'Closing the Critical 5–12 Day Epidemic Reporting Void in Livestock Farming',
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1.2,
            color: const Color(0xFF0F172A),
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Traditional livestock mortality surveillance depends on paper registers and verbal logs, allowing highly infectious pathogens like Avian Influenza, Newcastle Disease, and Foot-and-Mouth Disease to propagate unchecked across sheds and corridors.',
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.65,
            color: const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'FlockSense replaces delay with instant syndromic intelligence: combining daily telemetry deviations, environmental stress metrics (THI), and automated GIS quarantine cordon mapping.',
          style: GoogleFonts.inter(
            fontSize: 14,
            height: 1.6,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 28),

        // Three Core Pillars of the Problem Statement
        const _PillarItem(
          icon: Icons.radar_rounded,
          title: 'Early Detection (IoT & Baselines)',
          subtitle: 'Continuous comparison of water intake, feed consumption, and thermal stress against 7-day rolling baselines.',
        ),
        const SizedBox(height: 14),
        const _PillarItem(
          icon: Icons.fence_rounded,
          title: 'Prevention (Biosecurity & Quarantine)',
          subtitle: 'Automated 3km containment circles and 10km buffer cordons around detected viral clusters.',
        ),
        const SizedBox(height: 14),
        const _PillarItem(
          icon: Icons.hub_rounded,
          title: 'Management (Tri-Tier Coordination)',
          subtitle: 'Instant clinical triage handoffs between Farmers, Field Veterinarians, and State Situation Rooms.',
        ),
      ],
    );
  }

  Widget _buildAboutVisuals() {
    return Column(
      children: [
        // Main Poultry & Livestock Healthcare Image
        Stack(
          children: [
            const AgronexImage(
              imageUrl: 'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?auto=format&fit=crop&w=1200&q=80',
              height: 300,
              width: double.infinity,
              borderRadius: AppDesign.radiusLg,
              altText: 'Modern bio-secured livestock facility with IoT environmental sensors',
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Bio-security compliance score: 96% Optimal across monitored sheds [Demonstration Benchmark]',
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Dual Sub-Cards (Veterinary & Outbreak GIS Map)
        Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  const AgronexImage(
                    imageUrl: 'https://images.unsplash.com/photo-1576091160550-2173dba999ef?auto=format&fit=crop&w=600&q=80',
                    height: 140,
                    width: double.infinity,
                    borderRadius: AppDesign.radiusMd,
                    altText: 'Veterinarian conducting clinical diagnostics and swab sample preparation',
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'Clinical Triage',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF166534), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Stack(
                children: [
                  const AgronexImage(
                    imageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=600&q=80',
                    height: 140,
                    width: double.infinity,
                    borderRadius: AppDesign.radiusMd,
                    altText: 'GIS map coordinates and geospatial containment rings',
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        'GIS Situation Room',
                        style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF166534), fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillarItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PillarItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Icon(icon, color: const Color(0xFF166534), size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  height: 1.45,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 5. SOLUTIONS & SERVICES (EARLY DETECTION, PREVENTION, MANAGEMENT)
// ─────────────────────────────────────────────────────────────────────────────

class LandingSolutionsSection extends StatelessWidget {
  const LandingSolutionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 40.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AgronexBadge(
                text: 'CORE SURVEILLANCE MODULES',
                icon: Icons.medical_services_rounded,
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      'End-to-End Livestock Disease Prevention Architecture',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 30 : 22,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -0.6,
                      ),
                    ),
                  ),
                  if (isDesktop)
                    Text(
                      'Connecting Farmers, Field Clinicians, and State Health Directors',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                ],
              ),
              const SizedBox(height: 28),

              // 4 Detailed Livestock Health Solution Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop
                      ? (constraints.maxWidth - 24) / 2
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _SolutionCard(
                        width: cardWidth,
                        imageUrl: 'https://images.unsplash.com/photo-1548550023-2bdb3c5beed7?auto=format&fit=crop&w=800&q=80',
                        badge: 'EARLY DETECTION',
                        title: 'Real-Time IoT Shed Telemetry & Baselines',
                        description: 'Continuous monitoring of temperature, humidity, ammonia (NH3), and CO2, coupled with daily mortality deviations against 7-day rolling baselines.',
                        features: const [
                          'Automated intake drop alerts (feed & water consumption deficit)',
                          'Thermal Humidity Index (THI) heat stress predictive index',
                          'Multi-shed facility switcher with instant biometric risk rating',
                        ],
                        altText: 'Clean modern poultry facility equipped with IoT environmental sensors',
                      ),
                      _SolutionCard(
                        width: cardWidth,
                        imageUrl: 'https://images.unsplash.com/photo-1584515979956-d9f6e5d09982?auto=format&fit=crop&w=800&q=80',
                        badge: 'SYNDROMIC PREDICTION',
                        title: 'AI Symptom Checklist & Pathogen Classifier',
                        description: 'Field symptom logging across respiratory, digestive, and neurological categories. AI differential diagnostic engine ranks potential pathogens.',
                        features: const [
                          'Avian Influenza, Newcastle, and Infectious Bronchitis probability scoring',
                          'Lab swab chain of custody (RT-PCR and viral isolation tracking)',
                          'Prophylactic prescription log with active withdrawal period compliance',
                        ],
                        altText: 'Veterinary specialist conducting diagnostic analysis with laboratory swab kit',
                      ),
                      _SolutionCard(
                        width: cardWidth,
                        imageUrl: 'https://images.unsplash.com/photo-1524661135-423995f22d0b?auto=format&fit=crop&w=800&q=80',
                        badge: 'EPIDEMIC PREVENTION',
                        title: 'GIS Outbreak Mapping & Quarantine Cordons',
                        description: 'Geospatial situation room tracking confirmed outbreaks with dynamic 3km Red Containment Zones and 10km Yellow Quarantine Buffer Rings.',
                        features: const [
                          'Interactive Esri satellite, OpenStreetMap, and Dark tile layers',
                          'Nearby corridor exposure: alerts farms within 10 km of active clusters',
                          'One-click sanitized vehicle & visitor access logging at farm gates',
                        ],
                        altText: 'Interactive GIS mapping interface displaying outbreak clusters and quarantine zones',
                      ),
                      _SolutionCard(
                        width: cardWidth,
                        imageUrl: 'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=800&q=80',
                        badge: 'REGULATORY MANAGEMENT',
                        title: 'State Situation Room & Sanitary Export Engine',
                        description: 'District-wide velocity rankings identify high-risk epicenters. Generates official DAHD and WOAH-compliant sanitary bulletins in PDF & CSV.',
                        features: const [
                          'Priority-1 emergency queue for immediate veterinary dispatch',
                          'District vulnerability velocity rankings and resource allocation',
                          'Official epidemiological export bulletins ready for DAHD submission',
                        ],
                        altText: 'Official situation room console reviewing epidemiological situation and sanitary reports',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolutionCard extends StatelessWidget {
  final double width;
  final String imageUrl;
  final String badge;
  final String title;
  final String description;
  final List<String> features;
  final String altText;

  const _SolutionCard({
    required this.width,
    required this.imageUrl,
    required this.badge,
    required this.title,
    required this.description,
    required this.features,
    required this.altText,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AgronexHoverCard(
        borderRadius: AppDesign.radiusLg,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Header with Badge
            Stack(
              children: [
                AgronexImage(
                  imageUrl: imageUrl,
                  height: 200,
                  width: double.infinity,
                  borderRadius: AppDesign.radiusLg,
                  altText: altText,
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                      boxShadow: const [
                        BoxShadow(color: Color(0x10000000), blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.inter(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: const Color(0xFF166534),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Card Body
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      height: 1.55,
                      color: const Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: Color(0xFFE2E8F0), height: 1),
                  const SizedBox(height: 16),

                  // Feature Bullet Points
                  ...features.map((feature) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: Color(0xFF15803D),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature,
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 6. BENEFITS SECTION (MEASURABLE ANIMAL HEALTH OUTCOMES)
// ─────────────────────────────────────────────────────────────────────────────

class LandingBenefitsSection extends StatelessWidget {
  const LandingBenefitsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      color: const Color(0xFFF0FDF4),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 44.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AgronexBadge(
                text: 'SYSTEM OUTCOMES & BIOSECURITY GAINS',
                icon: Icons.verified_rounded,
              ),
              const SizedBox(height: 12),
              Text(
                'Built for Scalable Disease Containment & Farmer Protection',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 30 : 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Direct economic and epidemiological advantages validated for commercial livestock production.',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF475569)),
              ),
              const SizedBox(height: 32),

              // Benefits Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _BenefitCard(
                        width: cardWidth,
                        icon: Icons.trending_down_rounded,
                        title: 'Drastic Mortality Containment',
                        percent: '-65%',
                        description: 'Early isolation of sick birds or livestock halts pathogen replication before shed-wide mortality cascades. [Placeholder]',
                      ),
                      _BenefitCard(
                        width: cardWidth,
                        icon: Icons.speed_rounded,
                        title: 'Zero Reporting Lag',
                        percent: 'Real-time',
                        description: 'Direct digital bridge replaces 5–12 day delays between farm death logs and veterinary dispatch. [Placeholder]',
                      ),
                      _BenefitCard(
                        width: cardWidth,
                        icon: Icons.fence_rounded,
                        title: 'Biosecurity Breach Prevention',
                        percent: '98.5%',
                        description: 'Gate visitor audits and disinfectant logs ensure rigid farm bio-exclusion compliance. [Placeholder]',
                      ),
                      _BenefitCard(
                        width: cardWidth,
                        icon: Icons.medication_liquid_rounded,
                        title: 'Prudent Antimicrobial Use',
                        percent: '-40%',
                        description: 'Targeted differential diagnosis reduces blanket antibiotic misuse and ensures withdrawal compliance. [Placeholder]',
                      ),
                      _BenefitCard(
                        width: cardWidth,
                        icon: Icons.document_scanner_rounded,
                        title: 'Instant DAHD Export Bulletins',
                        percent: '100%',
                        description: 'Export health certificates and district summaries ready for animal health authority audits. [Placeholder]',
                      ),
                      _BenefitCard(
                        width: cardWidth,
                        icon: Icons.savings_rounded,
                        title: 'Operational Cost Preservation',
                        percent: '+28% ROI',
                        description: 'Preventing a single shed cull covers the operational telemetry investment for multi-year operations. [Placeholder]',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String title;
  final String percent;
  final String description;

  const _BenefitCard({
    required this.width,
    required this.icon,
    required this.title,
    required this.percent,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AgronexHoverCard(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  ),
                  child: Icon(icon, color: const Color(0xFF15803D), size: 22),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Text(
                    percent,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF15803D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7. HOW IT WORKS (3-STEP PIPELINE: DETECT, PREVENT, MANAGE)
// ─────────────────────────────────────────────────────────────────────────────

class LandingHowItWorksSection extends StatelessWidget {
  const LandingHowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 44.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AgronexBadge(
                text: 'TRI-TIER SURVEILLANCE PIPELINE',
                icon: Icons.alt_route_rounded,
              ),
              const SizedBox(height: 12),
              Text(
                'How the Early Detection & Outbreak Pipeline Works',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 30 : 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'From daily shed telemetry ingestion to emergency veterinary containment in three clear phases.',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 36),

              // 3-Step Row
              isDesktop
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _StepCard(
                            stepNumber: '01',
                            title: 'Step 1: Early Detection (Telemetry)',
                            description: 'Farmers log daily mortality, feed, and water consumption. IoT sensors stream temperature, humidity, and ammonia. Anomaly models detect sub-clinical deviations.',
                            icon: Icons.sensors_rounded,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _StepCard(
                            stepNumber: '02',
                            title: 'Step 2: Prevention (Biosecurity)',
                            description: 'Automated 3km Red Containment perimeters and 10km Yellow Buffer rings trigger instantly on GIS maps. Gate visitor logs lock down vulnerable corridors.',
                            icon: Icons.security_rounded,
                          ),
                        ),
                        SizedBox(width: 24),
                        Expanded(
                          child: _StepCard(
                            stepNumber: '03',
                            title: 'Step 3: Management (Triage & State)',
                            description: 'Veterinarians triage priority cases with differential diagnosis checklists and RT-PCR tracking. State situation room exports compliant DAHD bulletins.',
                            icon: Icons.assignment_turned_in_rounded,
                          ),
                        ),
                      ],
                    )
                  : const Column(
                      children: [
                        _StepCard(
                          stepNumber: '01',
                          title: 'Step 1: Early Detection (Telemetry)',
                          description: 'Farmers log daily mortality, feed, and water consumption. IoT sensors stream temperature, humidity, and ammonia. Anomaly models detect sub-clinical deviations.',
                          icon: Icons.sensors_rounded,
                        ),
                        SizedBox(height: 16),
                        _StepCard(
                          stepNumber: '02',
                          title: 'Step 2: Prevention (Biosecurity)',
                          description: 'Automated 3km Red Containment perimeters and 10km Yellow Buffer rings trigger instantly on GIS maps. Gate visitor logs lock down vulnerable corridors.',
                          icon: Icons.security_rounded,
                        ),
                        SizedBox(height: 16),
                        _StepCard(
                          stepNumber: '03',
                          title: 'Step 3: Management (Triage & State)',
                          description: 'Veterinarians triage priority cases with differential diagnosis checklists and RT-PCR tracking. State situation room exports compliant DAHD bulletins.',
                          icon: Icons.assignment_turned_in_rounded,
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final String stepNumber;
  final String title;
  final String description;
  final IconData icon;

  const _StepCard({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return AgronexHoverCard(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepNumber,
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF166534),
                  letterSpacing: -1,
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                ),
                child: Icon(icon, color: const Color(0xFF166534), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16.5,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              height: 1.55,
              color: const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 8. TECHNOLOGY & ARCHITECTURE SECTION
// ─────────────────────────────────────────────────────────────────────────────

class LandingCapabilitiesSection extends StatelessWidget {
  const LandingCapabilitiesSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 44.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AgronexBadge(
                text: 'HEALTHCARE IT INFRASTRUCTURE',
                icon: Icons.hub_rounded,
              ),
              const SizedBox(height: 12),
              Text(
                'Enterprise Telemetry & Veterinary Field Resilience',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 30 : 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Engineered to operate reliably across rural poultry sheds with intermittent connectivity.',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 32),

              // Capabilities Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _TechPill(
                        width: cardWidth,
                        title: 'Interactive Real Tile GIS',
                        subtitle: 'Satellite, OpenStreetMap, and Dark Matter views with dynamic meter-accurate 3km and 10km outbreak buffer rings.',
                        icon: Icons.map_rounded,
                      ),
                      _TechPill(
                        width: cardWidth,
                        title: 'Offline-First Hive Storage',
                        subtitle: 'Full local data persistence ensures uninterrupted mortality and symptom recording during network outages.',
                        icon: Icons.cloud_off_rounded,
                      ),
                      _TechPill(
                        width: cardWidth,
                        title: 'Tri-Tier Role Coordination',
                        subtitle: 'Distinct tailored consoles for Poultry Farmers, Field Veterinarians, and State Animal Husbandry Officers.',
                        icon: Icons.group_work_rounded,
                      ),
                      _TechPill(
                        width: cardWidth,
                        title: 'Thermal Humidity Index (THI)',
                        subtitle: 'Calculates heat and ventilation stress indicators that predispose birds to secondary respiratory infections.',
                        icon: Icons.thermostat_auto_rounded,
                      ),
                      _TechPill(
                        width: cardWidth,
                        title: 'Lab RT-PCR Chain of Custody',
                        subtitle: 'Tracking swab diagnostic samples from on-farm collection through accredited state reference laboratories.',
                        icon: Icons.science_rounded,
                      ),
                      _TechPill(
                        width: cardWidth,
                        title: 'DAHD / WOAH Sanitary Bulletins',
                        subtitle: 'One-click generation of exportable PDF and CSV epidemiological bulletins formatted to official standards.',
                        icon: Icons.picture_as_pdf_rounded,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TechPill extends StatelessWidget {
  final double width;
  final String title;
  final String subtitle;
  final IconData icon;

  const _TechPill({
    required this.width,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(22.0),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(AppDesign.radiusLg),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: Icon(icon, color: const Color(0xFF166534), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      height: 1.45,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 9. TRUST, CERTIFICATIONS & TESTIMONIALS
// ─────────────────────────────────────────────────────────────────────────────

class LandingTrustSection extends StatelessWidget {
  const LandingTrustSection({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 44.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AgronexBadge(
                text: 'ACCREDITATION & FIELD VALIDATION',
                icon: Icons.verified_user_rounded,
              ),
              const SizedBox(height: 12),
              Text(
                'Trusted by Veterinarians, Farmers & Regulators',
                style: GoogleFonts.inter(
                  fontSize: isDesktop ? 30 : 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF0F172A),
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Proven in regional field trials across poultry sheds and veterinary districts.',
                style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
              ),
              const SizedBox(height: 28),

              // Trust Badges Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: const Wrap(
                  spacing: 24,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  alignment: WrapAlignment.spaceAround,
                  children: [
                    _TrustBadgeItem(icon: Icons.verified_rounded, text: 'SIH Finalist [SIH26128 Prototype]'),
                    _TrustBadgeItem(icon: Icons.health_and_safety_rounded, text: 'DAHD Guidelines Aligned [Placeholder]'),
                    _TrustBadgeItem(icon: Icons.biotech_rounded, text: 'WOAH Sanitary Compliant [Placeholder]'),
                    _TrustBadgeItem(icon: Icons.shield_rounded, text: 'ISO 27001 Data Security [Placeholder]'),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 3 Testimonial Cards
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = isDesktop
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      _TestimonialCard(
                        width: cardWidth,
                        quote: '"The syndromic anomaly alert detected respiratory stress in Shed 3 before morning feed. We quarantined the flock in under 20 minutes, stopping a major outbreak."',
                        author: 'Ramesh Patil [Placeholder]',
                        role: 'Poultry Farm Operator [Placeholder]',
                        location: 'Nashik District, Maharashtra',
                      ),
                      _TestimonialCard(
                        width: cardWidth,
                        quote: '"The clinical triage queue and differential diagnostic scoring allow our veterinary hospital to prioritize critical sheds and deploy swabs without delay."',
                        author: 'Dr. Priya Deshmukh [Placeholder]',
                        role: 'District Veterinary Officer [Placeholder]',
                        location: 'Pune Animal Husbandry Dept.',
                      ),
                      _TestimonialCard(
                        width: cardWidth,
                        quote: '"The interactive GIS map with 3km containment and 10km buffer rings gives our state situation room immediate clarity during seasonal bird flu alerts."',
                        author: 'Anil Kulkarni [Placeholder]',
                        role: 'Regional Biosecurity Director [Placeholder]',
                        location: 'State Command Center',
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadgeItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _TrustBadgeItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF15803D)),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF14532D),
          ),
        ),
      ],
    );
  }
}

class _TestimonialCard extends StatelessWidget {
  final double width;
  final String quote;
  final String author;
  final String role;
  final String location;

  const _TestimonialCard({
    required this.width,
    required this.quote,
    required this.author,
    required this.role,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AgronexHoverCard(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                Row(
                  children: List.generate(
                    5,
                    (index) => const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  quote,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 18),
                const Divider(color: Color(0xFFE2E8F0), height: 1),
                const SizedBox(height: 12),
                Text(
                  author,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  role,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF166534),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 10. FINAL CALL TO ACTION BANNER (HIGH-CONTRAST ENTERPRISE LIGHT)
// ─────────────────────────────────────────────────────────────────────────────

class LandingCtaBanner extends StatefulWidget {
  const LandingCtaBanner({super.key});

  @override
  State<LandingCtaBanner> createState() => _LandingCtaBannerState();
}

class _LandingCtaBannerState extends State<LandingCtaBanner> {
  final _emailController = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_emailController.text.trim().isNotEmpty) {
      setState(() => _submitted = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32.0 : 16.0,
        vertical: 40.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppDesign.radiusXl),
              border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1815803D),
                  blurRadius: 36,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 56.0 : 24.0,
                vertical: isDesktop ? 56.0 : 36.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AgronexBadge(
                    text: 'DEPLOY DISEASE SURVEILLANCE',
                    icon: Icons.health_and_safety_rounded,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Ready to Implement Early Disease Detection in Your Facilities?',
                    style: GoogleFonts.inter(
                      fontSize: isDesktop ? 34 : 24,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F172A),
                      letterSpacing: -0.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      'Equip your farm, veterinary district, or state situation room with real-time biometric telemetry, automated quarantine maps, and official sanitary reporting.',
                      style: GoogleFonts.inter(
                        fontSize: isDesktop ? 15.5 : 14,
                        height: 1.6,
                        color: const Color(0xFF475569),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Interactive Form or Submission Confirmation
                  if (_submitted) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                        border: Border.all(color: const Color(0xFF15803D)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Thank you! A veterinary surveillance coordinator will connect shortly. [Demonstration Sample]',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              style: GoogleFonts.inter(color: const Color(0xFF0F172A), fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Enter veterinary or farm email... [Placeholder]',
                                hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 13),
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                                  borderSide: const BorderSide(color: Color(0xFF15803D)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InkWell(
                            onTap: _handleSubmit,
                            borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF15803D),
                                borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                              ),
                              child: Text(
                                'Request Demo',
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Direct Console Link Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0FDF4),
                      foregroundColor: const Color(0xFF15803D),
                      elevation: 0,
                      side: const BorderSide(color: Color(0xFFBBF7D0), width: 1.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.main),
                    icon: const Icon(Icons.dashboard_customize_rounded, size: 18),
                    label: Text(
                      'Launch Live Prototype Situation Room Directly →',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 11. COMPLETE FOOTER
// ─────────────────────────────────────────────────────────────────────────────

class LandingFooter extends StatelessWidget {
  final VoidCallback onBackToTop;

  const LandingFooter({super.key, required this.onBackToTop});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth >= 1024;

    return Container(
      color: const Color(0xFF14532D),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 48.0 : 20.0,
        vertical: 48.0,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1360),
          child: Column(
            children: [
              // Top Footer Grid (Responsive)
              LayoutBuilder(
                builder: (context, constraints) {
                  final bool isWide = constraints.maxWidth >= 900;
                  final brandWidget = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF15803D),
                              borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.health_and_safety_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'FLOCKSENSE',
                            style: GoogleFonts.inter(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'AI-Powered Animal Health Intelligence, Early Disease Warning & Outbreak Containment System built for Smart India Hackathon (SIH26128).',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.6,
                          color: const Color(0xFFDCFCE7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Problem: Efficient systems for early detection, prevention, and management of livestock diseases',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF86EFAC),
                        ),
                      ),
                    ],
                  );

                  final columnsWidget = [
                    const _FooterColumn(
                      title: 'Surveillance Platform',
                      links: [
                        'Farmer Telemetry Dashboard',
                        'Veterinary Triage Queue',
                        'State Situation Room',
                        'GIS 3km & 10km Map',
                        'Offline Cache Sync',
                      ],
                    ),
                    const _FooterColumn(
                      title: 'Capabilities',
                      links: [
                        'Syndromic Anomaly AI',
                        'Thermal Humidity (THI)',
                        'Differential Diagnosis',
                        'RT-PCR Chain of Custody',
                        'DAHD Sanitary Export',
                      ],
                    ),
                    const _FooterColumn(
                      title: 'Contact [Placeholder]',
                      links: [
                        'surveillance@flocksense.in [Placeholder]',
                        '+91 1800-VET-ALERT [Placeholder]',
                        'Krishi Bhavan, New Delhi [Placeholder]',
                        'Privacy & Biosecurity [Placeholder]',
                        'Terms of Service [Placeholder]',
                      ],
                    ),
                  ];

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: brandWidget),
                        const SizedBox(width: 36),
                        Expanded(
                          flex: 7,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: columnsWidget[0]),
                              const SizedBox(width: 16),
                              Expanded(child: columnsWidget[1]),
                              const SizedBox(width: 16),
                              Expanded(child: columnsWidget[2]),
                            ],
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        brandWidget,
                        const SizedBox(height: 32),
                        Wrap(
                          spacing: 36,
                          runSpacing: 24,
                          children: columnsWidget,
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 44),
              const Divider(color: Color(0xFF166534), height: 1),
              const SizedBox(height: 20),

              // Bottom Row (Copyright & Back to top)
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  Text(
                    '© 2026 FlockSense Animal Health Intelligence. SIH26128 Prototype.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFFBBF7D0),
                    ),
                  ),
                  InkWell(
                    onTap: onBackToTop,
                    borderRadius: BorderRadius.circular(AppDesign.radiusPill),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Back to Top',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF86EFAC),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_upward_rounded,
                            size: 14,
                            color: Color(0xFF86EFAC),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterColumn extends StatelessWidget {
  final String title;
  final List<String> links;

  const _FooterColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 14),
        ...links.map((link) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Text(
                link,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFFDCFCE7),
                ),
              ),
            )),
      ],
    );
  }
}
