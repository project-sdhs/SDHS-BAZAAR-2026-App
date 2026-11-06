import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// 입력 필드의 시각적 크기와 경계 스타일.
enum AppTextFieldVariant {
  /// 회색 면의 기본 입력 필드. 포커스·오류 상태에서만 테두리가 보입니다.
  box,

  /// 높이 48px, 아래쪽 선만 표시하는 입력 필드.
  line,

  /// 기본 입력 필드보다 위아래 여백이 넓은 입력 필드.
  big,

  /// 36px 굵은 글자와 파란 밑줄을 사용하는 강조 입력 필드.
  hero,
}

/// 크기([variant]), 라벨([label]), 오류([errorText]), 활성 상태([enabled])를
/// 지정해 모양을 예측할 수 있는 앱 공통 입력 필드.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.label,
    this.hintText,
    this.variant = AppTextFieldVariant.box,
    this.borderRadius,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.prefixIconSize = 24,
    this.suffix,
    this.suffixIcon,
    this.suffixIconTooltip,
    this.onSuffixIconPressed,
    this.obscureText = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.semanticLabel,
  }) : assert(
         controller == null || initialValue == null,
         'controller 와 initialValue 를 동시에 지정할 수 없습니다.',
       ),
       assert(maxLines > 0),
       assert(
         suffix == null || suffixIcon == null,
         'suffix 와 suffixIcon 을 동시에 지정할 수 없습니다.',
       ),
       assert(
         suffixIconTooltip == null || suffixIcon != null,
         'suffixIconTooltip 을 지정하면 suffixIcon 도 지정해야 합니다.',
       ),
       assert(
         onSuffixIconPressed == null || suffixIcon != null,
         'onSuffixIconPressed 를 지정하면 suffixIcon 도 지정해야 합니다.',
       );

  final TextEditingController? controller;
  final String? initialValue;

  /// 입력 칸 위에 표시할 라벨. 지정하면 접근성 라벨 기본값으로도 사용합니다.
  final String? label;
  final String? hintText;

  /// 필드의 배경·높이·경계 스타일을 정합니다.
  final AppTextFieldVariant variant;

  /// 둥근 필드의 모서리 반경. 기본값은 14px이며 line·hero에는 적용되지 않습니다.
  final double? borderRadius;

  /// 오류 문구를 표시하고 필드와 라벨을 오류 색으로 바꿉니다.
  final String? errorText;

  /// false이면 편집을 막고 비활성 스타일을 사용합니다.
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;

  /// [prefixIcon]의 크기. 기본값은 24px입니다.
  final double prefixIconSize;

  /// 후행에 표시할 사용자 정의 위젯. [suffixIcon]과 함께 쓸 수 없습니다.
  final Widget? suffix;

  /// 자동으로 활성·오류·비활성 색을 적용하는 후행 아이콘.
  final IconData? suffixIcon;
  final String? suffixIconTooltip;
  final VoidCallback? onSuffixIconPressed;
  final bool obscureText;
  final int maxLines;
  final TextAlign textAlign;
  final String? semanticLabel;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final isHero = widget.variant == AppTextFieldVariant.hero;
    final isLine = widget.variant == AppTextFieldVariant.line;
    final isDisabled = !widget.enabled;
    final hasError = !isDisabled && widget.errorText != null;
    final isFocused = !isDisabled && _focusNode.hasFocus;
    final radius = BorderRadius.circular(widget.borderRadius ?? AppRadius.r14);
    final textColor = isDisabled ? AppColors.muted : AppColors.foreground;
    final iconColor = isDisabled
        ? AppColors.muted
        : hasError
        ? AppColors.danger
        : isFocused
        ? AppColors.foreground
        : AppColors.muted;

    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.label case final label?) ...[
            ExcludeSemantics(
              child: Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isDisabled
                      ? AppColors.muted
                      : hasError
                      ? AppColors.danger
                      : isFocused
                      ? AppColors.primary
                      : AppColors.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
          ],
          TextFormField(
            controller: widget.controller,
            initialValue: widget.initialValue,
            focusNode: _focusNode,
            enabled: widget.enabled,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            obscureText: widget.obscureText,
            maxLines: widget.obscureText ? 1 : widget.maxLines,
            textAlign: widget.textAlign,
            style: (isHero ? AppTypography.h1 : AppTypography.body).copyWith(
              color: textColor,
              fontSize: isHero ? 36 : 17,
              fontWeight: isHero ? FontWeight.w700 : null,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: (isHero ? AppTypography.h1 : AppTypography.body)
                  .copyWith(
                    color: AppColors.muted,
                    fontSize: isHero ? 36 : 17,
                    fontWeight: isHero ? FontWeight.w700 : null,
                  ),
              filled: !isLine && !isHero,
              fillColor: isFocused || hasError
                  ? AppColors.canvas
                  : AppColors.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: isHero ? 0 : AppSpacing.s16,
                vertical: isHero
                    ? AppSpacing.s4
                    : isLine
                    ? AppSpacing.s8
                    : widget.variant == AppTextFieldVariant.big
                    ? AppSpacing.s24
                    : AppSpacing.s16,
              ),
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(
                      widget.prefixIcon,
                      color: iconColor,
                      size: widget.prefixIconSize,
                    ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              suffixIcon: _buildSuffix(iconColor),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              border: _inputBorder(
                isLine: isLine,
                isHero: isHero,
                borderColor: AppColors.border,
                visible: false,
                radius: radius,
              ),
              enabledBorder: _inputBorder(
                isLine: isLine,
                isHero: isHero,
                borderColor: hasError
                    ? AppColors.danger
                    : isHero
                    ? AppColors.primary
                    : AppColors.border,
                visible: hasError || isHero,
                radius: radius,
              ),
              focusedBorder: _inputBorder(
                isLine: isLine,
                isHero: isHero,
                borderColor: hasError ? AppColors.danger : AppColors.primary,
                visible: true,
                radius: radius,
              ),
              disabledBorder: _inputBorder(
                isLine: isLine,
                isHero: isHero,
                borderColor: AppColors.border,
                visible: false,
                radius: radius,
              ),
              errorBorder: _inputBorder(
                isLine: isLine,
                isHero: isHero,
                borderColor: AppColors.danger,
                visible: true,
                radius: radius,
              ),
              focusedErrorBorder: _inputBorder(
                isLine: isLine,
                isHero: isHero,
                borderColor: AppColors.danger,
                visible: true,
                radius: radius,
              ),
              isDense: isLine,
              constraints: isLine && widget.maxLines == 1
                  ? const BoxConstraints(minHeight: 48, maxHeight: 48)
                  : null,
            ),
          ),
          if (widget.errorText case final errorText? when !isDisabled)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.s4,
                top: AppSpacing.s6,
              ),
              child: Text(
                errorText,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.danger,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget? _buildSuffix(Color iconColor) {
    if (widget.suffix != null) return widget.suffix;
    if (widget.suffixIcon != null) {
      return IconButton(
        tooltip: widget.suffixIconTooltip,
        onPressed: widget.enabled ? widget.onSuffixIconPressed : null,
        icon: Icon(widget.suffixIcon, color: iconColor, size: 24),
      );
    }
    return null;
  }

  InputBorder _inputBorder({
    required bool isLine,
    required bool isHero,
    required Color borderColor,
    required bool visible,
    required BorderRadius radius,
  }) {
    if (isHero) {
      return UnderlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 2),
      );
    }
    if (isLine) {
      return UnderlineInputBorder(
        borderSide: BorderSide(color: borderColor, width: 2),
      );
    }
    if (!visible) return InputBorder.none;
    return OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(color: borderColor, width: 2),
    );
  }
}
