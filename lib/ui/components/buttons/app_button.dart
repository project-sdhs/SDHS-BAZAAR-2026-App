import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// 버튼 크기 (디자인 캔버스 Controls 보드의 TDS 버튼 4단계).
///
/// | 크기   | 높이 | 라디우스 | 글자 |
/// |--------|------|----------|------|
/// | small  | 32   | 8        | 14   |
/// | medium | 38   | 10       | 15   |
/// | large  | 48   | 14       | 16   |
/// | xlarge | 56   | 16       | 17   |
enum AppButtonSize {
  small(height: 32, radius: 8, fontSize: 14, iconSize: 16),
  medium(height: 38, radius: 10, fontSize: 15, iconSize: 18),
  large(height: 48, radius: 14, fontSize: 16, iconSize: 20),
  xlarge(height: 56, radius: 16, fontSize: 17, iconSize: 20);

  const AppButtonSize({
    required this.height,
    required this.radius,
    required this.fontSize,
    required this.iconSize,
  });

  final double height;
  final double radius;
  final double fontSize;
  final double iconSize;
}

/// 버튼 색 조합 (배경 / 글자).
enum AppButtonVariant {
  /// 가장 중요한 행동 하나. 예: 결제하기, 시작하기
  fillPrimary(
    background: AppColors.primary,
    foreground: AppColors.onPrimary,
    pressedColor: AppColors.primaryPressed,
  ),

  /// 덜 강조된 파란 버튼
  weakPrimary(
    background: AppColors.weakBackground,
    foreground: AppColors.weakForeground,
  ),

  /// 회색 보조 버튼. 예: 취소, 지도에서 보기
  light(background: AppColors.surface, foreground: AppColors.body),

  /// 검정 버튼
  dark(background: AppColors.foreground, foreground: AppColors.onPrimary),

  /// 되돌릴 수 없는 위험한 행동. 예: 삭제
  fillDanger(background: AppColors.danger, foreground: AppColors.onPrimary),

  /// 덜 강조된 위험 버튼
  weakDanger(background: AppColors.dangerWeak, foreground: AppColors.danger);

  const AppButtonVariant({
    required this.background,
    required this.foreground,
    this.pressedColor,
  });

  final Color background;
  final Color foreground;

  /// 누를 때 배경을 따로 정한 경우에만 값이 있습니다 (fillPrimary).
  final Color? pressedColor;

  /// 누르고 있는 동안의 배경. [pressedColor] 가 없으면 배경을 8% 어둡게.
  Color get pressedBackground =>
      pressedColor ?? Color.lerp(background, const Color(0xFF000000), 0.08)!;
}

/// 디자인 시스템 버튼.
///
/// ```dart
/// AppButton('결제하기', onPressed: () { ... })
///
/// AppButton(
///   '취소',
///   size: AppButtonSize.medium,
///   variant: AppButtonVariant.light,
///   onPressed: () => context.pop(),
/// )
/// ```
///
/// - `onPressed: null` 또는 `enabled: false` → 비활성(회색), 눌리지 않음
/// - `loading: true` → 폭은 그대로, 스피너 + 글자, 눌리지 않음
///   (키보드 포커스는 그대로 남아서, 처리가 끝나면 바로 다시 누를 수 있음)
/// - `expand: true` → 가로로 꽉 채움
class AppButton extends StatefulWidget {
  const AppButton(
    this.label, {
    super.key,
    required this.onPressed,
    this.size = AppButtonSize.large,
    this.variant = AppButtonVariant.fillPrimary,
    this.loading = false,
    this.enabled = true,
    this.expand = false,
    this.icon,
  });

  /// 버튼 글자
  final String label;

  /// 눌렀을 때 실행할 함수. `null` 이면 비활성 버튼이 됩니다.
  final VoidCallback? onPressed;

  final AppButtonSize size;
  final AppButtonVariant variant;

  /// 처리 중일 때 `true`. 스피너가 돌고 눌리지 않습니다.
  /// 키보드 포커스는 빼앗지 않습니다.
  final bool loading;

  /// `false` 면 비활성 버튼이 됩니다.
  final bool enabled;

  /// `true` 면 부모 폭을 꽉 채웁니다.
  final bool expand;

  /// 글자 앞에 붙는 아이콘 (선택)
  final IconData? icon;

  /// 스피너 크기 (모든 크기 공통)
  static const double spinnerSize = 20;

  /// 좌우 안쪽 여백 (모든 크기 공통)
  static const double horizontalPadding = 20;

