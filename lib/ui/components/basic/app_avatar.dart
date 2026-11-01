import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 사진을 사용하지 않고 이름의 첫 글자를 표시하는 프로필 원.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.highlighted = false,
  });

  final String name;
  final double size;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    return Semantics(
      label: name,
      image: true,
      child: ExcludeSemantics(
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlighted ? AppColors.weakBackground : AppColors.surface,
          ),
          child: trimmed.isEmpty
              ? Icon(
                  Icons.person_outline,
                  size: size / 2,
                  color: AppColors.muted,
                )
              : Text(
                  trimmed.characters.first,
                  style: AppTypography.body.copyWith(
                    fontSize: size * .4,
                    fontWeight: FontWeight.w600,
                    color: highlighted
                        ? AppColors.weakForeground
                        : AppColors.body,
                  ),
                ),
        ),
      ),
    );
  }
}
