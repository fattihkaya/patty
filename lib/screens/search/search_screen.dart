import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/health_parameters.dart';
import '../../models/log_model.dart';
import '../../models/pet_model.dart';
import '../../providers/pet_provider.dart';
import '../home/log_detail_screen.dart';
import '../home/widgets/timeline_item.dart';

enum SortOption { dateDesc, dateAsc, scoreDesc, scoreAsc }
enum QuickFilter { all, week, month, threeMonths }

class SearchScreen extends StatefulWidget {
  final PetModel? pet;

  const SearchScreen({super.key, this.pet});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  SortOption _sortOption = SortOption.dateDesc;
  QuickFilter _quickFilter = QuickFilter.all;
  String? _selectedParameter;
  DateTimeRange? _dateRange;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<LogModel> _filterLogs(List<LogModel> logs) {
    var filtered = List<LogModel>.from(logs);

    // Search by keyword
    if (_searchController.text.trim().isNotEmpty) {
      final keyword = _searchController.text.trim().toLowerCase();
      filtered = filtered.where((log) {
        final summary = log.summaryTr?.toLowerCase() ?? '';
        final careTip = log.careTipTr?.toLowerCase() ?? '';
        final petVoice = log.petVoiceTr?.toLowerCase() ?? '';
        final healthNote = log.healthNote?.toLowerCase() ?? '';
        return summary.contains(keyword) ||
            careTip.contains(keyword) ||
            petVoice.contains(keyword) ||
            healthNote.contains(keyword);
      }).toList();
    }

    // Quick filter by date
    switch (_quickFilter) {
      case QuickFilter.week:
        final weekAgo = DateTime.now().subtract(const Duration(days: 7));
        filtered = filtered
            .where((log) => log.createdAt.isAfter(weekAgo))
            .toList();
        break;
      case QuickFilter.month:
        final monthAgo = DateTime.now().subtract(const Duration(days: 30));
        filtered = filtered
            .where((log) => log.createdAt.isAfter(monthAgo))
            .toList();
        break;
      case QuickFilter.threeMonths:
        final threeMonthsAgo = DateTime.now().subtract(const Duration(days: 90));
        filtered = filtered
            .where((log) => log.createdAt.isAfter(threeMonthsAgo))
            .toList();
        break;
      case QuickFilter.all:
        break;
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((log) {
        return log.createdAt.isAfter(_dateRange!.start) &&
            log.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Parameter filter
    if (_selectedParameter != null) {
      filtered = filtered
          .where((log) => log.scoreFor(_selectedParameter!) != null)
          .toList();
    }

    // Sort
    switch (_sortOption) {
      case SortOption.dateDesc:
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.dateAsc:
        filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case SortOption.scoreDesc:
        filtered.sort((a, b) {
          final aScore = a.moodScore ?? 0;
          final bScore = b.moodScore ?? 0;
          return bScore.compareTo(aScore);
        });
        break;
      case SortOption.scoreAsc:
        filtered.sort((a, b) {
          final aScore = a.moodScore ?? 0;
          final bScore = b.moodScore ?? 0;
          return aScore.compareTo(bScore);
        });
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();
    final pet = widget.pet ?? petProvider.selectedPet;
    final allLogs = pet != null ? petProvider.getLogsForPet(pet.id) : <LogModel>[];
    final filteredLogs = _filterLogs(allLogs);

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Ara',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppConstants.primaryColor,
            letterSpacing: AppConstants.letterSpacingBold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilters(),
          Expanded(
            child: filteredLogs.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(filteredLogs, pet),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: TextField(
        controller: _searchController,
        style: GoogleFonts.plusJakartaSans(color: AppConstants.darkTextColor),
        decoration: InputDecoration(
          hintText: 'Ara... (özet, bakım önerisi, notlar)',
          hintStyle: GoogleFonts.plusJakartaSans(color: AppConstants.lightTextColor),
          prefixIcon: const Icon(Icons.search_rounded, color: AppConstants.lightTextColor),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: AppConstants.lightTextColor),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: AppConstants.backgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (value) => setState(() {}),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingLG,
        vertical: AppConstants.spacingMD,
      ),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildQuickFilters(),
              ),
              const SizedBox(width: 12),
              _buildSortButton(),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildParameterFilter(),
              ),
              const SizedBox(width: 12),
              _buildDateRangeButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildQuickFilterChip('Tümü', QuickFilter.all),
          const SizedBox(width: 8),
          _buildQuickFilterChip('Son Hafta', QuickFilter.week),
          const SizedBox(width: 8),
          _buildQuickFilterChip('Son Ay', QuickFilter.month),
          const SizedBox(width: 8),
          _buildQuickFilterChip('Son 3 Ay', QuickFilter.threeMonths),
        ],
      ),
    );
  }

