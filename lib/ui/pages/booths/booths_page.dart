import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/booth.dart';
import '../../../data/repositories/booth_repository.dart';
import '../../../state/booth_list_logic.dart';
import '../../components/basic/basic.dart';
import '../../components/feedback/feedback.dart';
import 'widgets/booth_grade_filter_chips.dart';
import 'widgets/booth_list_header.dart';
import 'widgets/booth_section_list.dart';
import 'widgets/booth_sort_control.dart';

/// 부스 목록 탭: 헤더 · 검색 진입 · 정렬 · 학년 필터 · 학년별 부스 카드 리스트.
///
/// 화면 전체가 한 번에 스크롤됩니다 (Figma). 서버 호출은 `AppProviders` 의 [BoothRepository] 로 합니다.
class BoothsPage extends StatefulWidget {
  const BoothsPage({super.key, this.loadBooths});

  /// 부스 전체를 정렬 기준대로 가져오는 함수. 없으면 서버(`GET /booths?sort=`)에서 가져옵니다.
  final Future<List<Booth>> Function(BoothSort sort)? loadBooths;

  @override
  State<BoothsPage> createState() => _BoothsPageState();
}

class _BoothsPageState extends State<BoothsPage> {
  BoothRepository get _repository => context.read<BoothRepository>();

  /// 정렬 기준마다 한 번만 가져옵니다 (인기 순은 서버가 정렬해 준 순서가 필요합니다).
  final Map<BoothSort, Future<List<Booth>>> _loads = {};

  BoothSort _sort = BoothSort.grade;
  BoothGradeFilter _filter = BoothGradeFilter.all;

  Future<List<Booth>> _loadFor(BoothSort sort) =>
      _loads.putIfAbsent(sort, () => (widget.loadBooths ?? _fetch)(sort));

  Future<List<Booth>> _fetch(BoothSort sort) =>
      _repository.booths(sort: sort.name);

  void _retry() {
    setState(() {
      _loads.remove(_sort);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Booth>>(
          future: _loadFor(_sort),
          builder: (context, snapshot) {
            final booths = snapshot.data;
            return ListView(
              children: [
                BoothListHeader(
                  openBoothCount: booths?.where((b) => b.isOpen).length,
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
                // Figma: 칩 줄 아래 24 띄우고 첫 학년 제목
                const SizedBox(height: AppSpacing.s24),
                _body(snapshot, booths),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(AsyncSnapshot<List<Booth>> snapshot, List<Booth>? booths) {
    if (snapshot.hasError) {
      return _Notice(
        AppEmptyState(
          title: '부스를 불러오지 못했어요',
          message: '잠시 뒤에 다시 시도해 주세요',
          icon: Icons.wifi_off,
          actionLabel: '다시 시도',
          onAction: _retry,
        ),
      );
    }
    if (booths == null) return const _LoadingCards();

    final sections = buildBoothSections(booths, sort: _sort, filter: _filter);
    if (sections.isEmpty) {
      return _Notice(
        AppEmptyState(
          title: '표시할 부스가 없어요',
          message: _filter == BoothGradeFilter.all
              ? '아직 등록된 부스가 없어요'
              : '${_filter.label}에는 표시할 부스가 없어요. 다른 칸을 골라 보세요',
        ),
      );
    }
    return BoothSectionList(
      sections: sections,
      imageUrlOf: (booth) => _repository.imageUrl(booth.imageUrl),
    );
  }
}

/// 안내 카드를 담는 영역. 화면이 작아도 넘치지 않습니다.
class _Notice extends StatelessWidget {
  const _Notice(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 300),
      child: child,
    );
  }
}

/// 불러오는 동안 보이는 카드 자리 표시 (카드와 같은 358 × 176 모양).
class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenHorizontal),
      child: Column(
        children: [
          AppSkeleton(height: 176, radius: 16),
          SizedBox(height: BoothSectionList.cardGap),
          AppSkeleton(height: 176, radius: 16),
        ],
      ),
    );
  }
}
