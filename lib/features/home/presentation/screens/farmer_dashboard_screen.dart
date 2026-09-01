import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flock_sense/config/routes/app_routes.dart';
import 'package:flock_sense/core/theme/app_colors.dart';
import 'package:flock_sense/core/theme/app_design.dart';
import 'package:flock_sense/core/theme/app_typography.dart';
import 'package:flock_sense/core/widgets/app_button.dart';
import 'package:flock_sense/core/widgets/metric_card.dart';
import 'package:flock_sense/core/widgets/page_container.dart';
import 'package:flock_sense/core/widgets/responsive_data_table.dart';
import 'package:flock_sense/core/widgets/status_badge.dart';
import 'package:flock_sense/features/daily_records/presentation/screens/daily_records_dashboard_screen.dart';
import 'package:flock_sense/features/health/presentation/screens/health_screen.dart';
import 'package:flock_sense/features/home/presentation/providers/farmer_dashboard_provider.dart';

/// Dedicated Untitled UI Clean SaaS & BentoGlow Farmer Operations Dashboard
class FarmerDashboardScreen extends ConsumerStatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  ConsumerState<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends ConsumerState<FarmerDashboardScreen> {
  String _selectedDateRange = 'Last 30 Days';
  int _selectedGrowthMetric = 0; // 0: Body Weight (g), 1: FCR Curve

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'Farmer';
    final state = ref.watch(farmerDashboardProvider);

    final totalLiveBirds = state.totalLiveBirds > 0 ? state.totalLiveBirds : 48250;

    return PageContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Untitled UI Top Control & Farm Telemetry Header ──────────────
          _buildUntitledUIHeader(displayName),
          const SizedBox(height: 20),

          // ── 2. Untitled UI 4-Card Hero Metric Grid ───────────────────────────
          _buildHeroMetricStrip(totalLiveBirds),
          const SizedBox(height: 24),

          // ── 3. Main Split Section (65% Analytics / 35% AI & Audit) ──────────
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1024;
              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left 65%: Growth Benchmark & IoT Shed Matrix
                    Expanded(
                      flex: 65,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildGrowthBenchmarkCard(),
                          const SizedBox(height: 20),
                          _buildIoTShedFleetGrid(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    // Right 35%: BentoGlow AI Health & Activity Feed
                    Expanded(
                      flex: 35,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBentoGlowAICard(),
                          const SizedBox(height: 20),
                          _buildActivityAuditLedger(),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGrowthBenchmarkCard(),
                    const SizedBox(height: 20),
                    _buildIoTShedFleetGrid(),
                    const SizedBox(height: 20),
                    _buildBentoGlowAICard(),
                    const SizedBox(height: 20),
                    _buildActivityAuditLedger(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 24),

          // ── 4. Active Flocks & Batch Telemetry Data Table ─────────────────────
          _buildActiveFlocksTable(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── 1. Header Widget ─────────────────────────────────────────────────────────
  Widget _buildUntitledUIHeader(String displayName) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Farm Info & Live Status
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                ),
                child: const Icon(Icons.hub_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'GreenValley Agri-Farm • Shed Network',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.slate900,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.healthyBg,
                          borderRadius: BorderRadius.circular(AppDesign.radiusFull),
                          border: Border.all(color: AppColors.healthyBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: AppColors.healthy, size: 7),
                            SizedBox(width: 5),
                            Text(
                              'Live Telemetry Online',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.healthy,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Welcome back, $displayName • Nashik, Maharashtra • 4 Active Sheds',
                    style: const TextStyle(fontSize: 13, color: AppColors.slate500),
                  ),
                ],
              ),
            ],
          ),

