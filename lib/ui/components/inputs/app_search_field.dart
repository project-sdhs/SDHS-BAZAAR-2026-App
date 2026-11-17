import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import 'app_text_field.dart';

/// 검색 입력과 입력 지우기 동작을 제공하는 필드.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.label,
    this.hintText = '검색어를 입력하세요',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.autofocus = false,
    this.compact = false,
  });

  final TextEditingController? controller;
  final String? label;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool autofocus;

  /// 높이 48 · 모서리 14 · 아이콘 20 으로 줄인 검색 바용 모양 (부스 검색 화면).
  final bool compact;

  @override
  State<AppSearchField> createState() => _AppSearchFieldState();
}

class _AppSearchFieldState extends State<AppSearchField> {
  late TextEditingController _controller;
  late bool _ownsController;

  @override
  void initState() {
    super.initState();
    _useController(widget.controller);
  }

  @override
  void didUpdateWidget(AppSearchField oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;
    return AppTextField(
      semanticLabel: widget.label ?? '검색',
      controller: _controller,
      label: widget.label,
      hintText: widget.hintText,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      compact: widget.compact,
      borderRadius: widget.compact ? AppRadius.r14 : AppRadius.r16,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      prefixIcon: Icons.search,
      prefixIconSize: widget.compact ? 20 : 24,
      suffixIcon: hasText ? Icons.cancel : null,
      suffixIconTooltip: hasText ? '검색어 지우기' : null,
      onSuffixIconPressed: hasText ? _clearSearch : null,
    );
  }

  void _clearSearch() {
    _controller.clear();
    widget.onChanged?.call('');
  }
}
