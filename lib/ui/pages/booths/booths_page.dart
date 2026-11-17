import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/booth.dart';
import '../../../data/models/popular_booth.dart';
import '../../../data/repositories/booth_repository.dart';
import '../../../state/booth_list_logic.dart';
import '../../components/basic/basic.dart';
import '../../components/feedback/feedback.dart';
import 'widgets/booth_grade_filter_chips.dart';
import 'widgets/booth_list_header.dart';
import 'widgets/booth_section_list.dart';
import 'widgets/booth_sort_control.dart';

/// 부스 목록 탭: 헤더 · 검색 진입 · 정렬 · 학년 필터 · 학년별 부스 카드 리스트.
class BoothsPage extends StatefulWidget {
  const BoothsPage({super.key, this.loadBooths, this.loadPopularBooths});

  /// 부스 전체를 가져오는 함수. 없으면 서버(`GET /booths`)에서 가져옵니다.
  final Future<List<Booth>> Function()? loadBooths;

  /// 인기 부스(인기 순 정렬에 씀)를 가져오는 함수. 없으면 서버에서 가져옵니다.
  ///
  /// 가져오지 못해도 목록은 보여 주고, 인기 순은 이름 순으로 대신합니다.
  final Future<List<PopularBooth>> Function()? loadPopularBooths;

  @override
  State<BoothsPage> createState() => _BoothsPageState();
}

class _BoothsPageState extends State<BoothsPage> {
  late final BoothRepository _repository = BoothRepository(ApiClient());
  late Future<_BoothListData> _data = _load();

  BoothSort _sort = BoothSort.grade;
  BoothGradeFilter _filter = BoothGradeFilter.all;

  Future<_BoothListData> _load() async {
    final booths = await (widget.loadBooths ?? _repository.booths)();
    List<PopularBooth> popular;
    try {
      popular = await (widget.loadPopularBooths ?? _repository.popularBooths)();
    } on Object {
      popular = const [];
    }
    return _BoothListData(booths, popular);
  }

  void _retry() {
    setState(() {
      _data = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<_BoothListData>(
          future: _data,
          builder: (context, snapshot) {
            final data = snapshot.data;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BoothListHeader(
                  openBoothCount: data?.booths.where((b) => b.isOpen).length,
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
                const SizedBox(height: AppSpacing.s16),
                Expanded(child: _body(snapshot, data)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(AsyncSnapshot<_BoothListData> snapshot, _BoothListData? data) {
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
    if (data == null) return const _LoadingCards();

    final sections = buildBoothSections(
      data.booths,
      sort: _sort,
      filter: _filter,
      popular: data.popular,
    );
    if (sections.isEmpty) {
      return const _Notice(
        AppEmptyState(title: '표시할 부스가 없어요', message: '다른 학년을 골라 보세요'),
      );
    }
    return ListView(
      children: [
        BoothSectionList(
          sections: sections,
          imageUrlOf: (booth) => _repository.imageUrl(booth.imageUrl),
        ),
      ],
    );
  }
}

/// 안내 카드를 담는 스크롤 영역. 화면이 작아도 넘치지 않고 스크롤됩니다.
class _Notice extends StatelessWidget {
  const _Notice(this.child);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 300),
          child: child,
        ),
      ],
    );
  }
}

class _BoothListData {
  const _BoothListData(this.booths, this.popular);

  final List<Booth> booths;
  final List<PopularBooth> popular;
}

/// 불러오는 동안 보이는 카드 자리 표시 (카드와 같은 358 × 176 모양).
class _LoadingCards extends StatelessWidget {
  const _LoadingCards();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      children: const [
        AppSkeleton(height: 176, radius: 16),
        SizedBox(height: BoothSectionList.cardGap),
        AppSkeleton(height: 176, radius: 16),
      ],
    );
  }
}
