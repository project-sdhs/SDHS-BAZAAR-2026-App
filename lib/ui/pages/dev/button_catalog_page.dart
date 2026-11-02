import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../components/buttons/buttons.dart';

/// 버튼 카탈로그 (개발용, 디버그 빌드에서만 `/dev/buttons` 로 열림).
///
/// 버튼의 크기 · 변형 · 상태를 한 화면에서 눈으로 확인할 때 씁니다.
class ButtonCatalogPage extends StatefulWidget {
  const ButtonCatalogPage({super.key});

  @override
  State<ButtonCatalogPage> createState() => _ButtonCatalogPageState();
}

class _ButtonCatalogPageState extends State<ButtonCatalogPage> {
  bool _loading = false;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startLoading() {
    setState(() => _loading = true);
    _timer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    void noop() {}

    return Scaffold(
      appBar: AppBar(title: const Text('버튼 카탈로그')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s16),
        children: [
          const _Section('사이즈'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.end,
            children: [
              for (final size in AppButtonSize.values)
                AppButton(size.name, size: size, onPressed: noop),
            ],
          ),
          const _Section('변형'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final variant in AppButtonVariant.values)
                AppButton(variant.name, variant: variant, onPressed: noop),
            ],
          ),
          const _Section('상태'),
          Column(
            spacing: 12,
            children: [
              AppButton(
                '계좌이체로 충전 (눌러 보세요)',
                size: AppButtonSize.xlarge,
                expand: true,
                loading: _loading,
                onPressed: _startLoading,
              ),
              const AppButton(
                '금액을 입력하세요',
                size: AppButtonSize.xlarge,
                expand: true,
                onPressed: null,
              ),
              AppButton(
                'QR로 결제',
                size: AppButtonSize.xlarge,
                expand: true,
                icon: Icons.qr_code_scanner,
                onPressed: noop,
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomCTA(
        buttons: [
          AppButton(
            '지도에서 보기',
            variant: AppButtonVariant.light,
            onPressed: noop,
          ),
          AppButton('QR로 결제', onPressed: noop),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSpacing.s24,
        bottom: AppSpacing.s16,
      ),
      child: Text(
        title,
        style: AppTypography.h4.copyWith(color: AppColors.foreground),
      ),
    );
  }
}
