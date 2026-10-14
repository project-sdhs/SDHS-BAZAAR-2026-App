import 'package:flutter/material.dart';

/// 디자인 캔버스(Toss Design System 기반)의 컬러 토큰.
///
/// 화면에서 `Color(0xFF...)` 를 직접 쓰지 말고 여기 있는 이름을 쓰세요.
/// 예: `color: AppColors.primary`
abstract final class AppColors {
  // 브랜드 (디지텍 퍼스널 컬러)
  static const Color primary = Color(0xFF0171CE);
  static const Color primaryPressed = Color(0xFF015CA8);
  static const Color weakBackground = Color(0xFFEDF5FC);
  static const Color weakForeground = Color(0xFF01477F);
  static const Color tileTint = Color(0xFFD4E7F7);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // 중성색 (TDS 시맨틱 토큰)
  static const Color foreground = Color(0xFF191F28); // 제목, 진한 글자
  static const Color body = Color(0xFF4E5968); // 본문 글자
  static const Color muted = Color(0xFF8B95A1); // 보조 글자
  static const Color border = Color(0xFFE5E8EB); // 1px 경계선
  static const Color surface = Color(0xFFF2F4F6); // 회색 면
  static const Color canvas = Color(0xFFFFFFFF); // 화면 배경

  // 상태
  static const Color danger = Color(0xFFE42939);
  static const Color dangerWeak = Color(0xFFFDECEE);
  static const Color focusRing = Color(0xFFA9CFEF);

  // 이미지가 들어갈 자리 (일러스트 대체 박스 등)
  static const Color placeholder = Color(0xFFE9ECF0);
}
