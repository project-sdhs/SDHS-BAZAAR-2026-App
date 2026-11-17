import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../data/repositories/recent_search_store.dart';
import '../../../state/recent_search_state.dart';
import 'widgets/booth_search_bar.dart';
import 'widgets/recent_searches_section.dart';

/// 부스 검색 화면.
///
/// 검색어가 비어 있으면 최근 검색어(APP-39)를 보여 줍니다.
/// 인기 검색 · 검색 결과는 이후 티켓에서 붙입니다.
class BoothSearchPage extends StatefulWidget {
  const BoothSearchPage({super.key, this.recentSearches});

  /// 최근 검색어 상태. 없으면 앱을 끄면 사라지는 메모리 저장소를 씁니다.
  final RecentSearchState? recentSearches;

  @override
  State<BoothSearchPage> createState() => _BoothSearchPageState();
}

class _BoothSearchPageState extends State<BoothSearchPage> {
  final _controller = TextEditingController();
  late final RecentSearchState _recent;
  late final bool _ownsRecent;

  @override
  void initState() {
    super.initState();
    _ownsRecent = widget.recentSearches == null;
    _recent =
        widget.recentSearches ?? RecentSearchState(MemoryRecentSearchStore());
    _recent.load();
    _controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.dispose();
    if (_ownsRecent) _recent.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

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
                  padding: const EdgeInsets.only(top: 16),
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
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
