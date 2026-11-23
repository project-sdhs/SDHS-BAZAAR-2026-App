import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/models/booth_detail.dart';
import '../../components/buttons/buttons.dart';
import '../../navigation/app_top_bar.dart';
import 'booth_sample.dart';
import 'widgets/booth_info_header.dart';
import 'widgets/booth_operator_tile.dart';

class BoothDetailPage extends StatelessWidget {
  const BoothDetailPage({super.key, required this.boothId});

  final String boothId;

  BoothDetail get _booth => sampleBooth;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BoothInfoHeader(booth: _booth),
                    if (_booth.operators.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.s32),
                      BoothOperatorSection(operators: _booth.operators),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomCTA(
        buttons: [
          AppButton(
            '지도에서 보기',
            variant: AppButtonVariant.light,
            onPressed: () => context.go(Routes.map),
          ),
          AppButton(
            'QR로 결제',
            enabled: _booth.isOpen,
            onPressed: () => context.go(Routes.pay),
          ),
        ],
      ),
    );
  }
}
