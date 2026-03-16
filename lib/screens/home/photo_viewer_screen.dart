import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';

class PhotoViewerScreen extends StatefulWidget {
  final String imageUrl;
  final String heroTag;
  final String? petName;
  final DateTime? date;

  const PhotoViewerScreen({
    super.key,
    required this.imageUrl,
    required this.heroTag,
    this.petName,
    this.date,
  });

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen> {
  final TransformationController _transformationController =
      TransformationController();
  bool _showControls = true;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
    setState(() => _showControls = true);
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: _toggleControls,
            onDoubleTap: _resetZoom,
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.5,
              maxScale: 4.0,
              onInteractionEnd: (details) {
                if (_transformationController.value.getMaxScaleOnAxis() <= 1.0) {
                  setState(() => _showControls = true);
                } else {
                  setState(() => _showControls = false);
                }
              },
              child: Hero(
                tag: widget.heroTag,
                child: Center(
                  child: Image.network(
                    widget.imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.black,
                        child: const Center(
                          child: Icon(Icons.error_outline,
                              color: Colors.white, size: 64),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.black,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_showControls) _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _buildAppBar(context),
          const Spacer(),
          if (widget.petName != null || widget.date != null)
            _buildMetadata(),
          _buildActionButtons(context),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            onPressed: () => _shareImage(context),
          ),
          IconButton(
            icon: const Icon(Icons.fullscreen_exit_rounded,
                color: Colors.white),
            onPressed: _resetZoom,
            tooltip: 'Zoom\'u sıfırla',
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.petName != null)
            Text(
              widget.petName!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          if (widget.date != null) ...[
            if (widget.petName != null) const SizedBox(height: 4),
            Text(
              DateFormat('dd MMMM yyyy', 'tr_TR').format(widget.date!),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.7),
            Colors.black.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _shareImage(context),
            backgroundColor: Colors.white.withValues(alpha: 0.9),
            icon: const Icon(Icons.share_rounded, color: AppConstants.primaryColor),
            label: Text(
              'Paylaş',
              style: GoogleFonts.plusJakartaSans(
                color: AppConstants.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareImage(BuildContext context) async {
    HapticFeedback.lightImpact();
    try {
      await Share.share(widget.imageUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paylaşım hatası: $e'),
            backgroundColor: AppConstants.errorColor,
          ),
        );
      }
    }
  }
}
