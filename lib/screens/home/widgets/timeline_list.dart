import 'package:flutter/material.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/models/log_model.dart';
import 'package:pet_ai/models/pet_model.dart';
import 'timeline_item.dart';

class TimelineList extends StatelessWidget {
  final PetModel pet;
  final List<LogModel> logs;
  final ScrollController? scrollController;
  final VoidCallback? onAddLog;
  final bool showAnalysis;

  const TimelineList({
    super.key,
    required this.pet,
    required this.logs,
    this.scrollController,
    this.onAddLog,
    this.showAnalysis = false,
  });

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      controller: scrollController,
      shrinkWrap: true,
      physics:
          const NeverScrollableScrollPhysics(), // Since it's inside CustomScrollView in HomeScreen
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return TimelineItem(
          log: logs[index],
          isLast: index == logs.length - 1,
          petName: pet.name,
          avatarUrl: pet.photoUrl,
          showAnalysis: showAnalysis,
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppConstants.surfaceColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 30,
              offset: const Offset(0, 16),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 32,
              backgroundColor: AppConstants.primaryLight,
              child: Icon(Icons.auto_stories_rounded,
                  size: 32, color: AppConstants.primaryColor),
            ),
            const SizedBox(height: 24),
            Text(
              '${pet.name} için henüz bir anı yok',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppConstants.darkTextColor,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Alt kısımdaki + butonuna dokunarak ilk fotoğrafını yükle ve AI yorumunu gör.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppConstants.lightTextColor,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAddLog,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Anı ekle'),
            ),
          ],
        ),
      ),
    );
  }
}
