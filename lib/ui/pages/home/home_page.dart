import 'package:bazaar_app/data/repositories/booth_repositories.dart';
import 'package:bazaar_app/ui/pages/home/home_intro.dart';
import 'package:flutter/material.dart';

import 'home_top_bar.dart';

/// 홈 탭 (임시). 실제 화면은 이후 PR 에서 만듭니다.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  //서버에서 열린 부스 개수를 가져옴
  late final Future<int> openBoothCount = fetchOpenBoothCount();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 학교 로고와 알림버튼이 있는 상단바
            HomeTopBar(
              hasUnread: true, //파란 점 표시
              onNotificationPressed: () {
                //알림 화면으로 이동하는 코드 넣을 곳
              },
            ),

            // 열린 부스 개수 + 설명 문장
            HomeIntro(openBoothCount: openBoothCount),

            // 나머지 홈 화면 내용은 여기에 추가
          ],
        ),
      ),
    );
  }
}