  Widget _buildQuickFilterChip(String label, QuickFilter filter) {
    final isSelected = _quickFilter == filter;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        HapticFeedback.lightImpact();
        setState(() => _quickFilter = filter);
      },
      selectedColor: AppConstants.primaryColor.withValues(alpha: 0.2),
      checkmarkColor: AppConstants.primaryColor,
      labelStyle: GoogleFonts.plusJakartaSans(
        color: isSelected ? AppConstants.primaryColor : AppConstants.darkTextColor,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  Widget _buildSortButton() {
    return PopupMenuButton<SortOption>(
      icon: const Icon(Icons.sort_rounded),
      onSelected: (option) {
        HapticFeedback.lightImpact();
        setState(() => _sortOption = option);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: SortOption.dateDesc,
          child: Text('Tarihe Göre (Yeni)'),
        ),
        const PopupMenuItem(
          value: SortOption.dateAsc,
          child: Text('Tarihe Göre (Eski)'),
        ),
        const PopupMenuItem(
          value: SortOption.scoreDesc,
          child: Text('Skora Göre (Yüksek)'),
        ),
        const PopupMenuItem(
          value: SortOption.scoreAsc,
          child: Text('Skora Göre (Düşük)'),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppConstants.primaryLight,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.sort_rounded, size: 18, color: AppConstants.primaryColor),
            const SizedBox(width: 4),
            Text(
              'Sırala',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterFilter() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.filter_list_rounded),
      onSelected: (param) {
        HapticFeedback.lightImpact();
        setState(() => _selectedParameter = param);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: null,
          child: Text('Tüm Parametreler'),
        ),
        const PopupMenuDivider(),
        ...kHealthParameters.map(
          (param) => PopupMenuItem(
            value: param.key,
            child: Text(param.label),
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _selectedParameter != null
              ? AppConstants.primaryColor.withValues(alpha: 0.2)
              : AppConstants.primaryLight,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list_rounded,
              size: 18,
              color: _selectedParameter != null
                  ? AppConstants.primaryColor
                  : AppConstants.primaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              _selectedParameter != null
                  ? kHealthParameters
                      .firstWhere((p) => p.key == _selectedParameter)
                      .shortLabel
                  : 'Filtrele',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
            if (_selectedParameter != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedParameter = null);
                },
                child: const Icon(Icons.close, size: 16, color: AppConstants.primaryColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeButton() {
    return OutlinedButton.icon(
      onPressed: () async {
        HapticFeedback.lightImpact();
        final range = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          initialDateRange: _dateRange,
          locale: const Locale('tr', 'TR'),
        );
        if (range != null) {
          setState(() => _dateRange = range);
        }
      },
      icon: const Icon(Icons.calendar_today_rounded, size: 18),
      label: Text(
        _dateRange != null
            ? '${DateFormat('dd MMM', 'tr_TR').format(_dateRange!.start)} - ${DateFormat('dd MMM', 'tr_TR').format(_dateRange!.end)}'
            : 'Tarih Aralığı',
        style: GoogleFonts.plusJakartaSans(fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.spacingXXL),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 80,
              color: AppConstants.lightTextColor.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Sonuç bulunamadı',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppConstants.darkTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir arama terimi veya filtre deneyin',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: AppConstants.lightTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLogDetail(LogModel log, PetModel pet) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LogDetailScreen(
          log: log,
          pet: pet,
        ),
      ),
    );
  }

  Widget _buildResultsList(List<LogModel> logs, PetModel? pet) {
    if (pet == null) {
      return const Center(child: Text('Pet seçilmedi'));
    }

    return ListView.separated(
      padding: AppConstants.screenPaddingMobile,
      itemCount: logs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final log = logs[index];
        return InkWell(
          onTap: () => _openLogDetail(log, pet),
          borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
          child: Container(
            decoration: AppConstants.cardDecoration,
            child: TimelineItem(
              log: log,
              isLast: index == logs.length - 1,
              petName: pet.name,
              avatarUrl: pet.photoUrl,
            ),
          ),
        );
      },
    );
  }
}
