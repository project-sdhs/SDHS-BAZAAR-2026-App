import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/payment_models.dart';
import '../../../state/credit_store.dart';
import '../../components/buttons/buttons.dart';
import '../../components/credit_amount/credit_amounts.dart';

// 차감 결과를 받은 뒤에만 receipt 화면으로 이동합니다.
enum _PaymentStage { selection, processing, receipt, insufficient }

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.booth});
  final PaymentBooth booth;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final Map<int, int> _quantities = {};
  _PaymentStage _stage = _PaymentStage.selection;
  PaymentReceipt? _receipt;
  String? _error;

  List<OrderLine> get _items => [
    for (final menu in widget.booth.menus)
      if ((_quantities[menu.id] ?? 0) > 0)
        OrderLine(menu: menu, quantity: _quantities[menu.id]!),
  ];
  int get _total => _items.fold(0, (sum, line) => sum + line.amount);

  Future<void> _pay() async {
    if (_stage == _PaymentStage.processing || _items.isEmpty) return;
    final store = context.read<CreditStore>();
    if (_total > store.balance) {
      setState(() => _stage = _PaymentStage.insufficient);
      return;
    }
    final items = _items;
    setState(() {
      _stage = _PaymentStage.processing;
      _error = null;
    });
    try {
      final receipt = await store.pay(widget.booth, items);
      if (!mounted) return;
      setState(() {
        _receipt = receipt;
        _stage = _PaymentStage.receipt;
      });
    } on PaymentException catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = error.code == 'INSUFFICIENT_CREDIT'
            ? _PaymentStage.insufficient
            : _PaymentStage.selection;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _stage = _PaymentStage.selection;
        _error = '결제 결과를 확인하지 못했어요. 잠시 후 다시 시도해 주세요.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    final processing = _stage == _PaymentStage.processing;
    return PopScope(
      canPop: !processing,
      child: Scaffold(
        backgroundColor: _stage == _PaymentStage.selection
            ? AppColors.scannerBackground
            : AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: '결제 화면 닫기',
                  color: _stage == _PaymentStage.selection
                      ? AppColors.onPrimary
                      : AppColors.foreground,
                  icon: const Icon(Icons.close),
                  onPressed: processing ? null : () => context.pop(),
                ),
              ),
              if (_stage == _PaymentStage.selection) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  child: Text(
                    '✓ QR을 인식했어요',
                    style: AppTypography.body.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(
                        _stage == _PaymentStage.selection ? 24 : 0,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (store.isPreview)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.s16,
                            ),
                            child: Text(
                              '디자인 미리보기 · 예시 데이터',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.muted,
                              ),
                            ),
                          ),
                        switch (_stage) {
                          _PaymentStage.selection => _selection(store),
                          _PaymentStage.processing => _processing(),
                          _PaymentStage.receipt => _completed(_receipt!),
                          _PaymentStage.insufficient => _insufficient(store),
                        },
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomActions(store),
      ),
    );
  }

  Widget _selection(CreditStore store) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _BoothHeader(booth: widget.booth),
      const SizedBox(height: AppSpacing.s24),
      if (!widget.booth.isOpen)
        _notice('지금은 주문을 받지 않는 부스예요. 운영 중일 때 다시 방문해 주세요.', danger: true)
      else ...[
        Row(
          children: [
            Expanded(
              child: Text(
                '메뉴 고르기',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${_items.length}개 선택',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        for (final menu in widget.booth.menus) _menuRow(menu),
        const SizedBox(height: AppSpacing.s16),
        _card(
          Column(
            children: [
              _AmountRow(label: '결제 금액', amount: _total, bold: true),
              const SizedBox(height: AppSpacing.s8),
              _AmountRow(
                label: '결제 후 잔액',
                amount: store.balance - _total,
                tone: _total > store.balance
                    ? CreditAmountTone.danger
                    : CreditAmountTone.secondary,
              ),
            ],
          ),
        ),
      ],
      if (_error case final error?) ...[
        const SizedBox(height: AppSpacing.s16),
        _notice(error, danger: true),
      ],
    ],
  );

  Widget _menuRow(MenuItem menu) {
    final quantity = _quantities[menu.id] ?? 0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          Opacity(
            opacity: menu.onSale ? 1 : 0.4,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.r14),
              ),
              alignment: Alignment.center,
              child: Text(menu.emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu.name,
                  style: AppTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: menu.onSale ? AppColors.foreground : AppColors.muted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                AppCreditAmount(
                  amount: menu.price,
                  type: CreditAmountType.body,
                  tone: menu.onSale
                      ? CreditAmountTone.secondary
                      : CreditAmountTone.muted,
                  soldOut: !menu.onSale,
                ),
              ],
            ),
          ),
          if (!menu.onSale)
            Text(
              '품절',
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (quantity > 0) ...[
                  _quantityButton(menu, quantity - 1, Icons.remove, '수량 줄이기'),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '$quantity',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                _quantityButton(menu, quantity + 1, Icons.add, '수량 늘리기'),
              ],
            ),
        ],
      ),
    );
  }

  Widget _quantityButton(
    MenuItem menu,
    int quantity,
    IconData icon,
    String label,
  ) => IconButton(
    tooltip: '${menu.name} $label',
    style: IconButton.styleFrom(
      backgroundColor: icon == Icons.add
          ? AppColors.weakBackground
          : AppColors.surface,
      foregroundColor: AppColors.primary,
      minimumSize: const Size(40, 40),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
    ),
    iconSize: 18,
    onPressed: quantity > 99
        ? null
        : () => setState(() => _quantities[menu.id] = quantity),
    icon: Icon(icon),
  );

  Widget _processing() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('결제하고 있어요', style: AppTypography.h3),
      const SizedBox(height: AppSpacing.s8),
      Text(
        '크레딧이 빠져나가면 결제 번호가 나와요.\n화면을 닫지 말고 잠깐만 기다려 주세요.',
        style: AppTypography.body.copyWith(color: AppColors.body),
      ),
      const SizedBox(height: AppSpacing.s32),
      _step(
        '주문 확인',
        '${widget.booth.name} · 메뉴 ${_items.length}개',
        complete: true,
      ),
      _step(
        '크레딧 빼는 중',
        '${AppCreditAmount.format(_total)} 크레딧을 결제하고 있어요',
        loading: true,
      ),
      _step('결제 번호 받기', '차감이 끝나면 바로 보여 드려요'),
      const SizedBox(height: AppSpacing.s24),
      _card(
        Column(
          children: [
            _BoothHeader(booth: widget.booth),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Divider(),
            ),
            ..._orderRows(_items),
            const SizedBox(height: AppSpacing.s16),
            _AmountRow(label: '결제할 금액', amount: _total, bold: true),
          ],
        ),
      ),
    ],
  );

  Widget _step(
    String title,
    String description, {
    bool complete = false,
    bool loading = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: loading
              ? const CircularProgressIndicator(strokeWidth: 3)
              : Icon(
                  complete ? Icons.check_circle : Icons.circle_outlined,
                  color: complete ? AppColors.primary : AppColors.border,
                  size: 28,
                ),
        ),
        const SizedBox(width: AppSpacing.s16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: complete || loading
                      ? AppColors.foreground
                      : AppColors.muted,
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _completed(PaymentReceipt receipt) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _resultHeading(
        '결제가 끝났어요',
        '${AppCreditAmount.format(receipt.total)} 크레딧이 빠져나갔어요',
      ),
      _card(
        Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '결제 번호',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '받을 때 이 번호를 보여 주세요',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.body,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${receipt.number}',
                  key: const Key('paymentNumber'),
                  style: AppTypography.h1.copyWith(
                    color: AppColors.primary,
                    fontSize: 52,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Divider(),
            ),
            _BoothHeader(booth: receipt.booth),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.s24),
      Text(
        '주문한 메뉴',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: AppSpacing.s8),
      ..._orderRows(receipt.items),
      const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
        child: Divider(),
      ),
      _AmountRow(label: '결제 전 크레딧', amount: receipt.balanceBefore),
      const SizedBox(height: AppSpacing.s8),
      _AmountRow(label: '결제', amount: -receipt.total, bold: true),
      const SizedBox(height: AppSpacing.s8),
      _AmountRow(
        label: '남은 크레딧',
        amount: receipt.balanceAfter,
        bold: true,
        tone: CreditAmountTone.charge,
      ),
      const SizedBox(height: AppSpacing.s8),
      Text(
        '${_paidAtLabel(receipt.paidAt)} · 거래 내역에도 남아 있어요',
        style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
      ),
    ],
  );

  String _paidAtLabel(DateTime paidAt) {
    final seoul = paidAt.toUtc().add(const Duration(hours: 9));
    final hour = seoul.hour.toString().padLeft(2, '0');
    final minute = seoul.minute.toString().padLeft(2, '0');
    return '${seoul.month}월 ${seoul.day}일 $hour:$minute';
  }

  Widget _insufficient(CreditStore store) => Column(
    children: [
      _resultHeading(
        '크레딧이 부족해요',
        '${AppCreditAmount.format((_total - store.balance).clamp(0, _total))} 크레딧을 더 충전하면 결제할 수 있어요',
        danger: true,
      ),
      _card(
        Column(
          children: [
            _BoothHeader(booth: widget.booth),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Divider(),
            ),
            _AmountRow(label: '결제할 금액', amount: _total),
            const SizedBox(height: AppSpacing.s8),
            _AmountRow(label: '보유 크레딧', amount: store.balance),
            const SizedBox(height: AppSpacing.s8),
            _AmountRow(
              label: '부족한 크레딧',
              amount: (_total - store.balance).clamp(0, _total),
              bold: true,
              tone: CreditAmountTone.danger,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.s16),
      _notice('크레딧은 빠져나가지 않았어요'),
    ],
  );

  Widget _resultHeading(
    String title,
    String description, {
    bool danger = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s24),
    child: Center(
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: danger ? AppColors.dangerWeak : AppColors.primary,
            ),
            child: Icon(
              danger ? Icons.error : Icons.check,
              color: danger ? AppColors.danger : AppColors.onPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.s8),
          Text(
            description,
            style: AppTypography.body.copyWith(color: AppColors.body),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  List<Widget> _orderRows(List<OrderLine> items) => [
    for (final line in items)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: _AmountRow(
          label: '${line.menu.name} × ${line.quantity}',
          amount: line.amount,
        ),
      ),
  ];

  Widget _bottomActions(CreditStore store) {
    final total = AppCreditAmount.format(_total);
    return switch (_stage) {
      _PaymentStage.selection => BottomCTA(
        buttons: [
          AppButton(
            '다시 스캔',
            variant: AppButtonVariant.light,
            onPressed: () => context.pop(),
          ),
          AppButton(
            '$total 결제하기',
            key: const Key('submitPayment'),
            enabled: _items.isNotEmpty && widget.booth.isOpen,
            onPressed: _pay,
          ),
        ],
      ),
      _PaymentStage.processing => BottomCTA(
        buttons: [const AppButton('결제 중이에요', onPressed: null)],
      ),
      _PaymentStage.receipt => BottomCTA(
        buttons: [
          AppButton(
            '거래 내역',
            variant: AppButtonVariant.light,
            onPressed: () => context.pushReplacement(Routes.transactions),
          ),
          AppButton('확인', onPressed: () => context.pop()),
        ],
      ),
      _PaymentStage.insufficient => BottomCTA(
        buttons: [
          AppButton(
            '다시 스캔',
            variant: AppButtonVariant.light,
            onPressed: () => context.pop(),
          ),
          AppButton(
            '충전하러 가기',
            onPressed: () async {
              await context.push(Routes.credit);
              if (mounted) setState(() => _stage = _PaymentStage.selection);
            },
          ),
        ],
      ),
    };
  }

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.s16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.r16),
    ),
    child: child,
  );

  Widget _notice(String message, {bool danger = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(AppSpacing.s16),
    decoration: BoxDecoration(
      color: danger ? AppColors.dangerWeak : AppColors.weakBackground,
      borderRadius: BorderRadius.circular(AppRadius.r14),
    ),
    child: Text(
      message,
      style: AppTypography.bodySmall.copyWith(
        color: danger ? AppColors.danger : AppColors.weakForeground,
      ),
    ),
  );
}

class _BoothHeader extends StatelessWidget {
  const _BoothHeader({required this.booth});
  final PaymentBooth booth;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.weakBackground,
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        child: const Icon(
          Icons.storefront_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
      const SizedBox(width: AppSpacing.s16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(booth.name, style: AppTypography.h4),
            Text(
              booth.location,
              style: AppTypography.bodySmall.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    ],
  );
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.bold = false,
    this.tone = CreditAmountTone.secondary,
  });
  final String label;
  final int amount;
  final bool bold;
  final CreditAmountTone tone;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: tone.color,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.s8),
      Flexible(
        child: Align(
          alignment: Alignment.centerRight,
          child: AppCreditAmount(
            amount: amount,
            type: CreditAmountType.body,
            tone: tone,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
