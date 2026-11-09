import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.description,
    this.onShare,
  });

  final String title;
  final String description;

  // [리뷰 4] 필요한 화면만 콜백을 전달
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    IconData backIcon = Icons.arrow_back_ios_new_rounded;
    IconData shareIcon = Icons.share_rounded;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      backIcon = CupertinoIcons.back;
      shareIcon = CupertinoIcons.share;
    }

    // [리뷰 3] 돌아갈 화면이 없으면 눌러도 반응 없는 뒤로 버튼을 표시 X
    final canGoBack = context.canPop();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1, left: 1, right: 1),
          // 버튼을 숨겨도 제목 위치가 달라지지 않도록 상단 높이는 유지
          child: SizedBox(
            height: 48,
            child: Row(
              children: [
                if (canGoBack)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: '뒤로가기',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        backIcon,
                        size: 24,
                        color: AppColors.foreground,
                      ),
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        }
                      },
                    ),
                  ),
                const Spacer(),
                // [리뷰 4] 공유 콜백이 있는 화면에서만 오른쪽 버튼을 표시
                if (onShare != null)
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      tooltip: '공유',
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        shareIcon,
                        size: 24,
                        color: AppColors.foreground,
                      ),
                      onPressed: onShare,
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
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
