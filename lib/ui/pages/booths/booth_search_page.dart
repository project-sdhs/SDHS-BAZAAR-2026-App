import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import 'widgets/booth_search_bar.dart';

/// 부스 검색 화면. 지금은 검색 바만 있고(APP-37),
/// 최근 검색어 · 인기 검색 · 검색 결과는 이후 티켓에서 붙입니다.
class BoothSearchPage extends StatefulWidget {
  const BoothSearchPage({super.key});

  @override
  State<BoothSearchPage> createState() => _BoothSearchPageState();
}

class _BoothSearchPageState extends State<BoothSearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.booths);
    }
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
              onSubmitted: (_) {},
              onCancel: _close,
            ),
          ],
        ),
      ),
    );
  }
}
