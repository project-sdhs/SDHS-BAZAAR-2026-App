import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/booth.dart';
import '../../../data/models/popular_booth.dart';
import '../../../data/repositories/booth_repository.dart';
import '../../../state/recent_search_state.dart';
import '../../components/basic/basic.dart';
import '../../components/feedback/feedback.dart';
import 'widgets/booth_search_bar.dart';
import 'widgets/booth_search_result_row.dart';
import 'widgets/popular_searches_section.dart';
import 'widgets/recent_searches_section.dart';

/// 부스 검색 화면.
///
/// 검색어가 비어 있으면 최근 검색어(APP-39)와 실시간 인기 검색(APP-40)을,
/// 검색어를 입력하면 검색 결과(APP-38)를 보여 줍니다.
/// 검색은 서버(`GET /booths?q=`)가 하고, 글자를 칠 때마다 요청하지 않도록 잠깐 기다렸다 보냅니다.
class BoothSearchPage extends StatefulWidget {
  const BoothSearchPage({super.key});

  @override
  State<BoothSearchPage> createState() => _BoothSearchPageState();
}

class _BoothSearchPageState extends State<BoothSearchPage> {
  final _controller = TextEditingController();
  late Future<List<PopularBooth>> _popular;

  /// 지금 보여 주는 검색 결과 요청. 검색어를 입력하기 전에는 null.
  Future<List<Booth>>? _results;
  Timer? _debounce;

  /// 글자 입력이 멈춘 뒤 이만큼 기다렸다가 검색합니다.
  static const _debounceDelay = Duration(milliseconds: 350);

  /// 앱 전체에서 한 번만 만든 최근 검색어 (`AppProviders`). 화면을 닫아도 남습니다.
  RecentSearchState get _recent => context.read<RecentSearchState>();

  /// 서버 호출은 밖에서 받은 저장소로만 합니다 (`AppProviders`).
  BoothRepository get _repository => context.read<BoothRepository>();

  @override
  void initState() {
    super.initState();
    _popular = _fetchPopular();
    _controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  /// 입력이 바뀔 때마다 부릅니다. 멈춘 뒤에 한 번만 서버에 묻습니다.
  void _onQueryChanged(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = null;
      });
      return;
    }
    _debounce = Timer(_debounceDelay, () => _runSearch(query));
  }

  void _runSearch(String query) {
    if (!mounted) return;
    final request = _repository.booths(query: query);
    // 화면이 그리기 전에 실패해도 처리되지 않은 오류로 남지 않게 합니다(오류는 화면이 보여 줍니다).
    request.ignore();
    setState(() {
      _results = request;
    });
  }

  Future<List<PopularBooth>> _fetchPopular() => _repository.popularBooths();

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
    // 제출하면 기다리지 않고 바로 검색합니다.
    _debounce?.cancel();
    _runSearch(trimmed);
  }

  void _searchAgain(String keyword) {
    _controller.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    _search(keyword);
  }

  Widget _resultsBody() {
    final request = _results;
    if (request == null) return const _ResultSkeletons();
    return FutureBuilder<List<Booth>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppEmptyState(
            title: '검색 결과를 불러오지 못했어요',
            message: '잠시 뒤에 다시 시도해 주세요',
            icon: Icons.wifi_off,
            actionLabel: '다시 시도',
            onAction: () => _runSearch(_controller.text.trim()),
          );
        }
        final booths = snapshot.data;
        if (booths == null) return const _ResultSkeletons();
        return ListView(
          // Figma: 검색 바 아래 16 띄우고 검색 결과
          padding: const EdgeInsets.only(top: AppSpacing.s16),
          children: [
            BoothSearchResults(
              booths: booths,
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
              onChanged: _onQueryChanged,
              onSubmitted: _search,
              onCancel: _close,
            ),
            if (_controller.text.trim().isNotEmpty)
              Expanded(child: _resultsBody())
            else
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: AppSpacing.s16),
                  children: [
                    Consumer<RecentSearchState>(
                      builder: (context, recent, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          RecentSearchesSection(
                            keywords: recent.keywords,
                            onSelected: _searchAgain,
                            onRemoved: recent.remove,
                            onClearAll: recent.clear,
                          ),
                          // 구역 사이 32. 최근 검색어가 없으면 첫 구역이므로 넣지 않습니다.
                          if (recent.keywords.isNotEmpty)
                            const SizedBox(height: AppSpacing.s32),
                        ],
                      ),
                    ),
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
      child: Semantics(
        button: true,
        excludeSemantics: true,
        label: '인기 검색을 불러오지 못했어요. 눌러서 다시 시도해요',
        onTap: onRetry,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onRetry,
          child: Text(
            '인기 검색을 불러오지 못했어요. 눌러서 다시 시도해요',
            style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
          ),
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
      padding: const EdgeInsets.only(top: AppSpacing.s16),
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
