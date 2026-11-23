import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../state/booth_list_logic.dart';
import 'widgets/booth_grade_filter_chips.dart';
import 'widgets/booth_list_header.dart';
import 'widgets/booth_sort_control.dart';

/// 부스 목록 탭. 부스 카드 리스트는 이후 티켓에서 붙입니다.
class BoothsPage extends StatefulWidget {
  const BoothsPage({super.key});

  @override
  State<BoothsPage> createState() => _BoothsPageState();
}

class _BoothsPageState extends State<BoothsPage> {
  BoothSort _sort = BoothSort.grade;
  BoothGradeFilter _filter = BoothGradeFilter.all;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoothListHeader(
              onSearchTap: () => context.push(Routes.boothSearch),
            ),
            const SizedBox(height: AppSpacing.s16),
            BoothSortControl(
              value: _sort,
              onChanged: (sort) => setState(() => _sort = sort),
            ),
            const SizedBox(height: AppSpacing.s16),
            BoothGradeFilterChips(
              value: _filter,
              onChanged: (filter) => setState(() => _filter = filter),
            ),
          ],
        ),
      ),
    );
  }
}
