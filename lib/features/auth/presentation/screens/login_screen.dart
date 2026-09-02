import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/features/auth/data/auth_service.dart';

import 'package:flock_sense/features/main_shell/presentation/screens/main_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _googleLoading = false;
  bool _showPass = false;
  String? _error;
  String _selectedRole = 'Farmer';

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _email.text.trim();
    final password = _pass.text.trim();

    // 1. Instant access for demo credentials
    if (email.contains('flocksense') || email.contains('dahd.nic.in') || email == 'farmer@flocksense.in' || email.contains('vet')) {
      try {
        await FirebaseAuth.instance.signInAnonymously().timeout(const Duration(milliseconds: 600));
      } catch (_) {}
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainShellScreen(initialRole: _selectedRole),
        ),
        (_) => false,
      );
      return;
    }

    try {
      await AuthService.login(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => MainShellScreen(initialRole: _selectedRole),
        ),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      // In case Firebase email auth is disabled in the project console during demo
      if (e.code == 'operation-not-allowed') {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => MainShellScreen(initialRole: _selectedRole),
          ),
          (_) => false,
        );
        return;
      }
      setState(() => _error = AuthService.mapAuthException(e));
    } catch (_) {
      setState(() => _error = 'Invalid credentials or network issue.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fillDemo(String role) async {
    setState(() {
      _selectedRole = role;
      if (role == 'Farmer') {
        _email.text = 'farmer@flocksense.in';
        _pass.text = 'password123';
      } else if (role == 'Veterinarian') {
        _email.text = 'vet@flocksense.gov.in';
        _pass.text = 'password123';
      } else {
        _email.text = 'officer@dahd.nic.in';
        _pass.text = 'password123';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // ── Left Hero Panel (Enterprise Branding & Mission) ───────────────
          Expanded(
            flex: 5,
            child: Container(
              color: AppColors.slate900,
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 48),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Brand Header
                  Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                        ),
                        child: const Icon(
                          Icons.shield_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'FlockSense',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),

                  // Hero Core Pitch
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusFull),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: const Text(
                            'SIH26128 • LIVESTOCK DISEASE SURVEILLANCE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryLight,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'AI-Powered Animal Health Intelligence & Early Warning Platform',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.25,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Real-time flock telemetry, early disease anomaly detection, and rapid coordination between poultry farmers, field veterinarians, and government health authorities.',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.slate300,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // 3 Key Feature Bullets
                        _buildFeaturePill(
                          Icons.sensors_outlined,
                          'Early Outbreak Detection',
                          'Automated mortality spike and symptom classification algorithms.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeaturePill(
                          Icons.medical_services_outlined,
                          'Clinical Veterinary Triage',
                          'Direct tele-consultations, prescription tracking, and lab diagnostics.',
                        ),
                        const SizedBox(height: 16),
                        _buildFeaturePill(
                          Icons.map_outlined,
                          'Government GIS Surveillance',
                          'District-level bio-security alerts and quarantine enforcement.',
                        ),
                      ],
                    ),
                  ),

                  // Bottom Footer
                  const Text(
                    '© 2026 FlockSense Surveillance System. Secured with Firebase Cloud Architecture.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right Auth Form Panel ──────────────────────────────────────────
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(
                        'Sign in to your account',
                        style: AppTypography.pageTitle.copyWith(fontSize: 24),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Select your operational role and enter your credentials to continue.',
                        style: AppTypography.pageSubtitle,
                      ),
                      const SizedBox(height: 24),

                      // ── NEW: Untitled UI Prototype Instant Launcher Banner ──────────
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.primarySoft,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(color: AppColors.healthyBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.healthy,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'NEW TEMPLATE',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Untitled UI Clean SaaS Prototype',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Explore the live dashboard with growth curves, 4-card metric strip, IoT sensor fleet, and BentoGlow AI telemetry.',
                              style: TextStyle(fontSize: 12, color: AppColors.slate700),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.rocket_launch_rounded, size: 16),
                                label: const Text('Launch Farmer Prototype Now →', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                onPressed: () async {
                                  try {
                                    await FirebaseAuth.instance.signInAnonymously();
                                  } catch (_) {}
                                  if (!mounted) return;
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const MainShellScreen(initialRole: 'Farmer'),
                                    ),
                                    (_) => false,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Role Selector Tabs
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(
                          children: [
                            _buildRoleTab('Farmer', Icons.agriculture_outlined),
                            _buildRoleTab('Veterinarian', Icons.medical_services_outlined),
                            _buildRoleTab('Government', Icons.policy_outlined),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Error Banner
                      if (_error != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.criticalBg,
                            borderRadius:
                                BorderRadius.circular(AppDesign.radiusMd),
                            border: Border.all(
                                color: AppColors.criticalBorder, width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.critical, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.critical,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Email Address',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.slate800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: 'name@farm-or-gov.in',
                                prefixIcon: Icon(Icons.email_outlined,
                                    size: 18, color: AppColors.slate400),
                              ),
                              validator: (v) => (v == null || !v.contains('@'))
                                  ? 'Enter a valid email address'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Password',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate800,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pushNamed(
                                      context, AppRoutes.forgotPassword),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    'Forgot password?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _pass,
                              obscureText: !_showPass,
                              style: const TextStyle(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: '••••••••',
                                prefixIcon: const Icon(Icons.lock_outline_rounded,
                                    size: 18, color: AppColors.slate400),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPass
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    size: 18,
                                    color: AppColors.slate400,
                                  ),
                                  onPressed: () =>
                                      setState(() => _showPass = !_showPass),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 6)
                                  ? 'Password must be at least 6 characters'
                                  : null,
                            ),
                            const SizedBox(height: 24),

                            // Submit Button
                            AppButton(
                              label: 'Sign In to Portal',
                              width: double.infinity,
                              size: AppButtonSize.medium,
                              isLoading: _loading,
                              onPressed: _login,
                            ),
                            const SizedBox(height: 16),

                            // Quick Demo Access Buttons
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.slate50,
                                borderRadius:
                                    BorderRadius.circular(AppDesign.radiusMd),
                                border: Border.all(
                                    color: AppColors.border, width: 1),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '⚡ Quick Demo Access (1-Click Fill)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.slate700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _fillDemo('Farmer'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                          child: const Text('Farmer',
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _fillDemo('Veterinarian'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                          child: const Text('Vet',
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              _fillDemo('Government'),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 8),
                                          ),
                                          child: const Text('Govt',
                                              style: TextStyle(fontSize: 11)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String roleName, IconData icon) {
    final isSelected = _selectedRole == roleName;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedRole = roleName),
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
            boxShadow: isSelected ? AppDesign.subtleShadow : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? AppColors.primary : AppColors.slate500,
              ),
              const SizedBox(width: 6),
              Text(
                roleName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.slate900 : AppColors.slate600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.slate800,
            borderRadius: BorderRadius.circular(AppDesign.radiusSm),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryLight),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.slate400,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
