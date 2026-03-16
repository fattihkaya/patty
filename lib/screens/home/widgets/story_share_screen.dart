import 'dart:ui' as ui;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/core/app_strings.dart';
import 'package:pet_ai/models/log_model.dart';

class StoryShareScreen extends StatefulWidget {
  final LogModel log;
  final String? petName;
  final String? userName;
  final String? avatarUrl;

  const StoryShareScreen({
    super.key,
    required this.log,
    this.petName,
    this.userName,
    this.avatarUrl,
  });

  @override
  State<StoryShareScreen> createState() => _StoryShareScreenState();
}

class _StoryShareScreenState extends State<StoryShareScreen> {
  final GlobalKey _globalKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _shareStory() async {
    setState(() => _isExporting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 100));

      final RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final XFile xfile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'patty_story_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      await Share.shareXFiles([xfile], text: 'via Patty');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hazırlanırken hata oluştu: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppConstants.darkTextColor),
        title: Text(
          'Story Olarak Paylaş',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppConstants.darkTextColor,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: RepaintBoundary(
                      key: _globalKey,
                      child: _buildStoryContent(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppConstants.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppConstants.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: const Color(0xFF0F172A),
                  shadowColor: Colors.transparent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                onPressed: _isExporting ? null : _shareStory,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Color(0xFF0F172A), strokeWidth: 2),
                      )
                    : const Icon(Icons.share_rounded),
                label: Text(
                  _isExporting ? 'Hazırlanıyor...' : 'Uygulamalarla Paylaş',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoryContent() {
    final log = widget.log;
    final dateStr = DateFormat('dd MMM yyyy', 'tr_TR').format(log.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: NetworkImage(log.photoUrl),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black.withValues(alpha: 0.15),
                      BlendMode.darken,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    const Color(0xFF0F172A).withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.35, 1.0],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tarih badge üstte
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      dateStr,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Pet ismi + avatar
                  if (widget.petName != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppConstants.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: AppConstants.surfaceColor,
                            backgroundImage: widget.avatarUrl != null
                                ? NetworkImage(widget.avatarUrl!)
                                : null,
                            child: widget.avatarUrl == null
                                ? const Icon(Icons.pets,
                                    size: 16,
                                    color: AppConstants.primaryColor)
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.petName!,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Mood & Enerji chip'leri
                  if (log.moodScore != null || log.energyScore != null)
                    Row(
                      children: [
                        if (log.moodScore != null)
                          _buildGlassChip(
                            icon: Icons.auto_awesome_rounded,
                            label: 'Mood',
                            value: '${log.moodScore}/5',
                            color: AppConstants.accentColor,
                          ),
                        if (log.moodScore != null && log.energyScore != null)
                          const SizedBox(width: 8),
                        if (log.energyScore != null)
                          _buildGlassChip(
                            icon: Icons.bolt_rounded,
                            label: 'Enerji',
                            value: '${log.energyScore}/5',
                            color: AppConstants.primaryColor,
                          ),
                      ],
                    ),
                  const SizedBox(height: 14),

                  // Pet sesi / konuşma kartı (özelleştirilebilir etiket)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppConstants.surfaceColor.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppConstants.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppConstants.primaryColor
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                  Icons.pets_rounded,
                                  color: AppConstants.primaryColor,
                                  size: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              getPetVoiceLabel(context, widget.petName),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppConstants.primaryColor,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          log.petVoiceTr?.trim().isNotEmpty == true
                              ? '"${log.petVoiceTr!.trim()}"'
                              : (log.summaryTr?.trim().isNotEmpty == true
                                  ? log.summaryTr!.trim()
                                  : log.aiComment.trim()),
                          style: GoogleFonts.plusJakartaSans(
                            color: AppConstants.darkTextColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                          maxLines: 5,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

  Widget _buildGlassChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            '$label ',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
