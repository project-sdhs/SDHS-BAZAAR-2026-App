import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/payment_models.dart';
import '../../../state/credit_store.dart';
import '../../components/buttons/buttons.dart';
import '../../components/credit_amount/credit_amounts.dart';
import '../../components/feedback/feedback.dart';
import '../../components/inputs/inputs.dart';
import '../../navigation/app_top_bar.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({super.key});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  final _amountController = TextEditingController(text: '10,000');
  int? _dismissedRequestId;
  bool _submitting = false;
  bool _refreshing = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  int? get _amount {
    final text = _amountController.text.replaceAll(',', '');
    if (!RegExp(r'^\d+$').hasMatch(text)) return null;
    return int.tryParse(text);
  }

  void _onAmountChanged(String value) {
    final digits = value.replaceAll(',', '');
    final amount = int.tryParse(digits);
    if (RegExp(r'^\d+$').hasMatch(digits) && amount != null) {
      final selection = _amountController.selection;
      final cursor = selection.isValid
          ? selection.extentOffset.clamp(0, value.length)
          : value.length;
      final digitsBeforeCursor = value
          .substring(0, cursor)
          .replaceAll(',', '')
          .length;
      final formatted = AppCreditAmount.format(amount);
      var formattedCursor = 0;
      var digitCount = 0;
      while (formattedCursor < formatted.length &&
          digitCount < digitsBeforeCursor) {
        if (formatted[formattedCursor] != ',') digitCount++;
        formattedCursor++;
      }
      _amountController.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formattedCursor),
      );
    }
    setState(() {});
  }

  void _addAmount(int increment) {
    final amount = _amount;
    if (amount == null) return;
    final nextAmount = amount + increment;
    if (nextAmount <= amount) {
      AppToast.show(
        context,
        message: '더 큰 금액은 입력할 수 없어요',
        type: AppToastType.error,
      );
      return;
    }
    final text = AppCreditAmount.format(nextAmount);
    _amountController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    setState(() {});
  }

  String? _validationMessage(CreditStore store) {
    if (_amountController.text.isEmpty) return '충전할 금액을 입력해주세요';
    final amount = _amount;
    if (amount == null) return '금액은 숫자로 입력해주세요';
    final settings = store.settings;
    if (amount < settings.minimumAmount) {
      return '${AppCreditAmount.format(settings.minimumAmount)}원부터 충전할 수 있어요';
    }
    if (settings.maximumAmount case final maximum? when amount > maximum) {
      return '한 번에 ${AppCreditAmount.format(maximum)}원까지 충전할 수 있어요';
    }
    if (settings.balanceLimit case final limit
        when limit != null && amount > limit - store.balance) {
      final available = limit > store.balance ? limit - store.balance : 0;
      return '보유 한도에 따라 ${AppCreditAmount.format(available)}원까지 충전할 수 있어요';
    }
    return null;
  }

  Future<void> _requestCharge(CreditStore store) async {
    if (_submitting || _validationMessage(store) != null) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      await store.requestCharge(_amount!);
      if (mounted) setState(() => _dismissedRequestId = null);
    } catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          message: error is PaymentException
              ? error.message
              : '충전 요청을 보내지 못했어요. 다시 시도해주세요',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refreshCharge(CreditStore store) async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final request = await store.refreshCharge();
      if (!mounted) return;
      if (request?.status == ChargeStatus.pending ||
          request?.status == ChargeStatus.needsReview) {
        AppToast.show(context, message: '입금 확인 중이에요. 잠시 후 다시 확인해주세요');
      }
    } catch (error) {
      if (mounted) {
        AppToast.show(
          context,
          message: error is PaymentException
              ? error.message
              : '충전 상태를 확인하지 못했어요. 다시 시도해주세요',
          type: AppToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _copy(String value, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) AppToast.show(context, message: message);
    } catch (_) {
      if (mounted) {
        AppToast.show(
          context,
          message: '복사하지 못했어요. 다시 시도해주세요',
          type: AppToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    final savedRequest = store.chargeRequest;
    final request = savedRequest?.id == _dismissedRequestId
        ? null
        : savedRequest;
    final waiting =
        request?.status == ChargeStatus.pending ||
        request?.status == ChargeStatus.needsReview;
    final validation = _validationMessage(store);
    final eventEnded = store.settings.eventEnded;
    final canRequest = !eventEnded && validation == null && !_submitting;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppTopBar(
                      title: request == null
                          ? '얼마를 충전할까요?'
                          : _statusTitle(request.status),
                      description: request == null
                          ? '계좌이체하면 바로 크레딧이 들어와요'
                          : _statusDescription(request.status),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (store.isPreview) ...[
                            Text(
                              '디자인 미리보기 · 예시 데이터',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s16),
                          ],
                          if (eventEnded) ...[
                            const _Notice(
                              icon: Icons.event_busy_outlined,
                              message: '바자회가 종료되어 충전 요청을 할 수 없어요',
                            ),
                            const SizedBox(height: AppSpacing.s16),
                          ],
                          if (request == null) ...[
                            AppTextField(
                              controller: _amountController,
                              variant: AppTextFieldVariant.hero,
                              semanticLabel: '충전 금액',
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.done,
                              enabled: !_submitting && !eventEnded,
                              errorText: validation,
                              onChanged: _onAmountChanged,
                              onSubmitted: (_) {
                                if (canRequest) _requestCharge(store);
                              },
                              suffix: Padding(
                                padding: const EdgeInsets.all(AppSpacing.s8),
                                child: Image.asset(
                                  'assets/images/credit_coin.png',
                                  width: 28,
                                  height: 28,
                                  excludeFromSemantics: true,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            Wrap(
                              spacing: AppSpacing.s8,
                              runSpacing: AppSpacing.s8,
                              children: [
                                for (final increment in [5000, 10000, 30000])
                                  AppButton(
                                    '+${AppCreditAmount.format(increment)}',
                                    size: AppButtonSize.small,
                                    variant: AppButtonVariant.light,
                                    onPressed:
                                        _submitting ||
                                            eventEnded ||
                                            _amount == null
                                        ? null
                                        : () => _addAmount(increment),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            Text(
                              '1크레딧 = 1원 · 2026 바자회에서만 쓸 수 있고 환불되지 않아요',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ] else
                            _RequestStatus(
                              request: request,
                              balance: store.balance,
                            ),
                          const SizedBox(height: AppSpacing.s24),
                          if ((request == null && !eventEnded) || waiting) ...[
                            _accountCard(store),
                            const SizedBox(height: AppSpacing.s16),
                            _depositorCard(
                              request?.depositorName ?? store.depositorName,
                            ),
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              '입금자명이 다르면 자동 확인이 안 돼서 처리가 늦어져요',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.s24),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            BottomCTA(
              buttons: [
                if (waiting)
                  AppButton(
                    '입금 확인하기',
                    loading: _refreshing,
                    onPressed: () => _refreshCharge(store),
                  )
                else if (request != null)
                  AppButton(
                    '다시 충전하기',
                    enabled: !eventEnded,
                    onPressed: () =>
                        setState(() => _dismissedRequestId = request.id),
                  )
                else
                  AppButton(
                    eventEnded
                        ? '충전이 종료됐어요'
                        : '${AppCreditAmount.format(_amount ?? 0)}원 충전 요청',
                    enabled: canRequest,
                    loading: _submitting,
                    onPressed: () => _requestCharge(store),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _accountCard(CreditStore store) {
    final account = store.settings.account;
    final hasAccount =
        !store.isPreview &&
        account.bank.trim().isNotEmpty &&
        account.holder.trim().isNotEmpty &&
        account.accountNo.replaceAll(RegExp(r'\D'), '').length >= 6;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '입금 계좌',
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: hasAccount
                    ? () => _copy(account.accountNo, '계좌번호를 복사했어요')
                    : null,
                child: const Text('복사'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          _AccountRow(label: '은행', value: account.bank),
          const SizedBox(height: AppSpacing.s8),
          _AccountRow(label: '계좌번호', value: account.accountNo),
          const SizedBox(height: AppSpacing.s8),
          _AccountRow(label: '예금주', value: account.holder),
        ],
      ),
    );
  }

  Widget _depositorCard(String name) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.weakBackground,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '입금자명을 이렇게 보내주세요',
            style: AppTypography.body.copyWith(
              color: AppColors.weakForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          Container(
            padding: const EdgeInsets.only(left: AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.canvas,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name.isEmpty ? '입금자명 확인 중' : name,
                    style: AppTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: '입금자명 복사',
                  onPressed: name.trim().isEmpty
                      ? null
                      : () => _copy(name, '입금자명을 복사했어요'),
                  icon: const Icon(Icons.copy_outlined, size: 20),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _statusTitle(ChargeStatus status) => switch (status) {
    ChargeStatus.pending => '충전 요청을 보냈어요',
    ChargeStatus.approved => '충전이 완료됐어요',
    ChargeStatus.rejected => '충전 요청을 확인해주세요',
    ChargeStatus.needsReview => '입금 내역을 확인하고 있어요',
  };

  String _statusDescription(ChargeStatus status) => switch (status) {
    ChargeStatus.pending => '안내된 계좌로 입금하면 확인 후 크레딧이 들어와요',
    ChargeStatus.approved => '크레딧으로 바자회를 즐겨보세요',
    ChargeStatus.rejected => '아래 사유를 확인하고 다시 요청해주세요',
    ChargeStatus.needsReview => '입금자명과 금액을 확인하고 있어요',
  };
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 68,
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
        ),
      ),
      const SizedBox(width: AppSpacing.s8),
      Expanded(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: AppTypography.bodySmall.copyWith(color: AppColors.body),
        ),
      ),
    ],
  );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.s16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r16),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.muted, size: 20),
        const SizedBox(width: AppSpacing.s8),
        Expanded(
          child: Text(
            message,
            style: AppTypography.bodySmall.copyWith(color: AppColors.body),
          ),
        ),
      ],
    ),
  );
}

class _RequestStatus extends StatelessWidget {
  const _RequestStatus({required this.request, required this.balance});

  final ChargeRequest request;
  final int balance;

  @override
  Widget build(BuildContext context) {
    final approved = request.status == ChargeStatus.approved;
    final rejected = request.status == ChargeStatus.rejected;
    final statusLabel = switch (request.status) {
      ChargeStatus.pending => '입금 확인 대기',
      ChargeStatus.approved => '충전 완료',
      ChargeStatus.rejected => '충전 반려',
      ChargeStatus.needsReview => '운영진 확인 중',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s24),
      decoration: BoxDecoration(
        color: rejected ? AppColors.dangerWeak : AppColors.weakBackground,
        borderRadius: BorderRadius.circular(AppRadius.r16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            approved
                ? Icons.check_circle_outline_rounded
                : rejected
                ? Icons.error_outline_rounded
                : Icons.schedule_rounded,
            color: rejected ? AppColors.danger : AppColors.primary,
            size: 32,
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            statusLabel,
            style: AppTypography.body.copyWith(
              color: rejected ? AppColors.danger : AppColors.weakForeground,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          AppCreditAmount(
            amount: request.amount,
            type: CreditAmountType.frame,
            tone: rejected ? CreditAmountTone.danger : CreditAmountTone.charge,
            showPlus: approved,
          ),
          if (request.reason case final reason? when reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(
              reason,
              style: AppTypography.bodySmall.copyWith(color: AppColors.body),
            ),
          ],
          if (approved) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(
              '현재 보유 크레딧',
              style: AppTypography.bodySmall.copyWith(color: AppColors.body),
            ),
            const SizedBox(height: AppSpacing.s4),
            AppCreditAmount(amount: balance),
          ],
          if (request.status == ChargeStatus.pending) ...[
            const SizedBox(height: AppSpacing.s16),
            Text(
              '입금 확인이 끝나면 잔액에 반영돼요. 확인 중인 요청은 다시 보낼 수 없어요.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.body),
            ),
          ],
        ],
      ),
    );
  }
}
