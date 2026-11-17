import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import 'widgets/booth_list_header.dart';

/// 부스 목록 탭. 정렬 · 필터 · 부스 카드 리스트는 이후 티켓에서 붙입니다.
class BoothsPage extends StatelessWidget {
  const BoothsPage({super.key});

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
          ],
        ),
      ),
    );
  }
}
