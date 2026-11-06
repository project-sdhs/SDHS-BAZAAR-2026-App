import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// 바텀시트를 공통 표면과 모서리 모양으로 표시하는 도우미.
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool isScrollControlled = true,
    bool isDismissible = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      builder: (sheetContext) => Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s16),
            child: builder(sheetContext),
          ),
          Positioned(
            top: AppSpacing.s8,
            left: 0,
            right: 0,
            child: ExcludeSemantics(
              child: Center(
                child: Container(
                  key: const ValueKey('AppBottomSheet.dragHandle'),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      useSafeArea: true,
      showDragHandle: false,
      enableDrag: true,
      backgroundColor: AppColors.canvas,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r16),
        ),
      ),
    );
  }
}
