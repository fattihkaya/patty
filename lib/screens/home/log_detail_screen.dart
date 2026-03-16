import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/app_strings.dart';
import '../../core/health_parameters.dart';
import '../../models/log_model.dart';
import '../../models/pet_model.dart';
import '../../models/condition_model.dart';
import '../../providers/pet_provider.dart';
import 'photo_viewer_screen.dart';
import 'widgets/comment_section_widget.dart';

class LogDetailScreen extends StatelessWidget {
  final LogModel log;
  final PetModel pet;

  const LogDetailScreen({
    super.key,
    required this.log,
    required this.pet,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPhotoSection(context),
                _buildAIAnalysisSection(context),
                _buildHealthParametersSection(),
                _buildConditionsSection(),
                _buildRelatedLogsSection(context),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: CommentSectionWidget(logId: log.id),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 100,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
        color: AppConstants.primaryColor,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: () => _shareLog(context),
          color: AppConstants.primaryColor,
        ),
        PopupMenuButton(
          icon: const Icon(Icons.more_vert_rounded),
        color: AppConstants.surfaceColor,
      itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: AppConstants.errorColor),
                  SizedBox(width: 8),
                  Text('Sil'),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'delete') {
              _showDeleteDialog(context);
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildPhotoSection(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoViewerScreen(
              imageUrl: log.photoUrl,
              heroTag: log.id,
            ),
          ),
        );
      },
      child: Hero(
        tag: log.id,
        child: Container(
          width: double.infinity,
          height: 400,
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            boxShadow: AppConstants.cardShadow,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
            child: Image.network(
              log.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppConstants.mutedColor,
                  child: const Icon(Icons.error_outline, size: 48),
                );
              },
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildAIAnalysisSection(BuildContext context) {
    final petVoiceLabel = getPetVoiceLabel(context, pet.name);
    final hasPetVoice =
        log.petVoiceTr != null && log.petVoiceTr!.trim().isNotEmpty;
    final hasOther =
        (log.summaryTr != null && log.summaryTr!.trim().isNotEmpty) ||
        (log.careTipTr != null && log.careTipTr!.trim().isNotEmpty) ||
        log.moodLabel != null ||
        log.moodScore != null;
    final sectionTitle = hasPetVoice
        ? petVoiceLabel
        : (hasOther ? S.of(context).aiAnalysis : null);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sectionTitle != null)
            Text(
              sectionTitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppConstants.primaryColor,
                letterSpacing: AppConstants.letterSpacingBold,
              ),
            ),
          if (sectionTitle != null) const SizedBox(height: 16),
          if (hasPetVoice) _buildPetVoiceOnlyCard(log.petVoiceTr!),
          if (hasPetVoice) const SizedBox(height: 12),
          if (log.summaryTr != null && log.summaryTr!.trim().isNotEmpty)
            _buildAnalysisCard(
              icon: Icons.summarize_rounded,
              title: 'Özet',
              content: log.summaryTr!,
              color: AppConstants.accentColor,
            ),
          if (log.careTipTr != null && log.careTipTr!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildAnalysisCard(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Bakım Önerisi',
              content: log.careTipTr!,
              color: AppConstants.accentColor,
            ),
          ],
          if (log.moodLabel != null || log.moodScore != null) ...[
            const SizedBox(height: 12),
            _buildMoodEnergyCard(),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPetVoiceOnlyCard(String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppConstants.primaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.pets_rounded,
              color: AppConstants.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                height: 1.6,
                color: AppConstants.darkTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisCard({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppConstants.darkTextColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.6,
              color: AppConstants.darkTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodEnergyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppConstants.modernGradient,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        boxShadow: AppConstants.elevatedShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if (log.moodLabel != null || log.moodScore != null)
            _buildMetricItem(
              label: 'Mood',
              value: log.moodLabel ?? '${log.moodScore}/5',
              icon: Icons.auto_awesome_rounded,
            ),
          if (log.energyScore != null)
            _buildMetricItem(
              label: 'Enerji',
              value: '${log.energyScore}/5',
              icon: Icons.bolt_rounded,
            ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthParametersSection() {
    final parameters = kHealthParameters
        .where((param) => log.scoreFor(param.key) != null)
        .toList();

    if (parameters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sağlık Parametreleri',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppConstants.primaryColor,
              letterSpacing: AppConstants.letterSpacingBold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: parameters.length,
            itemBuilder: (context, index) {
              final param = parameters[index];
              final score = log.scoreFor(param.key);
              final note = log.noteFor(param.key);
              return _buildParameterCard(param, score, note);
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildParameterCard(
    HealthParameterDescriptor param,
    int? score,
    String? note,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
        boxShadow: AppConstants.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                param.shortLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: param.color,
                ),
              ),
              if (score != null)
                Text(
                  '$score/5',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: param.color,
                  ),
                ),
            ],
          ),
          if (score != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score / 5,
                minHeight: 6,
                backgroundColor: param.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(param.color),
              ),
            ),
          ],
          if (note != null && note.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.4,
                color: AppConstants.lightTextColor,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConditionsSection() {
    final allConditions = [
      ...log.confirmedConditions,
      ...log.aiConditions,
    ];

    if (allConditions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sağlık Durumları',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppConstants.primaryColor,
              letterSpacing: AppConstants.letterSpacingBold,
            ),
          ),
          const SizedBox(height: 16),
          ...allConditions.map((condition) => _buildConditionCard(condition)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildConditionCard(ConditionModel condition) {
    final isConfirmed = log.confirmedConditions.any((c) => c.label == condition.label);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        boxShadow: AppConstants.cardShadow,
        border: Border.all(
          color: isConfirmed
              ? AppConstants.successColor.withValues(alpha: 0.3)
              : AppConstants.accentColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isConfirmed ? Icons.check_circle : Icons.info_outline_rounded,
            color: isConfirmed
                ? AppConstants.successColor
                : AppConstants.accentColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  condition.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppConstants.darkTextColor,
                  ),
                ),
                if (condition.note != null && condition.note!.trim().isNotEmpty)
                  Text(
                    condition.note!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: AppConstants.lightTextColor,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelatedLogsSection(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final relatedLogs = petProvider
        .getLogsForPet(pet.id)
        .where((l) => l.id != log.id)
        .take(3)
        .toList();

    if (relatedLogs.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'İlgili Kayıtlar',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppConstants.primaryColor,
              letterSpacing: AppConstants.letterSpacingBold,
            ),
          ),
          const SizedBox(height: 16),
          ...relatedLogs.map((relatedLog) => _buildRelatedLogCard(
                context,
                relatedLog,
              )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildRelatedLogCard(BuildContext context, LogModel relatedLog) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LogDetailScreen(log: relatedLog, pet: pet),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
          boxShadow: AppConstants.cardShadow,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                relatedLog.photoUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 60,
                    height: 60,
                    color: AppConstants.mutedColor,
                    child: const Icon(Icons.image),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('dd MMMM yyyy', 'tr_TR').format(relatedLog.createdAt),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppConstants.darkTextColor,
                    ),
                  ),
                  if (relatedLog.summaryTr != null &&
                      relatedLog.summaryTr!.trim().isNotEmpty)
                    Text(
                      relatedLog.summaryTr!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: AppConstants.lightTextColor,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppConstants.lightTextColor),
          ],
        ),
      ),
    );
  }

  Future<void> _shareLog(BuildContext context) async {
    final formattedDate =
        DateFormat('dd MMMM yyyy', 'tr_TR').format(log.createdAt);
    final buffer = StringBuffer()
      ..writeln('🐾 $formattedDate tarihli Patty kaydı')
      ..writeln('Pet: ${pet.name}')
      ..writeln()
      ..writeln('Mood: ${log.moodLabel ?? "Bilinmiyor"}'
          '${log.moodScore != null ? " (${log.moodScore}/5)" : ""}')
      ..writeln(
          'Enerji: ${log.energyScore != null ? "${log.energyScore}/5" : "Bilinmiyor"}')
      ..writeln()
      ..writeln(log.summaryTr ?? log.aiComment)
      ..writeln();
    if (kHealthParameters.any((param) => log.scoreFor(param.key) != null)) {
      buffer.writeln('🩺 Sağlık Notları:');
      for (final param in kHealthParameters) {
        final score = log.scoreFor(param.key);
        final note = log.noteFor(param.key);
        if (score != null) {
          buffer.writeln(
              '- ${param.shortLabel}: $score/5${note != null ? ' $note' : ''}'.trim());
        }
      }
      buffer.writeln();
    }
    if (log.careTipTr != null) {
      buffer
        ..writeln('💡 Öneri: ${log.careTipTr}')
        ..writeln();
    }
    if (log.petVoiceTr != null) {
      buffer
        ..writeln('🐶 ${log.petVoiceTr}')
        ..writeln();
    }
    buffer.writeln('Fotoğraf: ${log.photoUrl}');

    await Share.share(buffer.toString().trim());
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Kaydı Sil',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Bu kaydı silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<PetProvider>().deleteLog(log.id, pet.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kayıt başarıyla silindi'),
                      backgroundColor: AppConstants.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Silme işlemi başarısız: $e'),
                      backgroundColor: AppConstants.errorColor,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: AppConstants.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}
