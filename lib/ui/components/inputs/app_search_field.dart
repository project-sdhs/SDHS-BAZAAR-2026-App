import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'app_text_field.dart';

/// 검색 입력과 입력 지우기 동작을 제공하는 필드.
class AppSearchField extends StatefulWidget {
  const AppSearchField({
    super.key,
    this.controller,
    this.hintText = '검색어를 입력하세요',
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

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
    return AppTextField(
      semanticLabel: '검색',
      controller: _controller,
      hintText: widget.hintText,
      enabled: widget.enabled,
      textInputAction: TextInputAction.search,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      prefixIcon: Icons.search,
      suffix: _controller.text.isEmpty
          ? null
          : IconButton(
              tooltip: '검색어 지우기',
              onPressed: widget.enabled
                  ? () {
                      _controller.clear();
                      widget.onChanged?.call('');
                    }
                  : null,
              icon: const Icon(Icons.close, color: AppColors.muted),
            ),
    );
  }
}
