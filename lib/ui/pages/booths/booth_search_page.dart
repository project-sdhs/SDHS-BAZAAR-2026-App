import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/booth.dart';
import '../../../data/models/popular_booth.dart';
import '../../../data/repositories/booth_repository.dart';
import '../../../data/repositories/recent_search_store.dart';
import '../../../state/booth_list_logic.dart';
import '../../../state/recent_search_state.dart';
import '../../components/basic/basic.dart';
import '../../components/feedback/feedback.dart';
import 'widgets/booth_search_bar.dart';
import 'widgets/booth_search_result_row.dart';
import 'widgets/popular_searches_section.dart';
import 'widgets/recent_searches_section.dart';

/// 부스 검색 화면.
///
/// 검색어가 비어 있으면 최근 검색어(APP-39)와 실시간 인기 검색(APP-40)을 보여 줍니다.
/// 검색 결과(APP-38)는 BoothView 가 들어온 뒤 붙입니다.
class BoothSearchPage extends StatefulWidget {
  const BoothSearchPage({
    super.key,
    this.recentSearches,
    this.loadPopularBooths,
    this.loadBooths,
  });

  /// 최근 검색어 상태. 없으면 앱을 끄면 사라지는 메모리 저장소를 씁니다.
  final RecentSearchState? recentSearches;

  /// 인기 부스를 가져오는 함수. 없으면 서버(`GET /booths/popular`)에서 가져옵니다.
  final Future<List<PopularBooth>> Function()? loadPopularBooths;

  /// 검색 대상인 부스 전체를 가져오는 함수. 없으면 서버(`GET /booths`)에서 가져옵니다.
  final Future<List<Booth>> Function()? loadBooths;

  @override
  State<BoothSearchPage> createState() => _BoothSearchPageState();
}

class _BoothSearchPageState extends State<BoothSearchPage> {
  final _controller = TextEditingController();
  late final RecentSearchState _recent;
  late final bool _ownsRecent;
  late final BoothRepository _repository = BoothRepository(ApiClient());
  late Future<List<PopularBooth>> _popular;
  // 검색어를 처음 입력할 때 불러옵니다. 미리 불러 두면 실패했을 때 받는 곳이 없어요.
  Future<List<Booth>>? _booths;

  @override
  void initState() {
    super.initState();
    _ownsRecent = widget.recentSearches == null;
    _recent =
        widget.recentSearches ?? RecentSearchState(MemoryRecentSearchStore());
    _recent.load();
    _popular = _fetchPopular();
    _controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_ownsRecent) _recent.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  Future<List<PopularBooth>> _fetchPopular() {
    final loader = widget.loadPopularBooths;
    if (loader != null) return loader();
    return _repository.popularBooths();
  }

  Future<List<Booth>> _fetchBooths() {
    final loader = widget.loadBooths;
    if (loader != null) return loader();
    return _repository.booths();
  }

  void _retryBooths() {
    setState(() {
      _booths = _fetchBooths();
    });
  }

  void _retryPopular() {
    setState(() {
      _popular = _fetchPopular();
    });
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.booths);
    }
  }

  void _search(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    _recent.add(trimmed);
    // 검색 결과는 APP-38 에서 연결합니다.
  }

  void _searchAgain(String keyword) {
    _controller.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    _search(keyword);
  }

  Widget _results(String query) {
    return FutureBuilder<List<Booth>>(
      future: _booths ??= _fetchBooths(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppEmptyState(
            title: '검색할 부스를 불러오지 못했어요',
            message: '잠시 뒤에 다시 시도해 주세요',
            icon: Icons.wifi_off,
            actionLabel: '다시 시도',
            onAction: _retryBooths,
          );
        }
        final booths = snapshot.data;
        if (booths == null) return const _ResultSkeletons();
        return ListView(
          children: [
            BoothSearchResults(
              booths: searchBooths(booths, query),
              imageUrlOf: (booth) => _repository.imageUrl(booth.imageUrl),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoothSearchBar(
              controller: _controller,
              onChanged: (_) {},
              onSubmitted: _search,
              onCancel: _close,
            ),
            if (_controller.text.trim().isNotEmpty)
              Expanded(child: _results(_controller.text))
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: AppSpacing.s16),
                  children: [
                    ListenableBuilder(
                      listenable: _recent,
                      builder: (context, _) => RecentSearchesSection(
                        keywords: _recent.keywords,
                        onSelected: _searchAgain,
                        onRemoved: _recent.remove,
                        onClearAll: _recent.clear,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s32),
                    FutureBuilder<List<PopularBooth>>(
                      future: _popular,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _PopularError(onRetry: _retryPopular);
                        }
                        return PopularSearchesSection(
                          booths: snapshot.data ?? const [],
                          onSelected: (booth) => _searchAgain(booth.name),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PopularError extends StatelessWidget {
  const _PopularError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontal,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onRetry,
        child: Text(
          '인기 검색을 불러오지 못했어요. 눌러서 다시 시도해요',
          style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}

/// 검색 결과를 불러오는 동안 보이는 행 자리 표시 (결과 행과 같은 높이 80).
class _ResultSkeletons extends StatelessWidget {
  const _ResultSkeletons();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        3,
        (_) => const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: 12,
          ),
          child: Row(
            spacing: AppSpacing.s16,
            children: [
              AppSkeleton(width: 56, height: 56, radius: AppRadius.r14),
              Expanded(child: AppSkeleton(height: 40, radius: 8)),
            ],
          ),
        ),
      ),
    );
  }
}
