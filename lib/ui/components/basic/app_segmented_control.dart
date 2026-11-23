import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 붙어 있는 선택 영역. 키는 중복되지 않는 값, 값은 표시할 글자입니다.
class AppSegmentedControl<T extends Object> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final Map<T, String> items;
  final T value;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Padding(
      padding: const EdgeInsets.all(4),
      child: Row(
        spacing: 4,
        children: [
          for (final item in items.entries)
            Expanded(
              child: Semantics(
                selected: item.key == value,
                child: Material(
                  color: item.key == value
                      ? AppColors.canvas
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onChanged == null
                        ? null
                        : () => onChanged!(item.key),
                    borderRadius: BorderRadius.circular(10),
                    // 칸 높이 40 (막대 전체 48 = 칸 40 + 위아래 4). 큰 글자에서는 늘어납니다.
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 40),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Center(
                          heightFactor: 1,
                          child: Text(
                            item.value,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              fontSize: 15,
                              fontWeight: item.key == value
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: onChanged == null
                                  ? AppColors.muted
                                  : item.key == value
                                  ? AppColors.foreground
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
