import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/my_user.dart';
import '../../../components/basic/basic.dart';
import '../../../components/feedback/feedback.dart';

class MyMenus extends StatelessWidget {
  const MyMenus({super.key, required this.user});
  final MyUser user;

  Widget row(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    bool highlighted = false,
  }) => AppListRow(
    padding: const EdgeInsets.symmetric(vertical: 4),
    title: title,
    subtitle: subtitle,
    leading: Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: highlighted ? AppColors.weakBackground : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Icon(
        icon,
        color: highlighted ? AppColors.primary : AppColors.body,
      ),
    ),
    onTap: () => AppToast.show(context, message: '화면 연결 준비 중이에요.'),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      row(context, Icons.receipt_long, '거래 내역', '충전 · 구매 기록'),
      row(context, Icons.account_balance, '크레딧 충전', '계좌이체 · QR'),
      if (user.canViewClass)
        row(
          context,
          Icons.shield,
          '반 인원 확인',
          '반장 · 선생님만 보여요',
          highlighted: true,
        ),
      if (user.canOperate)
        row(
          context,
          Icons.storefront,
          '부스 운영',
          user.operatingBooths.map((booth) => booth['name']).join(' · '),
          highlighted: true,
        ),
    ],
  );
}
