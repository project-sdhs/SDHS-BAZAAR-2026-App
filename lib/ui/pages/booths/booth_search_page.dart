import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../state/recent_search_state.dart';
import 'widgets/booth_search_bar.dart';
import 'widgets/recent_searches_section.dart';

/// 부스 검색 화면.
///
/// 검색어가 비어 있으면 최근 검색어(APP-39)를 보여 줍니다.
/// 인기 검색 · 검색 결과는 이후 티켓에서 붙입니다.
class BoothSearchPage extends StatefulWidget {
  const BoothSearchPage({super.key});

  @override
  State<BoothSearchPage> createState() => _BoothSearchPageState();
}

class _BoothSearchPageState extends State<BoothSearchPage> {
  final _controller = TextEditingController();

  /// 앱 전체에서 한 번만 만든 최근 검색어 (`AppProviders`). 화면을 닫아도 남습니다.
  RecentSearchState get _recent => context.read<RecentSearchState>();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_rebuild);
  }

  @override
  void dispose() {
    _controller.dispose();
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
                    Consumer<RecentSearchState>(
                      builder: (context, recent, _) => RecentSearchesSection(
                        keywords: recent.keywords,
                        onSelected: _searchAgain,
                        onRemoved: recent.remove,
                        onClearAll: recent.clear,
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
