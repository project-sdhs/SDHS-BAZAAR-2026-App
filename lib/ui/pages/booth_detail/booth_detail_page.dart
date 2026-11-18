import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../navigation/app_top_bar.dart';

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
