import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import 'app_button.dart';

/// 화면 맨 아래에 고정되는 큰 버튼 영역 (버튼 1개 또는 2개).
///
/// 버튼 크기는 자동으로 `xlarge`(56) 가 되고, 2개면 같은 폭으로 나란히 놓입니다.
///
/// ```dart
/// Scaffold(
///   body: ...,
///   bottomNavigationBar: BottomCTA(
///     buttons: [
///       AppButton('지도에서 보기', variant: AppButtonVariant.light, onPressed: ...),
///       AppButton('QR로 결제', onPressed: ...),
///     ],
///   ),
/// )
/// ```
class BottomCTA extends StatelessWidget {
  BottomCTA({super.key, required this.buttons})
    : assert(
        buttons.isNotEmpty && buttons.length <= 2,
        'BottomCTA 에는 버튼을 1개 또는 2개만 넣습니다.',
      );

  /// 왼쪽부터 순서대로. 주로 [보조(light), 주요(fillPrimary)] 순서로 둡니다.
  final List<AppButton> buttons;

  /// 위 · 좌우 여백 16, 버튼 사이 8
  static const double padding = AppSpacing.s16;
  static const double gap = AppSpacing.s8;

  /// 아래 여백 34. 홈 인디케이터(안전 영역)가 더 크면 그만큼 띄웁니다.
  static const double bottomPadding = 34;

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return ColoredBox(
      color: AppColors.canvas,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          math.max(padding, viewPadding.left),
          padding,
          math.max(padding, viewPadding.right),
          math.max(bottomPadding, viewPadding.bottom),
        ),
        child: Row(
          spacing: gap,
          children: [
            for (final button in buttons) Expanded(child: _asXLarge(button)),
          ],
        ),
      ),
    );
  }

  /// 넘겨받은 버튼을 xlarge · 꽉 채움으로 바꿔서 그립니다.
  static AppButton _asXLarge(AppButton button) {
    return AppButton(
      button.label,
      key: button.key,
      onPressed: button.onPressed,
      size: AppButtonSize.xlarge,
      variant: button.variant,
      loading: button.loading,
      enabled: button.enabled,
      expand: true,
      icon: button.icon,
    );
  }
}
