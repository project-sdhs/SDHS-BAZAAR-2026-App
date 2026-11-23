import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../components/inputs/inputs.dart';

/// 부스 검색 화면 맨 위의 검색 바 (APP-37).
///
/// 검색 입력([AppSearchField], compact)과 오른쪽 `취소` 버튼으로 이루어집니다.
/// 입력한 글자는 [controller] 로 읽고, 지우기·취소 동작은 부모가 정합니다.
///
/// Figma 부스 검색 화면 기준: 바 높이 56, 좌우 16, 필드와 취소 사이 8.
/// 필드는 높이 48 · 모서리 14 · 글자 16, `취소` 는 높이 48 · 좌우 8 · 16/600.
class BoothSearchBar extends StatelessWidget {
  const BoothSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.onCancel,
    this.autofocus = true,
  });

  static const double height = 56;

  /// 서버 검색어(`GET /booths` 의 `q`)는 trim 한 뒤 1~30자라서 넘기면 400 이 납니다.
  static const int maxQueryLength = 30;

  final TextEditingController controller;

  /// 입력할 때, 그리고 지우기 버튼으로 비울 때(빈 문자열) 호출됩니다.
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  /// `취소` 를 눌렀을 때. 보통 검색 화면을 닫습니다.
  final VoidCallback onCancel;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: height),
      child: Padding(
        // 오른쪽은 `취소` 의 누르는 영역 좌우 8 이 여백 안으로 들어가므로 16 - 8.
        padding: const EdgeInsets.only(
          left: AppSpacing.screenHorizontal,
          right: AppSpacing.screenHorizontal - AppSpacing.s8,
        ),
        child: Row(
          spacing: AppSpacing.s8,
          children: [
            Expanded(
              child: AppSearchField(
                controller: controller,
                hintText: '반 · 부스 · 메뉴 검색',
                compact: true,
                autofocus: autofocus,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(maxQueryLength),
                ],
                onChanged: onChanged,
                onSubmitted: onSubmitted,
              ),
            ),
            _CancelButton(onPressed: onCancel),
          ],
        ),
      ),
    );
  }
}

class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '취소',
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
            // heightFactor: 부모 높이가 정해져 있어도 글자 높이에 맞춰 둡니다.
            child: Center(
              heightFactor: 1,
              child: Text(
                '취소',
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.body,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
