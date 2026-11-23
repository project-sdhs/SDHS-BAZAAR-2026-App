import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/my_user.dart';
import '../../../state/credit_store.dart';
import '../../components/basic/basic.dart';
import '../../components/buttons/buttons.dart';
import '../../components/credit_amount/credit_amounts.dart';
import 'widgets/my_profile.dart';

class MyPage extends StatelessWidget {
  const MyPage({super.key, this.user = mockStudent});
  final MyUser user;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
          children: [
            MyProfile(user: user),
            const SizedBox(height: AppSpacing.s24),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '보유 크레딧',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  AppCreditAmount(
                    amount: store.balance,
                    type: CreditAmountType.tile,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          '충전하기',
                          onPressed: () => context.push(Routes.credit),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s8),
                      Expanded(
                        child: AppButton(
                          'QR 결제',
                          variant: AppButtonVariant.light,
                          onPressed: () => context.go(Routes.pay),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            AppListRow(
              title: '거래 내역',
              subtitle: '충전 · 구매 기록',
              leading: const Icon(
                Icons.receipt_long_outlined,
                color: AppColors.body,
              ),
              onTap: () => context.push(Routes.transactions),
            ),
            AppListRow(
              title: '크레딧 충전',
              subtitle: '입금 계좌와 충전 상태 확인',
              leading: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColors.body,
              ),
              onTap: () => context.push(Routes.credit),
            ),
            if (store.isPreview)
              Padding(
                padding: const EdgeInsets.all(AppSpacing.s16),
                child: Text(
                  '디자인 미리보기 · 예시 데이터',
                  style: AppTypography.caption.copyWith(color: AppColors.muted),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
