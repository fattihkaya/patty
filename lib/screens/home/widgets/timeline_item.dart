import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/constants.dart';
import '../../../core/app_strings.dart';
import '../../../core/health_parameters.dart';
import '../../../models/log_model.dart';
import '../../../models/condition_model.dart';
import '../../../providers/pet_provider.dart';
import '../../../providers/subscription_provider.dart';
import '../../subscription/subscription_screen.dart';
import 'story_share_screen.dart';

class TimelineItem extends StatefulWidget {
  final LogModel log;
  final bool isLast;
  final String? petName;
  final String? userName;
  final String? avatarUrl;
  final bool showAnalysis;

  const TimelineItem({
    super.key,
    required this.log,
    required this.isLast,
    this.petName,
    this.userName,
    this.avatarUrl,
    this.showAnalysis = false,
  });

  @override
  State<TimelineItem> createState() => _TimelineItemState();
}

class _TimelineItemState extends State<TimelineItem> {
  LogModel get log => widget.log;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 6,
            top: 6,
            child: Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          if (!widget.isLast)
            Positioned(
              left: 11.5,
              top: 24,
              bottom: 0,
              child: Container(
                width: 1.5,
                decoration: BoxDecoration(
                  color: AppConstants.lightTextColor.withAlpha(51),
                ),
              ),
            ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 40),
              Expanded(child: _buildLogCard(context)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthChipExpanded({
    required String label,
    required int value,
    required Color color,
    String? note,
  }) {
    final hasNote = note != null && note.trim().isNotEmpty;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '$value/5',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: 6),
            Text(
              note.trim(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                height: 1.35,
                color: color.withValues(alpha: 0.95),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSummarySheet(
    BuildContext context, {
    required String summary,
    String? careTip,
    String? petVoice,
    required List<_HealthMetric> metrics,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                controller: controller,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.insights_rounded,
                            color: AppConstants.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'Detaylı Sağlık Raporu',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      summary,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        color: AppConstants.darkTextColor.withValues(alpha: 0.9),
                      ),
                    ),
                    if (careTip != null && careTip.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildCollapsibleText(
                        title: 'Bakım Tavsiyesi',
                        icon: Icons.lightbulb_outline_rounded,
                        content: careTip.trim(),
                        expanded: true,
                        onToggle: () {},
                        accent: AppConstants.accentColor,
                      ),
                    ],
                    if (petVoice != null && petVoice.trim().isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildCollapsibleText(
                        title: getPetVoiceLabel(ctx, widget.petName),
                        icon: Icons.record_voice_over,
                        content: petVoice.trim(),
                        expanded: true,
                        onToggle: () {},
                        accent: AppConstants.primaryColor,
                      ),
                    ],
                    if (metrics.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'Parametreler',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: metrics
                            .map(
                              (m) => _buildHealthChipExpanded(
                                label: m.label,
                                value: m.score,
                                color: m.color,
                                note: m.note,
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ignore: unused_element
  Widget _buildHealthChip({
    required String label,
    required int value,
    required Color color,
    String? note,
  }) {
    final hasNote = note != null && note.trim().isNotEmpty;
    return Container(
      width: 120,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              Text(
                '$value/5',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (hasNote) ...[
            const SizedBox(height: 4),
            Tooltip(
              message: note.trim(),
              child: Text(
                note.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: color.withValues(alpha: 0.9),
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogCard(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildImage(context),
          _buildInfo(context),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).moveY(begin: 30, end: 0);
  }

  Widget _buildImage(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3, // Senior Request: 4:3 Ratio
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              log.photoUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: AppConstants.surfaceColorAlt,
                  alignment: Alignment.center,
                  child: const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: AppConstants.surfaceColorAlt,
                alignment: Alignment.center,
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image_rounded,
                        color: AppConstants.lightTextColor, size: 28),
                    SizedBox(height: 8),
                    Text(
                      'Fotoğraf yüklenemedi',
                      style: TextStyle(
                        color: AppConstants.lightTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.ios_share_rounded,
                    size: 20, color: Colors.white),
                onPressed: () => _shareLog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final log = widget.log;
    final s = S.of(context);
    final summary = log.summaryTr?.trim().isNotEmpty == true
        ? log.summaryTr!.trim()
        : log.aiComment.trim();
    final careTip = log.careTipTr;
    final petVoice = log.petVoiceTr;
    final moodScore = log.moodScore;
    final energyScore = log.energyScore;

    // My Pets (Diary) için: analiz blokları açık
    if (widget.showAnalysis) {
      final metrics = _buildHealthMetrics();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (moodScore != null || energyScore != null)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  if (moodScore != null)
                    _buildScoreChip(
                      label: s.aiMood,
                      value: moodScore,
                      color: AppConstants.accentColor,
                    ),
                  if (energyScore != null)
                    _buildScoreChip(
                      label: s.energy,
                      value: energyScore,
                      color: AppConstants.secondaryColor,
                    ),
                ],
              ),
            if (moodScore != null || energyScore != null)
              const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Consumer<SubscriptionProvider>(
                builder: (context, subProvider, _) {
                  final isPremium = subProvider.isPremium;
                  return TextButton.icon(
                    onPressed: () {
                      if (isPremium) {
                        _showSummarySheet(
                          context,
                          summary: summary,
                          careTip: careTip,
                          petVoice: petVoice,
                          metrics: metrics,
                        );
                      } else {
                        HapticFeedback.mediumImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const SubscriptionScreen(),
                          ),
                        );
                      }
                    },
                    icon: Icon(
                      isPremium ? Icons.auto_awesome_rounded : Icons.lock_rounded,
                      size: 16,
                      color: isPremium ? AppConstants.primaryColor : Colors.amber,
                    ),
                    label: Text(
                      s.openHealthSummary,
                      style: TextStyle(
                        color: isPremium ? AppConstants.primaryColor : AppConstants.lightTextColor,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  );
                },
              ),
            ),
            if (petVoice != null && petVoice.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPetVoiceCard(context, petVoice.trim()),
            ],
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sadece pet voice varsa göster - Instagram tarzı minimal kart
          if (petVoice != null && petVoice.trim().isNotEmpty)
            Builder(
              builder: (ctx) {
                final label = getPetVoiceLabel(ctx, widget.petName);
                return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppConstants.surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.06),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pet avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppConstants.primaryLight,
                    backgroundImage: widget.avatarUrl != null
                        ? NetworkImage(widget.avatarUrl!)
                        : null,
                    child: widget.avatarUrl == null
                        ? const Icon(Icons.pets,
                            color: AppConstants.primaryColor, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pet sesi etiketi ve tarih - tek satır
                        Row(
                          children: [
                            if (label.isNotEmpty) ...[
                              Text(
                                label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Text(
                               label.isNotEmpty
                                   ? '• ${DateFormat(s.languageCode == 'en' ? 'MMM dd' : 'dd MMM', s.languageCode).format(log.createdAt)}'
                                   : DateFormat(s.languageCode == 'en' ? 'MMM dd' : 'dd MMM', s.languageCode)
                                       .format(log.createdAt),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: AppConstants.lightTextColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Pet voice metni
                        Text(
                          petVoice.trim(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.4,
                            color: AppConstants.darkTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
              },
            ),
          // Eğer pet voice yoksa sadece mood/energy göster
          if (petVoice == null || petVoice.trim().isEmpty) ...[
            if (moodScore != null || energyScore != null)
              Wrap(
                spacing: 8,
                children: [
                  if (moodScore != null)
                    _buildSimpleChip(
                      icon: Icons.sentiment_satisfied_outlined,
                      label: 'Mood $moodScore/5',
                      color: AppConstants.accentColor,
                    ),
                  if (energyScore != null)
                    _buildSimpleChip(
                      icon: Icons.bolt_outlined,
                      label: 'Enerji $energyScore/5',
                      color: AppConstants.secondaryColor,
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildPetVoiceCard(BuildContext context, String petVoice) {
    final label = getPetVoiceLabel(context, widget.petName);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppConstants.primaryLight,
            backgroundImage:
                widget.avatarUrl != null ? NetworkImage(widget.avatarUrl!) : null,
            child: widget.avatarUrl == null
                ? const Icon(Icons.pets, color: AppConstants.primaryColor, size: 20)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (label.isNotEmpty) ...[
                      Text(
                        label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      DateFormat('dd MMM', 'tr_TR').format(log.createdAt),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppConstants.lightTextColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  petVoice,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    height: 1.4,
                    color: AppConstants.darkTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleText({
    required String title,
    required IconData icon,
    required String content,
    required bool expanded,
    required VoidCallback onToggle,
    Color accent = AppConstants.primaryColor,
  }) {
    const collapsedLines = 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.smallBorderRadius),
        border: Border.all(color: accent.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              children: [
                Icon(
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 18,
                    color: accent),
                const SizedBox(width: 6),
                Icon(icon, size: 16, color: accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                Text(
                  expanded ? 'Daralt' : 'Aç',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: accent.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 160),
            crossFadeState:
                expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: Text(
              content,
              maxLines: collapsedLines,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: accent.withValues(alpha: 0.9),
              ),
            ),
            secondChild: Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: accent.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildChronicSection(
    List<ConditionModel> chronicConditions,
    String? healthNote,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 16,
                  color: AppConstants.primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Takip Edilen Durumlar',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: chronicConditions
                .map(
                  (condition) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryLight,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          condition.label,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                        if (condition.note?.trim().isNotEmpty ?? false)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              condition.note!.trim(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color:
                                    AppConstants.darkTextColor.withValues(alpha: 0.7),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          if (healthNote?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              'Günlük Not: ${healthNote!.trim()}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppConstants.darkTextColor.withValues(alpha: 0.85),
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<_HealthMetric> _buildHealthMetrics() {
    final metrics = <_HealthMetric>[];

    // Use the new parameter system
    for (final param in kHealthParameters) {
      final score = log.scoreFor(param.key);
      final note = log.noteFor(param.key);

      if (score != null) {
        metrics.add(_HealthMetric(
          label: param.shortLabel,
          score: score,
          note: note,
          color: param.color,
        ));
      }
    }

    return metrics;
  }

  Widget _buildScoreChip({
    required String label,
    required int value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              label == 'Mood' ? Icons.sentiment_satisfied_rounded : Icons.bolt_rounded,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: color.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$value/5',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildActionRow(
      BuildContext context, String cleanedComment, String logId) {
    final provider = context.watch<PetProvider>();
    final liked = provider.likedByMe(logId);
    final likeCount = provider.likeCountFor(logId);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => provider.toggleLike(logId),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppConstants.surfaceColor,
              foregroundColor: liked
                  ? AppConstants.primaryColor
                  : AppConstants.lightTextColor,
              side: BorderSide(
                color: liked
                    ? AppConstants.primaryColor.withValues(alpha: 0.3)
                    : AppConstants.lightTextColor.withValues(alpha: 0.2),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              size: 18,
              color: liked
                  ? AppConstants.primaryColor
                  : AppConstants.lightTextColor,
            ),
            label: Text(
              likeCount > 0 ? likeCount.toString() : 'Beğen',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _shareLog(context),
            style: OutlinedButton.styleFrom(
              backgroundColor: AppConstants.surfaceColor,
              foregroundColor: AppConstants.primaryColor,
              side: BorderSide(
                color: AppConstants.primaryColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.ios_share_rounded, size: 18),
            label: Text(
              'Paylaş',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: () => _copyComment(context, cleanedComment),
          style: OutlinedButton.styleFrom(
            backgroundColor: AppConstants.surfaceColor,
            foregroundColor: AppConstants.primaryColor,
            side: BorderSide(
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Icon(Icons.copy_rounded, size: 18),
        ),
      ],
    );
  }

  Future<void> _shareLog(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StoryShareScreen(
          log: widget.log,
          petName: widget.petName,
          userName: widget.userName,
          avatarUrl: widget.avatarUrl,
        ),
      ),
    );
  }

  Future<void> _copyComment(BuildContext context, String cleanedComment) async {
    await Clipboard.setData(ClipboardData(text: cleanedComment));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorum panoya kopyalandı ✨'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _HealthMetric {
  final String label;
  final int score;
  final String? note;
  final Color color;

  const _HealthMetric({
    required this.label,
    required this.score,
    required this.color,
    this.note,
  });
}
