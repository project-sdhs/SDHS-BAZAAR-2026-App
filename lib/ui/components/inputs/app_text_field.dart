import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// 입력 필드의 시각적 크기와 경계 스타일.
enum AppTextFieldVariant {
  /// 표면 배경과 둥근 테두리가 있는 기본 입력 필드.
  box,

  /// 아래쪽 선만 표시하는 입력 필드.
  line,

  /// 일반보다 여백을 넓힌 입력 필드.
  big,

  /// 큰 금액 입력 등에 사용하는 강조 입력 필드.
  hero,
}

/// 앱 공통 텍스트 입력 필드.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.hintText,
    this.variant = AppTextFieldVariant.box,
    this.errorText,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    this.prefixIcon,
    this.suffix,
    this.creditSuffix = false,
    this.obscureText = false,
    this.maxLines = 1,
    this.textAlign = TextAlign.start,
    this.semanticLabel,
  }) : assert(
         controller == null || initialValue == null,
         'controller 와 initialValue 를 동시에 지정할 수 없습니다.',
       ),
       assert(maxLines > 0);

  final TextEditingController? controller;
  final String? initialValue;
  final String? hintText;
  final AppTextFieldVariant variant;
  final String? errorText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool creditSuffix;
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
    final isFocused = _focusNode.hasFocus;
    final borderColor = widget.errorText != null
        ? AppColors.danger
        : isFocused
        ? AppColors.primary
        : AppColors.border;
    final radius = BorderRadius.circular(
      isHero ? AppRadius.r16 : AppRadius.r14,
    );

    return Semantics(
      label: widget.semanticLabel,
      textField: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
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
            style: AppTypography.body.copyWith(
              color: widget.enabled ? AppColors.foreground : AppColors.muted,
              fontSize: isHero ? 30 : null,
              fontWeight: isHero ? FontWeight.w600 : null,
            ),
            decoration: InputDecoration(
              hintText: widget.hintText,
              hintStyle: AppTypography.body.copyWith(color: AppColors.muted),
              filled: !isLine,
              fillColor: AppColors.surface,
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: isHero || widget.variant == AppTextFieldVariant.big
                    ? AppSpacing.s24
                    : AppSpacing.s16,
              ),
              prefixIcon: widget.prefixIcon == null
                  ? null
                  : Icon(widget.prefixIcon, color: AppColors.muted, size: 22),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              suffixIcon: _buildSuffix(),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 48,
              ),
              border: _inputBorder(
                isLine ? BorderSide.none : BorderSide(color: borderColor),
                radius,
              ),
              enabledBorder: _inputBorder(
                isLine
                    ? const BorderSide(color: AppColors.border)
                    : BorderSide(color: borderColor),
                radius,
              ),
              focusedBorder: _inputBorder(
                isLine
                    ? const BorderSide(color: AppColors.primary, width: 2)
                    : BorderSide(color: borderColor, width: 1.5),
                radius,
              ),
              disabledBorder: _inputBorder(
                const BorderSide(color: AppColors.border),
                radius,
              ),
              errorBorder: _inputBorder(
                const BorderSide(color: AppColors.danger),
                radius,
              ),
              focusedErrorBorder: _inputBorder(
                const BorderSide(color: AppColors.danger, width: 1.5),
                radius,
              ),
              isDense: false,
            ),
          ),
          if (widget.errorText case final errorText?)
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

  Widget? _buildSuffix() {
    if (widget.suffix != null) return widget.suffix;
    if (widget.creditSuffix) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.s16),
        child: Icon(
          Icons.monetization_on_outlined,
          color: AppColors.primary,
          size: 24,
          semanticLabel: '크레딧',
        ),
      );
    }
    return null;
  }

  InputBorder _inputBorder(BorderSide side, BorderRadius radius) {
    if (widget.variant == AppTextFieldVariant.line) {
      return UnderlineInputBorder(borderSide: side);
    }
    return OutlineInputBorder(borderRadius: radius, borderSide: side);
  }
}
