import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import 'map_marker_style.dart';

class BoothMarker extends StatelessWidget {
  const BoothMarker({
    super.key,
    required this.name,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  static const double height = 32;
  static const double horizontalPadding = 12;
  static const double radius = AppRadius.r8;
  static const double iconSize = 16;
  static const double iconGap = AppSpacing.s4;
  static const Size tailSize = Size(10, 6);

  @override
  Widget build(BuildContext context) {
    final background = selected ? AppColors.primary : AppColors.canvas;
    final foreground = selected ? AppColors.onPrimary : AppColors.foreground;

    return Semantics(
      button: true,
      selected: selected,
      label: name,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: height,
              padding: const EdgeInsets.symmetric(
                horizontal: horizontalPadding,
              ),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(radius),
                boxShadow: MapMarkerStyle.shadow,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: iconGap,
                children: [
                  if (selected) Icon(icon, size: iconSize, color: foreground),
                  Text(
                    name,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w600,
                      color: foreground,
                    ),
                  ),
                ],
              ),
            ),
            CustomPaint(size: tailSize, painter: _TailPainter(background)),
          ],
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}
