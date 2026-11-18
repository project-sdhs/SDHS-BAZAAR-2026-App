import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../navigation/app_top_bar.dart';

/// 부스 상세 (`/booths/:boothId`). 하단 탭 바 없이 전체 화면으로 뜹니다.
///
/// 지금은 상단 바(뒤로 · 공유)만 있습니다.
class BoothDetailPage extends StatelessWidget {
  const BoothDetailPage({super.key, required this.boothId});

  final String boothId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AppTopBar(
              onShare: () {
                // TODO: 공유 기능
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('공유는 준비 중이에요')));
              },
            ),
          ],
        ),
      ),
    );
  }
}
