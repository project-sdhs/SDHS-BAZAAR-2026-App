import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'map_marker_style.dart';

class ClusterMarker extends StatelessWidget {
  const ClusterMarker({super.key, required this.count, this.onTap});

  final int count;
  final VoidCallback? onTap;

  static const double diameter = 36;
  static const double borderWidth = 2;
  static const double horizontalPadding = 4;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '부스 $count곳',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: diameter,
          constraints: const BoxConstraints(minWidth: diameter),
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.foreground,
            borderRadius: BorderRadius.circular(diameter / 2),
            border: Border.all(color: AppColors.canvas, width: borderWidth),
            boxShadow: MapMarkerStyle.shadow,
          ),
          child: Text(
            '$count',
            style: AppTypography.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
