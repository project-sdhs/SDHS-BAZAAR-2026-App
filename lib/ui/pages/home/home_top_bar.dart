import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({
    super.key,
    required this.onNotificationPressed,
    this.hasUnread = false,
  });

  // 알림 버튼을 눌렀을 때 실행할 함수
  final VoidCallback onNotificationPressed;

  // 읽지 않은 알림이 있는지 여부
  final bool hasUnread;

  @override
  Widget build(BuildContext context) {
    // [플랫폼 아이콘 추가] Android에서는 Material 알림 아이콘을 사용합니다.
    IconData notificationIcon = Icons.notifications_none_rounded;

    // [플랫폼 아이콘 추가] iOS에서는 Cupertino 알림 아이콘으로 변경합니다.
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      notificationIcon = CupertinoIcons.bell;
    }

    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            // 학교 로고
            Image.asset(
              'assets/img/SDHS.png',
              width: 64,
              height: 36,
              fit: BoxFit.contain,
              semanticLabel: '서울디지텍고등학교',
            ),

            // 알림 버튼을 오른쪽으로 밀기
            const Spacer(),

            // 알림 버튼
            SizedBox(
              width: 48,
              height: 48,
              child: IconButton(
                tooltip: hasUnread ? '알림, 새알림 있음' : '알림',
                onPressed: onNotificationPressed,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // [플랫폼 아이콘 수정] 위에서 선택한 아이콘을 표시합니다.
                    Icon(
                      notificationIcon,
                      size: 24,
                      color: AppColors.foreground,
                    ),

                    // 읽지 않은 알림이 있으면 파란점 표시
                    if (hasUnread)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
