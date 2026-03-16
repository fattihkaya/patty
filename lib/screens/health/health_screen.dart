import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_ai/core/health_parameters.dart';
import 'package:pet_ai/models/log_model.dart';
import 'package:pet_ai/providers/pet_provider.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart' as sf;
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants.dart';
import '../../core/app_strings.dart';
import '../../providers/subscription_provider.dart';
import '../subscription/subscription_screen.dart';
import '../../widgets/premium_gate.dart';

class _ChartData {
  final DateTime date;
  final double? value;

  _ChartData(this.date, this.value);
}

class HealthScreen extends StatelessWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final selectedPet = petProvider.selectedPet;
    final logs = selectedPet == null
        ? <LogModel>[]
        : petProvider.getLogsForPet(selectedPet.id);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          S.of(context).statisticsDashboard,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppConstants.primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppConstants.primaryColor,
      ),
      body: selectedPet == null
          ? _buildNoPetState(context)
          : logs.isEmpty
              ? _buildEmptyLogsState(context, selectedPet.name)
              : _buildDashboard(
                  context,
                  petProvider,
                  selectedPet.id,
                  selectedPet.name,
                  logs,
                ),
    );
  }

  Widget _buildNoPetState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pets_rounded,
                size: 80, color: AppConstants.primaryColor.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            Text(
              'Henüz bir dost seçilmedi.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Home sekmesinde bir dost seçtiğinde istatistikler burada görünecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.lightTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyLogsState(BuildContext context, String petName) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined,
                size: 80, color: AppConstants.primaryColor.withValues(alpha: 0.2)),
            const SizedBox(height: 24),
            Text(
              '$petName için henüz istatistik yok',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI yorumları oluştukça mood ve enerji trendleri burada takip edilecek.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppConstants.lightTextColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, PetProvider petProvider,
      String petId, String petName, List<LogModel> logs) {
    final subProvider = context.watch<SubscriptionProvider>();
    final isLocked = subProvider.isFree;
    final s = S.of(context);
    final avgMood = _averageScore(logs.map((e) => e.moodScore));
    final avgEnergy = _averageScore(logs.map((e) => e.energyScore));
    final avgConfidence = _averageDouble(logs.map((e) => e.confidence));
    final weeklyLogs = logs.take(7).toList();
    final tips = logs
        .where(
            (log) => log.careTipTr != null && log.careTipTr!.trim().isNotEmpty)
        .take(3)
        .toList();
    final healthVitals = _prepareHealthMetrics(logs);

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          await petProvider.fetchLogs(petId);
          await petProvider.fetchPets();
        },
        color: AppConstants.primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.dashboard_rounded,
                      color: AppConstants.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '$petName için genel görünüm',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    color: AppConstants.primaryColor,
                    onPressed: () async {
                      await petProvider.fetchLogs(petId);
                      await petProvider.fetchPets();
                    },
                    tooltip: 'Yenile',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildHighlightCards(context, avgMood, avgEnergy, logs.length,
                      petId, petProvider)
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.1, end: 0),
              const SizedBox(height: 24),
              PremiumGate(
                isLocked: isLocked,
                featureTitle: s.moodEnergyTrend,
                featureDescription: s.moodEnergyTrendDescription,
                child: _buildTrendSection(weeklyLogs)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 100.ms)
                    .slideY(begin: -0.1, end: 0),
              ),
              const SizedBox(height: 24),
              if (healthVitals.isNotEmpty) ...[
                PremiumGate(
                isLocked: isLocked,
                featureTitle: s.healthVitals,
                featureDescription: s.healthVitalsDescription,
                child: _buildHealthVitalsSection(healthVitals, logs)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 200.ms)
                      .slideY(begin: -0.1, end: 0),
                ),
                const SizedBox(height: 24),
              ],
              if (tips.isNotEmpty || avgConfidence != null) ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (tips.isNotEmpty)
                      Expanded(
                        child: _buildTipsSection(tips)
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 300.ms)
                            .slideY(begin: -0.1, end: 0),
                      ),
                    if (tips.isNotEmpty && avgConfidence != null)
                      const SizedBox(width: 16),
                    if (avgConfidence != null)
                      Expanded(
                        child: _buildConfidenceCard(avgConfidence)
                            .animate()
                            .fadeIn(duration: 500.ms, delay: 400.ms)
                            .slideY(begin: -0.1, end: 0),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
              ] else ...[
                if (tips.isNotEmpty) ...[
                  _buildTipsSection(tips)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 300.ms)
                      .slideY(begin: -0.1, end: 0),
                  const SizedBox(height: 24),
                ],
                if (avgConfidence != null) ...[
                  _buildConfidenceCard(avgConfidence)
                      .animate()
                      .fadeIn(duration: 500.ms, delay: 400.ms)
                      .slideY(begin: -0.1, end: 0),
                  const SizedBox(height: 24),
                ],
              ],
              PremiumGate(
                isLocked: isLocked,
                featureTitle: s.healthRadarTitle,
                featureDescription: s.healthRadarDescription,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(s.healthSummary),
                    const SizedBox(height: 16),
                    _buildRadarChart(petProvider
                        .averageParameterScores(petId)
                        .map((key, value) => MapEntry(key, value ?? 0.0))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PremiumGate(
                isLocked: isLocked,
                featureTitle: s.advancedAiInsightsTitle,
                featureDescription: s.advancedAiInsightsDescription,
                child: _buildAdvancedAnalyticsSection(context, logs, petProvider, petId),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightCards(BuildContext context, double? mood,
      double? energy, int totalLogs, String petId, PetProvider petProvider) {
    Widget buildCard(String title, String value, Color color, Color bgColor,
        {IconData? icon, Widget? footer, VoidCallback? onTap}) {
      return Expanded(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (onTap != null) {
                HapticFeedback.lightImpact();
                onTap();
              }
            },
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bgColor.withValues(alpha: 0.1), bgColor.withValues(alpha: 0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon ?? Icons.info_rounded,
                        color: color, size: 24),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.lightTextColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1.1,
                    ),
                  ),
                  if (footer != null) ...[
                    const SizedBox(height: 12),
                    footer,
                  ],
                  if (onTap != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: color.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Detay',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    final lastLogDate = totalLogs > 0 ? _relativeDateString() : '-';

    return Row(
      children: [
        buildCard(
          'Ortalama Mood',
          mood == null ? '--' : '${mood.toStringAsFixed(1)}/5',
          AppConstants.accentColor,
          AppConstants.accentColor,
          icon: Icons.auto_awesome_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mood detayları yakında eklenecek'),
                backgroundColor: AppConstants.primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        buildCard(
          'Enerji',
          energy == null ? '--' : '${energy.toStringAsFixed(1)}/5',
          AppConstants.secondaryColor,
          AppConstants.secondaryColor,
          icon: Icons.bolt_rounded,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enerji detayları yakında eklenecek'),
                backgroundColor: AppConstants.primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        buildCard(
          'Toplam Kayıt',
          '$totalLogs',
          AppConstants.primaryColor,
          AppConstants.primaryColor,
          icon: Icons.analytics_rounded,
          footer: Text(
            'Son kayıt: $lastLogDate',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppConstants.lightTextColor,
            ),
          ),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tüm kayıtları görüntüle'),
                backgroundColor: AppConstants.primaryColor,
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrendSection(List<LogModel> logs) {
    if (logs.isEmpty) return const SizedBox.shrink();

    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentLogs = logs
        .where((log) => log.createdAt.isAfter(sevenDaysAgo))
        .take(7)
        .toList();

    if (recentLogs.isEmpty) return const SizedBox.shrink();

    final reversedLogs = recentLogs.reversed.toList();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.secondaryColor.withValues(alpha: 0.15),
                          AppConstants.accentColor.withValues(alpha: 0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.show_chart_rounded,
                      color: AppConstants.accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mood & Energy Trendi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Son 7 Gün',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppConstants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 260,
                child: _buildCombinedTrendChart(reversedLogs),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCombinedTrendChart(List<LogModel> logs) {
    final moodSpots = logs.asMap().entries.map((entry) {
      final index = entry.key;
      final log = entry.value;
      return FlSpot(index.toDouble(), log.moodScore?.toDouble() ?? 0);
    }).toList();

    final energySpots = logs.asMap().entries.map((entry) {
      final index = entry.key;
      final log = entry.value;
      return FlSpot(index.toDouble(), log.energyScore?.toDouble() ?? 0);
    }).toList();

    const moodColor = Color(0xFFEC4899);
    const energyColor = Color(0xFF8B5CF6);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppConstants.lightTextColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == value.toInt() && value >= 0 && value <= 5) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppConstants.lightTextColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < logs.length && index == value) {
                  final date = logs[index].createdAt;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd\nMMM', 'tr_TR').format(date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppConstants.darkTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.visible,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: moodSpots,
            isCurved: true,
            color: moodColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: moodColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  moodColor.withValues(alpha: 0.3),
                  moodColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          LineChartBarData(
            spots: energySpots,
            isCurved: true,
            color: energyColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: energyColor,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  energyColor.withValues(alpha: 0.3),
                  energyColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        minY: 0,
        maxY: 5,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots
                  .map((spot) {
                    final index = spot.x.toInt();
                    if (index >= 0 && index < logs.length) {
                      final isMood = spot.barIndex == 0;
                      final label = isMood ? 'Mood' : 'Energy';
                      return LineTooltipItem(
                        '$label: ${spot.y.toStringAsFixed(1)}/5',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
            tooltipBgColor: AppConstants.surfaceColor,
            tooltipRoundedRadius: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppConstants.primaryColor,
      ),
    );
  }

  IconData _getParameterIcon(String key) {
    switch (key) {
      case 'fur_luster':
        return Icons.brush_rounded;
      case 'skin_hygiene':
        return Icons.cleaning_services_rounded;
      case 'eye_clarity':
        return Icons.visibility_rounded;
      case 'nasal_discharge':
        return Icons.air_rounded;
      case 'ear_posture':
        return Icons.hearing_rounded;
      case 'weight_index':
        return Icons.monitor_weight_rounded;
      case 'posture_alignment':
        return Icons.straighten_rounded;
      case 'facial_relaxation':
        return Icons.face_rounded;
      case 'energy_vibe':
        return Icons.flash_on_rounded;
      case 'stress_level':
        return Icons.self_improvement_rounded;
      default:
        return Icons.health_and_safety_rounded;
    }
  }

  Widget _buildHealthVitalsSection(
      List<HealthVital> vitals, List<LogModel> logs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppConstants.primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Sağlık Vitals',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppConstants.primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${vitals.length} metrik',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppConstants.primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 200,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vitals.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final vital = vitals[index];
              final score = vital.score ?? 0.0;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VitalDetailScreen(
                        vital: vital,
                        logs: logs,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 180,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        vital.color.withValues(alpha: 0.1),
                        vital.color.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: vital.color.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: vital.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              vital.icon,
                              size: 20,
                              color: vital.color,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              vital.label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: vital.color,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        vital.score == null
                            ? '--'
                            : '${vital.score!.toStringAsFixed(1)}/5',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: vital.color,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: score / 5,
                          minHeight: 8,
                          backgroundColor: vital.color.withValues(alpha: 0.2),
                          valueColor:
                              AlwaysStoppedAnimation<Color>(vital.color),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        vital.description,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          height: 1.3,
                          color: AppConstants.lightTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTipsSection(List<LogModel> tips) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppConstants.accentColor,
            AppConstants.accentColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppConstants.accentColor.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Tavsiyeleri',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 20),
          ...tips.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      log.careTipTr!,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    DateFormat('dd MMM', 'tr_TR').format(log.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceCard(double? confidence) {
    final value = confidence ?? 0;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
        },
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.06),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Analiz Güvencesi',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppConstants.darkTextColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: AppConstants.lightTextColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                confidence == null
                    ? 'Yeterli veri yok.'
                    : '%${(value * 100).toStringAsFixed(0)} güven ile hesaplandı.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: AppConstants.lightTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  value: confidence ?? 0,
                  minHeight: 10,
                  backgroundColor: AppConstants.primaryLight,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppConstants.primaryColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildPetVoiceCard(LogModel log) {
    if (log.petVoiceTr == null || log.petVoiceTr!.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Petin Sesinden',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppConstants.primaryColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppConstants.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  log.petVoiceTr!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 1.6,
                    color: AppConstants.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            DateFormat('dd MMMM yyyy', 'tr_TR').format(log.createdAt),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppConstants.primaryColor.withValues(alpha: 0.7),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  double? _averageScore(Iterable<int?> scores) {
    final filtered = scores.whereType<int>().toList();
    if (filtered.isEmpty) return null;
    return filtered.reduce((a, b) => a + b) / filtered.length;
  }

  double? _averageDouble(Iterable<double?> scores) {
    final filtered = scores.whereType<double>().toList();
    if (filtered.isEmpty) return null;
    return filtered.reduce((a, b) => a + b) / filtered.length;
  }

  String _relativeDateString() {
    final now = DateTime.now();
    return DateFormat('dd MMM', 'tr_TR').format(now);
  }

  List<HealthVital> _prepareHealthMetrics(List<LogModel> logs) {
    final vitals = <HealthVital>[];

    for (final param in kHealthParameters) {
      final scores = logs
          .map((log) => log.parameterScores[param.key])
          .whereType<double>()
          .toList();

      final averageScore = scores.isEmpty
          ? null
          : scores.reduce((a, b) => a + b) / scores.length;

      final latestNote = logs.map((log) => log.noteFor(param.key)).firstWhere(
            (note) => note != null && note.trim().isNotEmpty,
            orElse: () => null,
          );

      if (averageScore != null ||
          (latestNote != null && latestNote.isNotEmpty)) {
        vitals.add(HealthVital(
          key: param.key,
          label: param.label,
          score: averageScore,
          note: latestNote,
          description: param.description,
          color: param.color,
          icon: _getParameterIcon(param.key),
        ));
      }
    }

    return vitals;
  }

  Widget _buildRadarChart(Map<String, double> parameterAverages) {
    final actualEntries = kHealthParameters.map((param) {
      final score = parameterAverages[param.key] ?? 0.0;
      return RadarEntry(value: score);
    }).toList();

    final idealEntries = kHealthParameters.map((_) {
      return const RadarEntry(value: 5.0);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '10 Eksen Sağlık Analizi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppConstants.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: RadarChart(
              RadarChartData(
                radarTouchData: RadarTouchData(
                  touchCallback: (FlTouchEvent event, response) {},
                ),
                dataSets: [
                  RadarDataSet(
                    fillColor: AppConstants.lightTextColor.withValues(alpha: 0.1),
                    borderColor: AppConstants.lightTextColor.withValues(alpha: 0.2),
                    borderWidth: 1,
                    dataEntries: idealEntries,
                  ),
                  RadarDataSet(
                    fillColor: AppConstants.primaryColor.withValues(alpha: 0.3),
                    borderColor: AppConstants.primaryColor,
                    borderWidth: 2,
                    dataEntries: actualEntries,
                  ),
                ],
                radarShape: RadarShape.polygon,
                borderData: FlBorderData(show: false),
                radarBorderData: BorderSide(
                  color: AppConstants.lightTextColor.withValues(alpha: 0.3),
                ),
                titlePositionPercentageOffset: 0.1,
                titleTextStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
                tickCount: 5,
                ticksTextStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: AppConstants.lightTextColor,
                ),
                tickBorderData: BorderSide(
                  color: AppConstants.lightTextColor.withValues(alpha: 0.3),
                ),
                gridBorderData: BorderSide(
                  color: AppConstants.lightTextColor.withValues(alpha: 0.3),
                ),
                getTitle: (index, angle) {
                  final param = kHealthParameters[index];
                  return RadarChartTitle(
                    text: param.shortLabel,
                    angle: angle,
                    positionPercentageOffset: 0.15,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildRadarChartLegend(parameterAverages),
        ],
      ),
    );
  }

  Color _getSemanticColor(double score) {
    if (score <= 2.0) {
      return AppConstants.errorColor;
    } else if (score <= 3.0) {
      return AppConstants.warningColor;
    } else {
      return AppConstants.successColor;
    }
  }

  Widget _buildRadarChartLegend(Map<String, double> parameterAverages) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: kHealthParameters.map((param) {
        final score = parameterAverages[param.key] ?? 0;
        final semanticColor = _getSemanticColor(score);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: semanticColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${param.shortLabel}: ${score.toStringAsFixed(1)}/5',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildAdvancedAnalyticsSection(
    BuildContext context,
    List<LogModel> logs,
    PetProvider petProvider,
    String petId,
  ) {
    final subscriptionProvider = context.watch<SubscriptionProvider>();
    final hasAdvancedAnalytics =
        subscriptionProvider.checkFeatureAccess('advanced_analytics');

    if (!hasAdvancedAnalytics) {
      return _buildPremiumUpgradeCard(
        context,
        title: 'Gelişmiş Analitik',
        description:
            'Premium üyeler için detaylı trend analizi ve karşılaştırmalı grafikler',
        feature: 'advanced_analytics',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Gelişmiş Analitik'),
        const SizedBox(height: 16),
        _buildAdvancedTrendChart(logs, petProvider, petId),
      ],
    );
  }

  Widget _buildAdvancedTrendChart(
    List<LogModel> logs,
    PetProvider petProvider,
    String petId,
  ) {
    if (logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Center(
          child: Text(
            'Yeterli veri yok',
            style: GoogleFonts.plusJakartaSans(
              color: AppConstants.lightTextColor,
            ),
          ),
        ),
      );
    }

    final chartData = logs.map((log) {
      final scores = log.parameterScores;
      final avgScore = scores.values.isNotEmpty
          ? scores.values
                  .map((s) => (s ?? 0).toDouble())
                  .reduce((a, b) => a + b) /
              scores.length
          : 0.0;
      return _ChartData(log.createdAt, avgScore);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Parametre Trend Analizi',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppConstants.darkTextColor,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 250,
            child: sf.SfCartesianChart(
              primaryXAxis: sf.DateTimeAxis(
                dateFormat: DateFormat('dd/MM'),
              ),
              series: <sf.LineSeries<_ChartData, DateTime>>[
                sf.LineSeries<_ChartData, DateTime>(
                  dataSource: chartData,
                  xValueMapper: (_ChartData data, _) => data.date,
                  yValueMapper: (_ChartData data, _) => data.value,
                  color: AppConstants.primaryColor,
                  width: 3,
                  markerSettings: const sf.MarkerSettings(
                    isVisible: true,
                    height: 6,
                    width: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumUpgradeCard(
    BuildContext context, {
    required String title,
    required String description,
    required String feature,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppConstants.primaryGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: AppConstants.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppConstants.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppConstants.borderRadius),
                ),
              ),
              child: Text(
                'Premium\'a Geç',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HealthVital {
  final String key;
  final String label;
  final double? score;
  final String? note;
  final String description;
  final Color color;
  final IconData icon;

  const HealthVital({
    required this.key,
    required this.label,
    required this.score,
    required this.note,
    required this.description,
    required this.color,
    required this.icon,
  });
}

// Vital Detail Screen
class VitalDetailScreen extends StatelessWidget {
  final HealthVital vital;
  final List<LogModel> logs;

  const VitalDetailScreen({
    super.key,
    required this.vital,
    required this.logs,
  });

  @override
  Widget build(BuildContext context) {
    final param = kHealthParameters.firstWhere(
      (p) => p.key == vital.key,
      orElse: () => kHealthParameters.first,
    );

    final scoreHistory = logs
        .map((log) {
          final score = log.parameterScores[vital.key];
          if (score != null) {
            return MapEntry(log.createdAt, score.toDouble());
          }
          return null;
        })
        .whereType<MapEntry<DateTime, double>>()
        .toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    final noteHistoryMap = <DateTime, String>{};
    for (final log in logs) {
      final note = log.noteFor(vital.key);
      if (note != null && note.trim().isNotEmpty) {
        noteHistoryMap[log.createdAt] = note;
      }
    }

    final scores = scoreHistory.map((e) => e.value).toList();

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          vital.label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppConstants.primaryColor,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppConstants.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    vital.color.withValues(alpha: 0.15),
                    vital.color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: vital.color.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: vital.color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      vital.icon,
                      size: 48,
                      color: vital.color,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    vital.score == null
                        ? '--'
                        : '${vital.score!.toStringAsFixed(1)}/5',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: vital.color,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: (vital.score ?? 0) / 5,
                      minHeight: 12,
                      backgroundColor: vital.color.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(vital.color),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Description
            Text(
              'Açıklama',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: AppConstants.cardShadow,
              ),
              child: Text(
                param.description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  height: 1.6,
                  color: AppConstants.darkTextColor,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Latest Note
            if (vital.note != null && vital.note!.trim().isNotEmpty) ...[
              Text(
                'Son Not',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: vital.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: vital.color.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note_rounded,
                      color: vital.color,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        vital.note!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.6,
                          color: AppConstants.darkTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Statistics
            if (scores.isNotEmpty) ...[
              Text(
                'İstatistikler',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                  boxShadow: AppConstants.cardShadow,
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                        'Ortalama', '${vital.score!.toStringAsFixed(1)}/5'),
                    Divider(height: 24, color: Colors.white.withValues(alpha: 0.06)),
                    _buildStatRow('Toplam Ölçüm', '${scores.length}'),
                    Divider(height: 24, color: Colors.white.withValues(alpha: 0.06)),
                    _buildStatRow('En Yüksek',
                        '${scores.reduce((a, b) => a > b ? a : b).toStringAsFixed(1)}/5'),
                    Divider(height: 24, color: Colors.white.withValues(alpha: 0.06)),
                    _buildStatRow('En Düşük',
                        '${scores.reduce((a, b) => a < b ? a : b).toStringAsFixed(1)}/5'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Score History
            if (scoreHistory.isNotEmpty) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: vital.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.timeline_rounded,
                      color: vital.color,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Değer Geçmişi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppConstants.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Chart
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppConstants.surfaceColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                    width: 1,
                  ),
                  boxShadow: AppConstants.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 200,
                      child: _buildScoreHistoryChart(scoreHistory, vital.color),
                    ),
                    const SizedBox(height: 20),
                    if (scoreHistory.length > 3) ...[
                      Text(
                        'Son Kayıtlar',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...scoreHistory
                          .take(3)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                        final index = entry.key;
                        final dateScore = entry.value;
                        final isLast = index == 2;
                        final note = noteHistoryMap[dateScore.key];
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                          child: _buildCompactHistoryItem(
                            date: dateScore.key,
                            value: dateScore.value,
                            color: vital.color,
                            note: note,
                            onTap: note != null
                                ? () => _showNoteDialog(
                                    context, dateScore.key, note, vital.color)
                                : null,
                          ),
                        );
                      }),
                    ] else ...[
                      ...scoreHistory.toList().asMap().entries.map((entry) {
                        final index = entry.key;
                        final dateScore = entry.value;
                        final isLast = index == scoreHistory.length - 1;
                        final note = noteHistoryMap[dateScore.key];
                        return Padding(
                          padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
                          child: _buildCompactHistoryItem(
                            date: dateScore.key,
                            value: dateScore.value,
                            color: vital.color,
                            note: note,
                            onTap: note != null
                                ? () => _showNoteDialog(
                                    context, dateScore.key, note, vital.color)
                                : null,
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            color: AppConstants.lightTextColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            color: AppConstants.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreHistoryChart(
    List<MapEntry<DateTime, double>> scoreHistory,
    Color color,
  ) {
    final reversed = scoreHistory.reversed.toList();
    final spots = reversed.asMap().entries.map((entry) {
      final dateScore = entry.value;
      return FlSpot(entry.key.toDouble(), dateScore.value);
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppConstants.lightTextColor.withValues(alpha: 0.1),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == value.toInt() && value >= 0 && value <= 5) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      value.toInt().toString(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: AppConstants.lightTextColor,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index >= 0 && index < reversed.length) {
                  final date = reversed[index].key;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('dd\nMMM', 'tr_TR').format(date),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: AppConstants.lightTextColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: color,
                  strokeWidth: 3,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.1),
            ),
          ),
        ],
        minY: 0,
        maxY: 5,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots
                  .map((spot) {
                    final index = spot.x.toInt();
                    if (index >= 0 && index < reversed.length) {
                      final date = reversed[index].key;
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)}/5\n${DateFormat('dd MMM yyyy HH:mm', 'tr_TR').format(date)}',
                        GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }
                    return null;
                  })
                  .whereType<LineTooltipItem>()
                  .toList();
            },
            tooltipBgColor: AppConstants.surfaceColor,
            tooltipRoundedRadius: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHistoryItem({
    required DateTime date,
    required double value,
    required Color color,
    String? note,
    VoidCallback? onTap,
  }) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;
    final hasNote = note != null && note.trim().isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isToday ? color.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isToday ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        DateFormat('dd MMMM yyyy', 'tr_TR').format(date),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppConstants.darkTextColor,
                        ),
                      ),
                      if (isToday) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Bugün',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                      if (hasNote) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.note_rounded,
                                size: 12,
                                color: color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Not var',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm', 'tr_TR').format(date),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppConstants.lightTextColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    color.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}/5',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (hasNote) ...[
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 20,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showNoteDialog(
    BuildContext context,
    DateTime date,
    String note,
    Color color,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
            left: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
            right: BorderSide(color: Colors.white.withValues(alpha: 0.06), width: 1),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.note_rounded,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('dd MMMM yyyy', 'tr_TR').format(date),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppConstants.darkTextColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm', 'tr_TR').format(date),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      note,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        height: 1.6,
                        color: AppConstants.darkTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildModernNoteHistoryItem({
    required DateTime date,
    required String note,
    required Color color,
    required bool isLast,
    required bool isFirst,
  }) {
    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Container(
      margin: EdgeInsets.only(
        top: isFirst ? 0 : 8,
        bottom: isLast ? 0 : 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color,
                    width: 2.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.note_rounded,
                    size: 18,
                    color: color,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isToday ? color.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color:
                      isToday ? color.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.06),
                  width: 1.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('dd MMMM yyyy', 'tr_TR').format(date),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.darkTextColor,
                          ),
                        ),
                      ),
                      if (isToday) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Bugün',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        DateFormat('HH:mm', 'tr_TR').format(date),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppConstants.lightTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: color.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      note,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.6,
                        color: AppConstants.darkTextColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
