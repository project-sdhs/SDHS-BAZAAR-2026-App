import 'package:flutter/material.dart';

// [뒤로 이동 추가] 홈에서도 이전 로그인 화면으로 돌아갈 수 있습니다.
import '../../navigation/app_top_bar.dart';

/// 홈 탭 (임시). 실제 화면은 이후 PR 에서 만듭니다.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        // [뒤로 이동 수정] 기존 제목/설명을 공통 상단바로 표시합니다.
        child: AppTopBar(title: '홈', description: '준비 중'),
      ),
    );
  }
}
