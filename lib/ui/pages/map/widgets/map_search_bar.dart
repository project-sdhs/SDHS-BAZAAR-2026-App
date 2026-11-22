import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class MapSearchBar extends StatefulWidget {
  const MapSearchBar({
    super.key,
    this.controller,
    this.hintText = '지도에서 부스 검색',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;

  static const double height = 52;
  static const double radius = AppRadius.r16;
  static const double leadingPadding = AppSpacing.s16;
  static const double trailingPadding = AppSpacing.s6;
  static const double iconSize = 24;
  static const double iconGap = AppSpacing.s8;
  static const double buttonSize = 40;
  static const double borderWidth = 1;

  @override
  State<MapSearchBar> createState() => _MapSearchBarState();
}

class _MapSearchBarState extends State<MapSearchBar> {
  late TextEditingController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _useController(widget.controller);
  }

  @override
  void didUpdateWidget(MapSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _controller.removeListener(_handleControllerChange);
      if (_ownsController) _controller.dispose();
      _useController(widget.controller);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleControllerChange);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _useController(TextEditingController? controller) {
    _ownsController = controller == null;
    _controller = controller ?? TextEditingController();
    _controller.addListener(_handleControllerChange);
  }

  void _handleControllerChange() => setState(() {});

  void _clear() {
    _controller.clear();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    final textStyle = AppTypography.body.copyWith(color: AppColors.foreground);

    return Container(
      height: MapSearchBar.height,
      padding: const EdgeInsets.only(
        left: MapSearchBar.leadingPadding,
        right: MapSearchBar.trailingPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(MapSearchBar.radius),
        border: Border.all(
          color: AppColors.border,
          width: MapSearchBar.borderWidth,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.search,
            size: MapSearchBar.iconSize,
            color: AppColors.muted,
          ),
          const SizedBox(width: MapSearchBar.iconGap),
          Expanded(
            child: TextField(
              controller: _controller,
              style: textStyle,
              cursorColor: AppColors.primary,
              textInputAction: TextInputAction.search,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                hintText: widget.hintText,
                hintStyle: textStyle.copyWith(color: AppColors.muted),
              ),
            ),
          ),
          if (hasText)
            _IconButton(
              icon: Icons.cancel,
              tooltip: '검색어 지우기',
              color: AppColors.muted,
              onPressed: _clear,
            ),
          _IconButton(
            icon: Icons.tune,
            tooltip: '필터',
            color: AppColors.body,
            onPressed: widget.onFilterTap,
          ),
        ],
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed ?? () {},
    icon: Icon(icon, size: MapSearchBar.iconSize, color: color),
    constraints: const BoxConstraints.tightFor(
      width: MapSearchBar.buttonSize,
      height: MapSearchBar.buttonSize,
    ),
    padding: EdgeInsets.zero,
    style: IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
  );
}
