import 'package:flutter/material.dart';

import 'home_top_bar.dart';

/// 홈 탭 (임시). 실제 화면은 이후 PR 에서 만듭니다.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // [뒤로 이동 수정] 기존 제목/설명을 공통 상단바로 표시
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 학교 로고와 알림버튼이 있는 상단바
            HomeTopBar(
              onNotificationPressed: () {
                //알림 화면으로 이동하는 코드 넣을 곳
              },
            ),

            // 홈화면의 나머지 내용 코드 넣을 곳
          ],
        ),
      ),
    );
  }
}
