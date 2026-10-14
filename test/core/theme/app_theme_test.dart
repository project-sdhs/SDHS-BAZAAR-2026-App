import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('primary 컬러는 디지텍 #0171CE 이다', () {
    expect(AppColors.primary, const Color(0xFF0171CE));
    expect(AppTheme.light.colorScheme.primary, AppColors.primary);
  });

  test('화면 배경은 흰색(canvas)이다', () {
    expect(AppTheme.light.scaffoldBackgroundColor, AppColors.canvas);
  });

  test('타입 롤의 줄 높이는 디자인 px 값과 같다', () {
    expect(AppTypography.h1.fontSize! * AppTypography.h1.height!, 54);
    expect(AppTypography.h2.fontSize! * AppTypography.h2.height!, 45);
    expect(AppTypography.h3.fontSize! * AppTypography.h3.height!, 36);
    expect(AppTypography.h4.fontSize! * AppTypography.h4.height!, 33);
    expect(AppTypography.body.fontSize! * AppTypography.body.height!, 24);
    expect(
      AppTypography.bodySmall.fontSize! * AppTypography.bodySmall.height!,
      21,
    );
  });

  test('기본 글꼴은 Pretendard 이다', () {
    expect(AppTheme.light.textTheme.bodyLarge?.fontFamily, 'Pretendard');
  });
}