  /// 키보드 포커스 링: 두께 3, 버튼에서 2 떨어짐
  static const double focusRingWidth = 3;
  static const double focusRingOffset = 2;

  /// 테스트에서 배경 상자를 찾을 때 씁니다.
  @visibleForTesting
  static const Key surfaceKey = ValueKey('AppButton.surface');

  /// 테스트에서 포커스 링을 찾을 때 씁니다.
  @visibleForTesting
  static const Key focusRingKey = ValueKey('AppButton.focusRing');

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;
  bool _showFocusRing = false;

  /// 회색 비활성 모양인지 (로딩 중에는 원래 색을 유지합니다)
  bool get _disabled =>
      !widget.loading && (!widget.enabled || widget.onPressed == null);

  /// 키보드 포커스를 받을 수 있는지.
  /// 로딩 중에도 `true` 라서 포커스가 다른 곳으로 튀지 않습니다.
  bool get _focusable => widget.enabled && widget.onPressed != null;

  /// 지금 누를 수 있는지 (포커스는 받을 수 있지만 로딩 중이면 못 누름)
  bool get _interactive => _focusable && !widget.loading;

  @override
  void didUpdateWidget(AppButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_interactive) _pressed = false;
  }

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  void _handleTap() {
    if (_interactive) widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final variant = widget.variant;

    final Color background;
    final Color foreground;
    if (_disabled) {
      background = AppColors.surface;
      foreground = AppColors.muted;
    } else {
      background = _pressed ? variant.pressedBackground : variant.background;
      foreground = variant.foreground;
    }

    final textStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: size.fontSize,
      fontWeight: FontWeight.w600,
      color: foreground,
    );

    Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppButton.horizontalPadding,
      ),
      child: _Label(
        label: widget.label,
        icon: widget.icon,
        iconSize: size.iconSize,
        style: textStyle,
      ),
    );

    if (widget.loading) {
      // 원래 내용을 투명하게 남겨 폭을 유지하고, 그 위에 스피너 + 글자를 올립니다.
      content = Stack(
        alignment: Alignment.center,
        children: [
          Visibility(
            visible: false,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: content,
          ),
          Positioned.fill(
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: AppButton.spinnerSize,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.label,
                      style: textStyle,
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    final surface = DecoratedBox(
      key: AppButton.surfaceKey,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(size.radius),
      ),
      child: SizedBox(
        height: size.height,
        width: widget.expand ? double.infinity : null,
        child: Center(widthFactor: widget.expand ? null : 1, child: content),
      ),
    );

    const ringOutset = AppButton.focusRingOffset + AppButton.focusRingWidth;

    return Semantics(
      container: true,
      button: true,
      enabled: !_disabled,
      label: widget.label,
      value: widget.loading ? '처리 중' : null,
      liveRegion: widget.loading,
      child: FocusableActionDetector(
        // 로딩 중에도 켜 둬서 포커스를 유지합니다. 누르기(Enter/Space)는
        // _handleTap 에서 _interactive 를 확인해 무시합니다.
        enabled: _focusable,
        mouseCursor: _interactive
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowFocusHighlight: (value) => setState(() => _showFocusRing = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _handleTap(),
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _interactive ? (_) => _setPressed(true) : null,
          onTapUp: _interactive ? (_) => _setPressed(false) : null,
          onTapCancel: _interactive ? () => _setPressed(false) : null,
          onTap: _interactive ? _handleTap : null,
          child: ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                surface,
                if (_showFocusRing && _focusable)
                  Positioned(
                    left: -ringOutset,
                    top: -ringOutset,
                    right: -ringOutset,
                    bottom: -ringOutset,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        key: AppButton.focusRingKey,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            size.radius + ringOutset,
                          ),
                          border: Border.all(
                            color: AppColors.focusRing,
                            width: AppButton.focusRingWidth,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 아이콘(선택) + 글자 한 줄.
class _Label extends StatelessWidget {
  const _Label({
    required this.label,
    required this.icon,
    required this.iconSize,
    required this.style,
  });

  final String label;
  final IconData? icon;
  final double iconSize;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    if (icon == null) {
      return Text(
        label,
        style: style,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Row 대신 Text.rich 를 쓰면 폭이 좁을 때도 넘치지 않고 말줄임(…)이 됩니다.
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, size: iconSize, color: style.color),
            ),
          ),
          TextSpan(text: label),
        ],
      ),
      style: style,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );
  }
}