          // Right: Date Selector & Actions
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.slate50,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.slate600),
                    const SizedBox(width: 6),
                    Text(
                      _selectedDateRange,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.slate700),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: AppColors.slate500),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              AppButton(
                label: 'Export PDF',
                icon: Icons.download_rounded,
                size: AppButtonSize.small,
                variant: AppButtonVariant.outlined,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Generating batch telemetry report PDF...')),
                  );
                },
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Add Daily Log',
                icon: Icons.add_rounded,
                size: AppButtonSize.small,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DailyRecordsDashboardScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── 2. Untitled UI 4-Card Hero Metric Grid ───────────────────────────────────
  Widget _buildHeroMetricStrip(int totalBirds) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 48) / 4;
        final isNarrow = constraints.maxWidth < 900;
        final itemWidth = isNarrow ? (constraints.maxWidth - 16) / 2 : cardWidth;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            SizedBox(
              width: itemWidth,
              child: MetricCard(
                title: 'Total Live Flock',
                value: NumberFormat('#,###').format(totalBirds),
                delta: '+2.4%',
                isPositiveDelta: true,
                icon: Icons.pets_outlined,
                accentColor: AppColors.primary,
                subtitle: 'Across 4 active sheds',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: const MetricCard(
                title: 'Cumulative FCR',
                value: '1.48',
                delta: '0.04 Efficient',
                isPositiveDelta: true,
                icon: Icons.bolt_outlined,
                accentColor: AppColors.info,
                subtitle: 'Ross 308 Breed Target: 1.52',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: const MetricCard(
                title: 'Flock Mortality Rate',
                value: '1.8%',
                delta: '-0.3% Improved',
                isPositiveDelta: true,
                icon: Icons.health_and_safety_outlined,
                accentColor: AppColors.healthy,
                subtitle: 'Target threshold < 2.50%',
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: const MetricCard(
                title: 'Projected Net Revenue',
                value: '₹ 5,84,200',
                delta: '+8.2% vs Plan',
                isPositiveDelta: true,
                icon: Icons.payments_outlined,
                accentColor: AppColors.warning,
                subtitle: 'Projected harvest Day 38 (2.15 kg)',
              ),
            ),
          ],
        );
      },
    );
  }

  // ── 3A. Growth Velocity vs Breed Benchmark Card ───────────────────────────────
  Widget _buildGrowthBenchmarkCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flock Growth Velocity vs Breed Benchmark',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                      letterSpacing: -0.2,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Actual live body mass tracking vs Cobb 500 and Ross 308 breed standard curves',
                    style: TextStyle(fontSize: 12.5, color: AppColors.slate500),
                  ),
                ],
              ),
              // Segmented Metric Toggle
              Container(
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    _buildSegmentButton('Weight (g)', _selectedGrowthMetric == 0, () {
                      setState(() => _selectedGrowthMetric = 0);
                    }),
                    _buildSegmentButton('FCR Curve', _selectedGrowthMetric == 1, () {
                      setState(() => _selectedGrowthMetric = 1);
                    }),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Growth Curve Visual Bars & Markers
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildGrowthColumn('Day 07', '195g', '180g', 0.22),
                _buildGrowthColumn('Day 14', '490g', '460g', 0.38),
                _buildGrowthColumn('Day 21', '980g', '930g', 0.55),
                _buildGrowthColumn('Day 28', '1,490g', '1,420g', 0.72, isCurrent: true),
                _buildGrowthColumn('Day 35 (Est)', '2,080g', '1,990g', 0.88, isProjected: true),
                _buildGrowthColumn('Day 42 (Est)', '2,650g', '2,540g', 1.0, isProjected: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendPill('Actual Flock Weight', AppColors.primary, isSolid: true),
              const SizedBox(width: 16),
              _buildLegendPill('Cobb 500 Target', AppColors.info),
              const SizedBox(width: 16),
              _buildLegendPill('Ross 308 Target', AppColors.slate400),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrowthColumn(String day, String actual, String target, double fillFraction, {bool isCurrent = false, bool isProjected = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          actual,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isCurrent ? AppColors.primary : (isProjected ? AppColors.slate500 : AppColors.slate900),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 32,
          height: 110 * fillFraction,
          decoration: BoxDecoration(
            color: isCurrent
                ? AppColors.primary
                : (isProjected ? AppColors.primary.withOpacity(0.3) : AppColors.primary.withOpacity(0.7)),
            borderRadius: BorderRadius.circular(6),
            border: isCurrent ? Border.all(color: AppColors.primaryDark, width: 2) : null,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          day,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
            color: isCurrent ? AppColors.primary : AppColors.slate600,
          ),
        ),
      ],
    );
  }

  Widget _buildLegendPill(String label, Color color, {bool isSolid = false}) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.slate600, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDesign.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDesign.radiusSm),
          boxShadow: isSelected ? AppDesign.subtleShadow : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.slate900 : AppColors.slate600,
          ),
        ),
      ),
    );
  }

  // ── 3B. Multi-Shed IoT Sensor Fleet Grid ─────────────────────────────────────
  Widget _buildIoTShedFleetGrid() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.sensors_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Multi-Shed IoT Environmental Sensor Fleet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Sensor Calibration →', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4 Shed Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final width = isWide ? (constraints.maxWidth - 16) / 2 : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(
                    width: width,
                    child: _buildShedCard(
                      shedName: 'Shed 01 — Broiler Cobb 500',
                      batchId: 'Batch B08 • Day 28',
                      birds: '12,500 Birds',
                      temp: '24.2°C',
                      humidity: '62%',
                      ammonia: '12 ppm',
                      siloLevel: '84% (Corn Soy)',
                      status: 'Optimal',
                      statusColor: AppColors.healthy,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildShedCard(
                      shedName: 'Shed 02 — Broiler Ross 308',
                      batchId: 'Batch B07 • Day 31',
                      birds: '11,800 Birds',
                      temp: '25.8°C',
                      humidity: '68%',
                      ammonia: '18 ppm',
                      siloLevel: '42% ⚠️ Refill Due',
                      status: 'Attention',
                      statusColor: AppColors.warning,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildShedCard(
                      shedName: 'Shed 03 — Starter Broiler',
                      batchId: 'Batch B09 • Day 09',
                      birds: '13,200 Birds',
                      temp: '29.5°C',
                      humidity: '58%',
                      ammonia: '8 ppm',
                      siloLevel: '92% (Pre-Starter)',
                      status: 'Optimal',
                      statusColor: AppColors.healthy,
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _buildShedCard(
                      shedName: 'Shed 04 — Grower Unit',
                      batchId: 'Batch B06 • Day 36',
                      birds: '10,750 Birds',
                      temp: '23.8°C',
                      humidity: '64%',
                      ammonia: '14 ppm',
                      siloLevel: '68% (Finisher)',
                      status: 'Optimal',
                      statusColor: AppColors.healthy,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShedCard({
    required String shedName,
    required String batchId,
    required String birds,
    required String temp,
    required String humidity,
    required String ammonia,
    required String siloLevel,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        borderRadius: BorderRadius.circular(AppDesign.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                shedName,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.slate900),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesign.radiusFull),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('$batchId • $birds', style: const TextStyle(fontSize: 11.5, color: AppColors.slate500)),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSensorItem('🌡️ Temp', temp),
              _buildSensorItem('💧 Humidity', humidity),
              _buildSensorItem('💨 NH3', ammonia),
              _buildSensorItem('📦 Silo', siloLevel),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSensorItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.slate500)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.slate800)),
      ],
    );
  }

  // ── 3C. BentoGlow AI Biometric Command Card ──────────────────────────────────
  Widget _buildBentoGlowAICard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Obsidian Slate
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: const [
          BoxShadow(color: Color(0x1F000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: Color(0xFF10B981), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'AI Biometric Command',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppDesign.radiusFull),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
                ),
                child: const Text(
                  'Gemini 1.5 Active',
                  style: TextStyle(color: Color(0xFF10B981), fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Two Bento Metric Rings: Biosecurity & THI
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Biosecurity Score', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      SizedBox(height: 4),
                      Text('94 / 100', style: TextStyle(color: Color(0xFF10B981), fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('Grade A • Optimal', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(AppDesign.radiusMd),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('THI Climate Stress', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      SizedBox(height: 4),
                      Text('72.4 THI', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 20, fontWeight: FontWeight.w800)),
                      Text('Stress Free Range', style: TextStyle(color: Colors.white60, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // AI Syndromic Advisory Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B).withOpacity(0.6),
              borderRadius: BorderRadius.circular(AppDesign.radiusMd),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.insights_rounded, color: Color(0xFF38BDF8), size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Flock growth velocity is +3.1% above Cobb 500 standard. Water-to-feed ratio is optimal (2.08 L/kg). Zero pathogenic respiratory anomalies detected across sheds.',
                    style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Action Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF38BDF8),
                side: const BorderSide(color: Color(0xFF0284C7)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesign.radiusMd)),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              icon: const Icon(Icons.health_and_safety_outlined, size: 16),
              label: const Text('Open Full Biosecurity Diagnosis', style: TextStyle(fontSize: 12.5)),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HealthScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── 3D. Daily Farm Activity & Audit Ledger ───────────────────────────────────
  Widget _buildActivityAuditLedger() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDesign.radiusLg),
        border: Border.all(color: AppColors.border),
        boxShadow: AppDesign.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Farm Activity & Audit',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.slate900),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DailyRecordsDashboardScreen()),
                  );
                },
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildAuditRow('10:30 AM', 'Feed Silo 02 Refilled', '4.2 Tons Broiler Finisher Dispatched', Icons.inventory_2_outlined, AppColors.primary),
          const Divider(height: 16),
          _buildAuditRow('08:15 AM', 'Daily Mortality Logged', 'Shed 02 logged 12 birds (0.04%)', Icons.check_circle_outline_rounded, AppColors.healthy),
          const Divider(height: 16),
          _buildAuditRow('Yesterday', 'ND LaSota Vaccination', 'Batch B04 completed 21-day booster', Icons.vaccines_outlined, AppColors.info),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String time, String title, String subtitle, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppDesign.radiusMd),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.slate900)),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.slate500)),
            ],
          ),
        ),
        Text(time, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
      ],
    );
  }

  // ── 4. Active Flocks Data Table ──────────────────────────────────────────────
  Widget _buildActiveFlocksTable() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Flocks & Batch Telemetry',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.slate900),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.farms),
              child: const Text('Manage Farms & Flocks →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ResponsiveDataTable(
          columns: const [
            ResponsiveDataColumn(label: 'Flock Identifier', flex: 2),
            ResponsiveDataColumn(label: 'Breed Standard', flex: 2),
            ResponsiveDataColumn(label: 'Age', flex: 1),
            ResponsiveDataColumn(label: 'Live Count', flex: 2),
            ResponsiveDataColumn(label: 'FCR Efficiency', flex: 2),
            ResponsiveDataColumn(label: 'Health Index', flex: 2),
            ResponsiveDataColumn(label: 'Action', flex: 1, align: TextAlign.right),
          ],
          rows: [
            ResponsiveDataRow(
              cells: [
                const Text('Batch B08 (Shed 01)', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate900)),
                const Text('Broiler Cobb 500', style: TextStyle(color: AppColors.slate700)),
                const Text('28 days', style: TextStyle(color: AppColors.slate700)),
                const Text('12,500 birds', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text('1.48 (Optimal)', style: TextStyle(color: AppColors.healthy, fontWeight: FontWeight.w600)),
                StatusBadge.fromStatus('Healthy'),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.slate400),
              ],
            ),
            ResponsiveDataRow(
              cells: [
                const Text('Batch B07 (Shed 02)', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate900)),
                const Text('Broiler Ross 308', style: TextStyle(color: AppColors.slate700)),
                const Text('31 days', style: TextStyle(color: AppColors.slate700)),
                const Text('11,800 birds', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text('1.54 (Standard)', style: TextStyle(color: AppColors.info, fontWeight: FontWeight.w600)),
                StatusBadge.fromStatus('Monitoring'),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.slate400),
              ],
            ),
            ResponsiveDataRow(
              cells: [
                const Text('Batch B09 (Shed 03)', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate900)),
                const Text('Starter Broiler', style: TextStyle(color: AppColors.slate700)),
                const Text('09 days', style: TextStyle(color: AppColors.slate700)),
                const Text('13,200 birds', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text('1.18 (Starter)', style: TextStyle(color: AppColors.healthy, fontWeight: FontWeight.w600)),
                StatusBadge.fromStatus('Healthy'),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.slate400),
              ],
            ),
            ResponsiveDataRow(
              cells: [
                const Text('Batch B06 (Shed 04)', style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.slate900)),
                const Text('Grower Unit', style: TextStyle(color: AppColors.slate700)),
                const Text('36 days', style: TextStyle(color: AppColors.slate700)),
                const Text('10,750 birds', style: TextStyle(fontWeight: FontWeight.w600)),
                const Text('1.62 (Finisher)', style: TextStyle(color: AppColors.healthy, fontWeight: FontWeight.w600)),
                StatusBadge.fromStatus('Healthy'),
                const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.slate400),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
