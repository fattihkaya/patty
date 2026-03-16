import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pet_ai/core/constants.dart';
import 'package:pet_ai/core/app_strings.dart';

class FeatureComparisonWidget extends StatelessWidget {
  const FeatureComparisonWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);

    return Container(
      padding: const EdgeInsets.all(AppConstants.spacingLG),
      decoration: BoxDecoration(
        color: AppConstants.surfaceColor,
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 1,
        ),
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
          Text(
            s.languageCode == 'en'
                ? 'Feature Comparison'
                : 'Özellik Karşılaştırması',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppConstants.darkTextColor,
            ),
          ),
          const SizedBox(height: AppConstants.spacingLG),
          _buildComparisonTable(s),
        ],
      ),
    );
  }

  Widget _buildComparisonTable(S s) {
    final isEn = s.languageCode == 'en';

    final features = [
      _ComparisonFeature(
        isEn ? 'AI Analysis' : 'AI Analizi',
        isEn ? '3/mo' : '3/ay',
        isEn ? 'Unlimited' : 'Sınırsız',
      ),
      _ComparisonFeature(
        isEn ? 'Pet Profiles' : 'Pet Profili',
        '1',
        isEn ? 'Unlimited' : 'Sınırsız',
      ),
      _ComparisonFeature(
        isEn ? 'Statistics Charts' : 'İstatistik Grafikleri',
        '❌',
        '✅',
      ),
      _ComparisonFeature(
        isEn ? 'PDF Export' : 'PDF Dışa Aktarma',
        '❌',
        '✅',
      ),
      _ComparisonFeature(
        isEn ? 'AI Task Suggestions' : 'AI Görev Önerileri',
        '❌',
        '✅',
      ),
      _ComparisonFeature(
        isEn ? 'Family Members' : 'Aile Üyeleri',
        '❌',
        '✅',
      ),
      _ComparisonFeature(
        isEn ? 'Ad-Free' : 'Reklamsız',
        '❌',
        '✅',
      ),
      _ComparisonFeature(
        isEn ? 'Priority AI' : 'Öncelikli AI',
        '❌',
        '✅',
      ),
    ];

    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2.2),
        1: FlexColumnWidth(1),
        2: FlexColumnWidth(1.2),
      },
      children: [
        TableRow(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.white.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          children: [
            _buildTableHeader(isEn ? 'Feature' : 'Özellik'),
            _buildTableHeader(isEn ? 'Free' : 'Ücretsiz'),
            _buildTableHeader('Premium', isHighlighted: true),
          ],
        ),
        ...features.map((feature) => TableRow(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.04),
                    width: 0.5,
                  ),
                ),
              ),
              children: [
                _buildTableCell(feature.name, isHeader: true),
                _buildTableCell(feature.free),
                _buildTableCell(feature.premium, isHighlighted: true),
              ],
            )),
      ],
    );
  }

  Widget _buildTableHeader(String text, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isHighlighted
              ? AppConstants.primaryColor
              : AppConstants.darkTextColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTableCell(String text,
      {bool isHeader = false, bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: isHeader ? 13 : 12,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w500,
          color: isHighlighted
              ? AppConstants.primaryColor
              : isHeader
                  ? AppConstants.darkTextColor
                  : AppConstants.lightTextColor,
        ),
        textAlign: isHeader ? TextAlign.start : TextAlign.center,
      ),
    );
  }
}

class _ComparisonFeature {
  final String name;
  final String free;
  final String premium;

  _ComparisonFeature(this.name, this.free, this.premium);
}
