import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'map_marker_style.dart';
import 'map_search_bar.dart';

class MapGradeChips extends StatelessWidget {
  const MapGradeChips({
    super.key,
    required this.selectedGrade,
    required this.onChanged,
  });

  final int? selectedGrade;
  final ValueChanged<int?> onChanged;

  static const List<int?> grades = [null, 1, 2, 3];
  static const double height = 36;
  static const double horizontalPadding = 16;
  static const double radius = AppRadius.r10;
  static const double gap = AppSpacing.s6;

  static String labelOf(int? grade) => grade == null ? '전체' : '$grade학년';

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        spacing: gap,
        children: [
          for (final grade in grades)
            _GradeChip(
              label: labelOf(grade),
              selected: grade == selectedGrade,
              onTap: () => onChanged(grade),
            ),
        ],
      ),
    );
  }
}

class _GradeChip extends StatelessWidget {
  const _GradeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: MapGradeChips.height,
          padding: const EdgeInsets.symmetric(
            horizontal: MapGradeChips.horizontalPadding,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.foreground : AppColors.canvas,
            borderRadius: BorderRadius.circular(MapGradeChips.radius),
            boxShadow: MapMarkerStyle.shadow,
          ),
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 15,
              fontWeight: MapSearchBar.textWeight,
              color: selected ? AppColors.onPrimary : AppColors.body,
            ),
          ),
        ),
      ),
    );
  }
}
