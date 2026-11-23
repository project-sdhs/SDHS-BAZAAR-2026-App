import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../state/booth_list_logic.dart';
import '../../../components/basic/basic.dart';

/// `전체 · 1~3학년 · 특별부스` 칩 한 줄. 하나만 선택되며 선택은 부모가 들고 있습니다.
class BoothGradeFilterChips extends StatelessWidget {
  const BoothGradeFilterChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BoothGradeFilter value;
  final ValueChanged<BoothGradeFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: Row(
        spacing: AppSpacing.s8,
        children: [
          for (final filter in BoothGradeFilter.values)
            AppChip(
              filter.label,
              selected: filter == value,
              onSelected: (_) => onChanged(filter),
            ),
        ],
      ),
    );
  }
}
