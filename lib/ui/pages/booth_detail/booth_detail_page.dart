import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/booth.dart';
import '../../navigation/app_top_bar.dart';
import 'booth_sample.dart';
import 'widgets/booth_info_header.dart';

class BoothDetailPage extends StatelessWidget {
  const BoothDetailPage({super.key, required this.boothId});

  final String boothId;

  Booth get _booth => sampleBooth;

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
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  AppSpacing.s8,
                  AppSpacing.screenHorizontal,
                  AppSpacing.s24,
                ),
                child: BoothInfoHeader(booth: _booth),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
