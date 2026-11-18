import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/api/api_client.dart';
import '../../../../data/models/my_credit.dart';
import '../../../../data/repositories/my_repository.dart';
import '../../../components/buttons/buttons.dart';
import '../../../components/credit_amount/credit_amounts.dart';
import '../../../components/feedback/feedback.dart';

class MyAccountActions extends StatefulWidget {
  const MyAccountActions({
    super.key,
    required this.repository,
    required this.onLogout,
  });
  final MyRepository repository;

  /// 세션을 관리하는 상위 계층에서 실제 인증 해제를 주입합니다.
  final Future<void> Function() onLogout;
  @override
  State<MyAccountActions> createState() => _MyAccountActionsState();
}

class _MyAccountActionsState extends State<MyAccountActions> {
  bool _busy = false;

  Future<void> _perform({required bool deleting}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      MyCredit? credit;
      if (deleting) {
        credit = await widget.repository.getCredit();
        if (!mounted) return;
        if (credit.pendingChargeAmount > 0) {
          AppToast.show(
            context,
            message: '처리 중인 충전이 있어 계정을 삭제할 수 없어요.',
            type: AppToastType.error,
          );
          return;
        }
      }
      if (!mounted) return;
      final confirmed = await AppDialog.show(
        context,
        title: deleting ? '계정을 삭제할까요?' : '로그아웃할까요?',
        message: deleting
            ? '남은 ${AppCreditAmount.format(credit!.balance)} 크레딧이 소멸해요. 삭제 후에는 복구할 수 없어요.'
            : '다시 이용하려면 로그인해야 해요.',
        confirmLabel: deleting ? '계정 삭제' : '로그아웃',
        confirmVariant: AppButtonVariant.fillDanger,
      );
      if (confirmed != true || !mounted) return;
      if (deleting) {
        final forfeited = await widget.repository.deleteAccount();
        if (!mounted) return;
        AppToast.show(
          context,
          message: '${AppCreditAmount.format(forfeited)} 크레딧이 소멸하고 계정이 삭제됐어요.',
        );
      }
      await widget.onLogout();
      if (mounted) context.go(Routes.login);
    } on ApiException catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          message: error.statusCode == 409
              ? '처리 중인 충전이 있어 계정을 삭제할 수 없어요.'
              : error.message,
          type: AppToastType.error,
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          message: '처리하지 못했어요. 다시 시도해 주세요.',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      TextButton(
        onPressed: _busy ? null : () => _perform(deleting: false),
        style: TextButton.styleFrom(foregroundColor: AppColors.danger),
        child: const Text('로그아웃'),
      ),
      TextButton(
        onPressed: _busy ? null : () => _perform(deleting: true),
        style: TextButton.styleFrom(foregroundColor: AppColors.body),
        child: const Text('계정 삭제'),
      ),
    ],
  );
}
