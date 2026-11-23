import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../state/booth_list_logic.dart';
import '../../../components/basic/basic.dart';

/// `학년 순 / 인기 순` 을 고르는 조절 막대. 선택한 값은 부모가 들고 있습니다.
class BoothSortControl extends StatelessWidget {
  const BoothSortControl({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BoothSort value;
  final ValueChanged<BoothSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: AppSegmentedControl<BoothSort>(
        items: {for (final sort in BoothSort.values) sort: sort.label},
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
