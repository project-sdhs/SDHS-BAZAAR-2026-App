import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/api/api_client.dart';
import '../../../data/models/charge_request.dart';
import '../../../data/models/my_user.dart';
import '../../../data/models/payment_exception.dart';
import '../../../data/models/public_settings.dart';
import '../../../state/credit_store.dart';
import '../../../state/depositor_name.dart';
import '../../../state/idempotency.dart';
import '../../components/basic/basic.dart';
import '../../components/buttons/buttons.dart';
import '../../components/credit_amount/credit_amounts.dart';
import '../../components/feedback/feedback.dart';
import '../../components/inputs/inputs.dart';
import '../../navigation/app_top_bar.dart';

/// 크레딧 충전 (APP-53~57): 금액 입력 → 충전 요청 → 입금 안내 → 승인 확인.
class CreditPage extends StatefulWidget {
  const CreditPage({super.key, this.user = mockStudent});

  /// 입금자명을 만들 사용자.
  // TODO(auth): 로그인(`GET /users/me`)을 붙이면 로그인한 사용자를 넘깁니다.
  final MyUser user;

  /// 입금 확인 중인 요청을 다시 읽는 간격 (명세: 10초)
  static const pollInterval = Duration(seconds: 10);

  /// 금액 칩
  static const quickAmounts = [5000, 10000, 30000];

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> {
  final _amountController = TextEditingController(text: '10,000');
  late final CreditStore _store;
  bool _submitting = false;
  bool _refreshing = false;

  /// 서버가 400/422 `fields.amount` 로 알려 준 이유. 금액을 바꾸면 지웁니다.
  String? _serverAmountError;

  /// 이 금액의 `Idempotency-Key`. 응답을 못 받았으면 다시 누를 때 그대로 쓰고,
  /// 성공 · 서버 거절 · 금액 변경 때 버립니다.
  String? _chargeKey;
  int? _chargeKeyAmount;

  Timer? _pollTimer;
  bool _polling = false;

  @override
  void initState() {
    super.initState();
    _store = context.read<CreditStore>()..addListener(_syncPolling);
    _syncPolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _store.removeListener(_syncPolling);
    _amountController.dispose();
    super.dispose();
  }

  /// 입금 확인 중(pending · needs_review)인 요청이 있는 동안만 10초마다 상태를 읽습니다.
  void _syncPolling() {
    final waiting = _store.chargeRequest?.status.isWaiting ?? false;
    if (waiting) {
      _pollTimer ??= Timer.periodic(CreditPage.pollInterval, (_) => _poll());
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  Future<void> _poll() async {
    if (_polling || _store.chargeRequest == null) return;
    _polling = true;
    try {
      await _store.refreshChargeRequest();
    } catch (_) {
      // 다음 주기에 다시 읽습니다.
    } finally {
      _polling = false;
    }
  }

  /// 입력한 금액. 비어 있으면 0, 숫자가 아니면 null.
  int? get _amount {
    final text = _amountController.text.replaceAll(',', '');
    if (text.isEmpty) return 0;
    if (!RegExp(r'^\d+$').hasMatch(text)) return null;
    return int.tryParse(text);
  }

  void _amountChanged() {
    _serverAmountError = null;
    if (_chargeKeyAmount != _amount) _forgetKey();
  }

  void _forgetKey() {
    _chargeKey = null;
    _chargeKeyAmount = null;
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
    setState(_amountChanged);
  }

  /// 금액 칩: 지금 금액에 더합니다 (빈 칸은 0).
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
    setState(_amountChanged);
  }

  String? _validationMessage(PublicSettings settings) {
    if (_amountController.text.isEmpty) return '충전할 금액을 입력해주세요';
    final amount = _amount;
    if (amount == null) return '금액은 숫자로 입력해주세요';
    if (amount < settings.chargeMin) {
      return '${AppCreditAmount.format(settings.chargeMin)}원부터 충전할 수 있어요';
    }
    if (settings.chargeMax case final maximum? when amount > maximum) {
      return '한 번에 ${AppCreditAmount.format(maximum)}원까지 충전할 수 있어요';
    }
    // 보유 한도: 잔액 + 확인 중인 충전 + 이번 충전 ≤ 한도
    if (settings.balanceLimit case final limit?) {
      final available = limit - _store.balance - _store.pendingChargeAmount;
      if (amount > available) {
        return available > 0
            ? '보유 한도 때문에 ${AppCreditAmount.format(available)}원까지 충전할 수 있어요'
            : '보유 한도가 다 차서 지금은 충전할 수 없어요';
      }
    }
    return null;
  }

  Future<void> _requestCharge(PublicSettings settings) async {
    if (_submitting ||
        _store.isEventEnded ||
        _serverAmountError != null ||
        _validationMessage(settings) != null) {
      return;
    }
    final amount = _amount!;
    if (_chargeKey == null || _chargeKeyAmount != amount) {
      _chargeKey = newIdempotencyKey();
      _chargeKeyAmount = amount;
    }
    FocusScope.of(context).unfocus();
    setState(() => _submitting = true);
    try {
      final result = await _store.requestCharge(
        amount,
        idempotencyKey: _chargeKey!,
      );
      _forgetKey();
      if (mounted && !result.created) {
        AppToast.show(context, message: '이미 보낸 충전 요청이 있어요');
      }
    } on PaymentException catch (error) {
      if (error.code != PaymentErrorCode.idempotencyInProgress) _forgetKey();
      if (mounted) _showChargeError(error);
    } on ApiNetworkException {
      // 서버가 받았는지 모르므로 키를 남겨 두고, 다시 누르면 같은 키로 보냅니다.
      _toastError('충전 요청을 보내지 못했어요. 연결을 확인하고 다시 눌러 주세요');
    } catch (_) {
      _toastError('충전 요청을 보내지 못했어요. 다시 시도해주세요');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showChargeError(PaymentException error) {
    switch (error.code) {
      case PaymentErrorCode.eventEnded:
        // CreditStore 가 종료 상태로 바꿉니다.
        break;
      case PaymentErrorCode.validationFailed:
        final reason = error.fields['amount'];
        if (reason != null) {
          setState(() => _serverAmountError = reason);
        } else {
          _toastError(error.message);
        }
      case PaymentErrorCode.rateLimited:
        final seconds = error.retryAfter?.inSeconds;
        _toastError(
          seconds == null
              ? '충전 요청이 많아요. 잠시 뒤 다시 시도해 주세요'
              : '충전 요청이 많아요. $seconds초 뒤 다시 시도해 주세요',
        );
      case PaymentErrorCode.appNotOpen:
        _toastError('바자회 앱이 아직 열리지 않았어요');
      case PaymentErrorCode.idempotencyInProgress:
        _toastError('충전 요청을 처리하고 있어요. 잠시 뒤 다시 눌러 주세요');
      default:
        _toastError(error.message);
    }
  }

  Future<void> _refreshCharge() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    try {
      final request = await _store.refreshChargeRequest();
      if (mounted && request.status.isWaiting) {
        AppToast.show(context, message: '입금 확인 중이에요. 잠시 후 다시 확인해주세요');
      }
    } on PaymentException catch (error) {
      _toastError(error.message);
    } catch (_) {
      _toastError('충전 상태를 확인하지 못했어요. 다시 시도해주세요');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _toastError(String message) {
    if (!mounted) return;
    AppToast.show(context, message: message, type: AppToastType.error);
  }

  Future<void> _copy(String value, String message) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) AppToast.show(context, message: message);
    } catch (_) {
      _toastError('복사하지 못했어요. 다시 시도해주세요');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    final settings = store.settings;
    if (settings == null || !store.isReady) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            children: [
              const AppTopBar(title: '얼마를 충전할까요?'),
              if (store.isLoading)
                const _LoadingBody()
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 300),
                  child: AppEmptyState(
                    title: _loadErrorTitle(store.error),
                    message: '잠시 뒤에 다시 시도해 주세요',
                    icon: Icons.wifi_off,
                    actionLabel: '다시 시도',
                    onAction: store.refresh,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    final request = store.chargeRequest;
    final ended = store.isEventEnded;
    final waiting = request?.status.isWaiting ?? false;
    final validation = _serverAmountError ?? _validationMessage(settings);
    final canRequest = !ended && validation == null && !_submitting;
    final amount = _amount;
    final account = request == null
        ? settings.depositAccount
        : request.depositAccount ?? settings.depositAccount;
    final depositorName =
        request?.depositorName ??
        buildDepositorName(
          settings,
          name: widget.user.name,
          studentNo: widget.user.studentNo,
          depositCode: widget.user.depositCode,
        );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (request == null)
                AppTopBar(
                  title: '얼마를 충전할까요?',
                  description: ended
                      ? '바자회가 끝나 충전할 수 없어요'
                      : '계좌이체하면 바로 크레딧이 들어와요',
                  descriptionColor: ended ? AppColors.danger : AppColors.muted,
                )
              else
                AppTopBar(
                  title: _statusTitle(request.status),
                  description: _statusDescription(request.status),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (request == null) ...[
                      AppTextField(
                        controller: _amountController,
                        variant: AppTextFieldVariant.hero,
                        semanticLabel: '충전 금액',
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        enabled: !_submitting && !ended,
                        errorText: ended ? null : validation,
                        onChanged: _onAmountChanged,
                        onSubmitted: (_) {
                          if (canRequest) _requestCharge(settings);
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
                      Row(
                        children: [
                          for (final (index, increment)
                              in CreditPage.quickAmounts.indexed) ...[
                            if (index > 0) const SizedBox(width: AppSpacing.s8),
                            Expanded(
                              child: AppButton(
                                '+${AppCreditAmount.format(increment)}',
                                size: AppButtonSize.medium,
                                variant: AppButtonVariant.light,
                                expand: true,
                                onPressed:
                                    _submitting || ended || amount == null
                                    ? null
                                    : () => _addAmount(increment),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s16),
                      Text(
                        '1크레딧 = 1원 · 2026 바자회에서만 쓸 수 있고, 환불되지 않아요',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ] else
                      _RequestStatus(request: request, balance: store.balance),
                    if (request == null || waiting) ...[
                      const SizedBox(height: AppSpacing.s24),
                      _AccountCard(
                        account: account,
                        onCopy: (accountNo) => _copy(accountNo, '계좌번호를 복사했어요'),
                      ),
                      const SizedBox(height: AppSpacing.s24),
                      _DepositorCard(
                        name: depositorName,
                        onCopy: () => _copy(depositorName, '입금자명을 복사했어요'),
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
      bottomNavigationBar: BottomCTA(
        buttons: [
          if (waiting)
            AppButton(
              '입금 확인하기',
              loading: _refreshing,
              onPressed: _refreshCharge,
            )
          else if (request != null)
            AppButton(
              '다시 충전하기',
              enabled: !ended,
              onPressed: store.clearChargeRequest,
            )
          else if (ended)
            const AppButton('충전할 수 없어요', enabled: false, onPressed: null)
          else
            AppButton(
              '${AppCreditAmount.format(amount ?? 0)}원 충전 요청',
              enabled: canRequest,
              loading: _submitting,
              onPressed: () => _requestCharge(settings),
            ),
        ],
      ),
    );
  }

  String _loadErrorTitle(Object? error) =>
      error is PaymentException && error.code == PaymentErrorCode.appNotOpen
      ? '바자회 앱이 아직 열리지 않았어요'
      : '충전 정보를 불러오지 못했어요';

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

/// 설정을 읽는 동안 보이는 자리 표시 (금액 줄 · 칩 · 계좌 카드)
class _LoadingBody extends StatelessWidget {
  const _LoadingBody();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal: AppSpacing.s16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeleton(width: 200, height: 44, radius: 8),
        SizedBox(height: AppSpacing.s16),
        AppSkeleton(height: 38, radius: 10),
        SizedBox(height: AppSpacing.s24),
        AppSkeleton(height: 160, radius: 16),
        SizedBox(height: AppSpacing.s24),
        AppSkeleton(height: 140, radius: 16),
      ],
    ),
  );
}

/// 입금 계좌 카드 (Credit 캔버스: 회색 면 · padding 20 · 제목 17/700 · 복사 아이콘)
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.account, required this.onCopy});

  final DepositAccount? account;
  final ValueChanged<String> onCopy;

  @override
  Widget build(BuildContext context) {
    final account = this.account;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _CopyButton(
                tooltip: '계좌번호 복사',
                color: AppColors.muted,
                onPressed: account == null
                    ? null
                    : () => onCopy(account.accountNo),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (account == null)
            Text(
              '입금 계좌를 준비하고 있어요. 잠시 뒤 다시 확인해 주세요',
              style: AppTypography.body.copyWith(color: AppColors.body),
            )
          else ...[
            _AccountRow(label: '은행', value: account.bank),
            const SizedBox(height: AppSpacing.s8),
            _AccountRow(label: '계좌번호', value: account.accountNo),
            const SizedBox(height: AppSpacing.s8),
            _AccountRow(label: '예금주', value: account.holder),
          ],
        ],
      ),
    );
  }
}

/// 입금자명 카드 (Credit 캔버스: 파란 면 · 이름 칩은 글자 폭만큼)
class _DepositorCard extends StatelessWidget {
  const _DepositorCard({required this.name, required this.onCopy});

  final String name;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
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
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.weakForeground,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Flexible(
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s8,
                ),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                ),
                child: Text(
                  name,
                  style: AppTypography.body.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.s8),
            _CopyButton(
              tooltip: '입금자명 복사',
              color: AppColors.weakForeground,
              onPressed: name.trim().isEmpty ? null : onCopy,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          '입금자명이 다르면 자동 확인이 안 돼서 처리가 늦어져요',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.weakForeground,
          ),
        ),
      ],
    ),
  );
}

class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final String tooltip;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    icon: const Icon(Icons.content_copy_rounded, size: 20),
    color: color,
    visualDensity: VisualDensity.compact,
  );
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
        width: 72,
        child: Text(
          label,
          style: AppTypography.body.copyWith(color: AppColors.muted),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          value,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ],
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
              '입금 확인이 끝나면 잔액에 반영돼요. 10초마다 자동으로 확인해요.',
              style: AppTypography.bodySmall.copyWith(color: AppColors.body),
            ),
          ],
        ],
      ),
    );
  }
}
