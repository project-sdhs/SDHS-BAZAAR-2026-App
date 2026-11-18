import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../data/models/my_credit.dart';
import '../../../components/buttons/buttons.dart';
import '../../../components/credit_amount/credit_amounts.dart';
import '../../../components/feedback/feedback.dart';

class MyWallet extends StatelessWidget {
  const MyWallet({super.key, required this.credit});
  final MyCredit credit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.r16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('보유 크레딧'),
            AppCreditAmount(
              amount: credit.balance,
              type: CreditAmountType.tile,
            ),
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                AppButton(
                  '충전하기',
                  icon: Icons.add,
                  onPressed: () =>
                      AppToast.show(context, message: '충전 화면 연결 준비 중이에요.'),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: AppButton(
                    'QR 결제',
                    icon: Icons.qr_code_scanner,
                    variant: AppButtonVariant.light,
                    expand: true,
                    onPressed: () => context.go(Routes.pay),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.s8),
      AppCreditAmount(
        amount: credit.used,
        type: CreditAmountType.caption,
        tone: CreditAmountTone.muted,
        prefix: '이번 바자회에 ',
        suffix: ' 썼어요',
      ),
    ],
  );
}
