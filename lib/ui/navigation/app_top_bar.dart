import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// [뒤로 이동 추가] 중첩된 하단 탭에서도 라우터의 이전 화면으로 돌아갑니다.
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key, required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    // 기본 - 안드로이드 아이콘
    IconData backIcon = Icons.arrow_back_ios_new_rounded;

    // ios라면 아이콘 변경
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      backIcon = CupertinoIcons.back;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        // [뒤로 이동 수정] 자기 자신을 다시 생성하던 코드를 제거했습니다.

        // 뒤로가기 버튼
        Padding(
          padding: const EdgeInsets.only(top: 1, left: 1),
          child: SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: '뒤로가기',
              padding: EdgeInsets.zero,
              icon: Icon(backIcon, size: 24, color: AppColors.foreground),

              onPressed: () {
                // [뒤로 이동 수정] 이전 화면이 있을 때만 라우터에서 돌아갑니다.
                if (context.canPop()) {
                  context.pop();
                }
              },
            ),
          ),
        ),

        const SizedBox(height: 8),

        //제목
        Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 39 / 26,
              color: AppColors.foreground,
            ),
          ),
        ),

        const SizedBox(height: 3),

        // 설명
        Padding(
          padding: const EdgeInsetsGeometry.symmetric(horizontal: 16),
          child: Text(
            description,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              height: 24 / 16,
              color: AppColors.muted,
            ),
          ),
        ),

        const SizedBox(height: 31),
      ],
    );
  }
}
