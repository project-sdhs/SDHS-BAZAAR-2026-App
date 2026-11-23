import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class HomeIntro extends StatelessWidget {
  const HomeIntro({super.key, required this.openBoothCount});

  // 서버에서 받아올 열린 부스 개수
  final Future<int> openBoothCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // 화면 너비 390
      width: double.infinity,
      height: 98,
      child: Padding(
        padding: const EdgeInsetsGeometry.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //첫 번째 문장: 높이 36
            SizedBox(
              height: 36,
              child: FutureBuilder<int>(
                future: openBoothCount,
                builder: (context, snapshot) {
                  String title = '오늘 열린 부스 확인 중';

                  if (snapshot.hasError) {
                    title = '부스 정보를 불러오지 못했어요';
                  } else if (snapshot.hasData) {
                    title = '오늘 열린 부스 ${snapshot.data}곳';
                  }

                  return Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      height: 36 / 24,
                      color: AppColors.foreground,
                    ),
                  );
                },
              ),
            ),

            //두 문장 사이 간격
            const SizedBox(height: 6),

            const Text(
              '지금 가장 붐비는 곳부터 보여드려요',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                height: 24 / 16,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
