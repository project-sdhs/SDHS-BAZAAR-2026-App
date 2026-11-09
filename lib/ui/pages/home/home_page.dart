import 'package:flutter/material.dart';

// [리뷰 2·3] 홈은 탭 첫 화면이므로 이전 로그인 기록과 뒤로 버튼이 없음
import '../../navigation/app_top_bar.dart';

/// 홈 탭 (임시). 실제 화면은 이후 PR 에서 만듭니다.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        // [뒤로 이동 수정] 기존 제목/설명을 공통 상단바로 표시
        child: AppTopBar(title: '홈', description: '준비 중'),
      ),
    );
  }
}
