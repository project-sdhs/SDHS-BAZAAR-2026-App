import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/popular_booth.dart';
import '../../../data/repositories/booth_repository.dart';
import '../../../state/recent_search_state.dart';
import 'widgets/booth_search_bar.dart';
import 'widgets/popular_searches_section.dart';
import 'widgets/recent_searches_section.dart';

/// 부스 검색 화면.
///
/// 검색어가 비어 있으면 최근 검색어(APP-39)와 실시간 인기 검색(APP-40)을 보여 줍니다.
/// 검색 결과는 이후 티켓에서 붙입니다.
class BoothSearchPage extends StatefulWidget {
  const BoothSearchPage({super.key});

  @override
  State<BoothSearchPage> createState() => _BoothSearchPageState();
}

class _BoothSearchPageState extends State<BoothSearchPage> {
  final _controller = TextEditingController();
  late Future<List<PopularBooth>> _popular;

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
    _controller.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

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
    // 검색 결과는 이후 티켓에서 연결합니다.
  }

  void _searchAgain(String keyword) {
    _controller.value = TextEditingValue(
      text: keyword,
      selection: TextSelection.collapsed(offset: keyword.length),
    );
    _search(keyword);
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
            if (_controller.text.trim().isEmpty)
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
