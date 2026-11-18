import 'package:flutter/material.dart';

import '../../../components/basic/basic.dart';

/// 푸시 정책이 결정되기 전까지 부모가 알림 설정을 관리합니다.
class MyNotifications extends StatefulWidget {
  const MyNotifications({super.key, this.initialValue = true, this.onChanged});
  final bool initialValue;
  final ValueChanged<bool>? onChanged;

  @override
  State<MyNotifications> createState() => _MyNotificationsState();
}

class _MyNotificationsState extends State<MyNotifications> {
  late bool _enabled = widget.initialValue;

  @override
  Widget build(BuildContext context) => AppListRow(
    title: '주문 알림 받기',
    trailing: AppToggle(
      value: _enabled,
      label: '주문 알림 받기',
      onChanged: (value) {
        setState(() => _enabled = value);
        widget.onChanged?.call(value);
      },
    ),
  );
}
