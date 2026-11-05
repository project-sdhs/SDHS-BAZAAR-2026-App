import 'package:flutter/cupertino.dart';

import '../../../core/theme/app_colors.dart';

/// 목록 행 뒤에 붙이는 주문 알림 등의 스위치. 값은 부모가 관리합니다.
class AppToggle extends StatelessWidget {
  const AppToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: CupertinoSwitch(
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.primary,
    ),
  );
}
