import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/models/pet_model.dart';
import 'package:pet_ai/models/log_model.dart';
import 'package:pet_ai/screens/home/widgets/timeline_item.dart';
import 'package:flutter_animate/flutter_animate.dart';

class PetCalendarView extends StatefulWidget {
  final PetModel pet;
  final List<LogModel> logs;

  const PetCalendarView({
    super.key,
    required this.pet,
    required this.logs,
  });

  @override
  State<PetCalendarView> createState() => _PetCalendarViewState();
}

class _PetCalendarViewState extends State<PetCalendarView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<LogModel> _getLogsForDay(DateTime day) {
    return widget.logs.where((log) {
      return log.createdAt.year == day.year &&
          log.createdAt.month == day.month &&
          log.createdAt.day == day.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDayLogs =
        _selectedDay != null ? _getLogsForDay(_selectedDay!) : [];

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: TableCalendar(
            firstDay: DateTime.now().subtract(const Duration(days: 365 * 2)),
            lastDay: DateTime.now().add(const Duration(days: 30)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            locale: 'tr_TR',
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.darkTextColor,
              ),
              leftChevronIcon: const Icon(Icons.chevron_left_rounded,
                  color: AppConstants.primaryColor),
              rightChevronIcon: const Icon(Icons.chevron_right_rounded,
                  color: AppConstants.primaryColor),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: AppConstants.primaryLight.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                  color: AppConstants.primaryColor,
                  fontWeight: FontWeight.bold),
              selectedDecoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: AppConstants.secondaryColor,
                shape: BoxShape.circle,
              ),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                final dayLogs = _getLogsForDay(date);
                if (dayLogs.isNotEmpty) {
                  return Positioned(
                    bottom: 1,
                    child: Icon(
                      Icons.pets_rounded,
                      size: 10,
                      color: AppConstants.secondaryColor.withValues(alpha: 0.8),
                    ),
                  );
                }
                return null;
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: selectedDayLogs.isNotEmpty
              ? Container(
                  key: ValueKey('logs_${_selectedDay?.toIso8601String()}'),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'O Günün Anıları',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppConstants.darkTextColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...selectedDayLogs.map((log) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: TimelineItem(
                              log: log,
                              isLast: true,
                              petName: widget.pet.name,
                              avatarUrl: widget.pet.photoUrl,
                            )
                                .animate()
                                .fadeIn(delay: Duration(milliseconds: selectedDayLogs.indexOf(log) * 100))
                                .slideY(begin: 0.1, end: 0),
                          )),
                    ],
                  ),
                )
              : _selectedDay != null
                  ? Container(
                      key: const ValueKey('empty'),
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 40,
                              color: AppConstants.lightTextColor.withValues(alpha: 0.3))
                              .animate()
                              .fadeIn(delay: const Duration(milliseconds: 200)),
                          const SizedBox(height: 12),
                          Text(
                            'Bu tarihte kayıtlı bir anı yok.',
                            style: GoogleFonts.plusJakartaSans(color: AppConstants.lightTextColor),
                          ).animate().fadeIn(delay: const Duration(milliseconds: 300)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
