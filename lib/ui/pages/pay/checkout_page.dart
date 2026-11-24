import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/seoul_time.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/payment_exception.dart';
import '../../../data/models/qr_pay.dart';
import '../../../state/credit_store.dart';
import '../../../state/idempotency.dart';
import '../../components/buttons/buttons.dart';
import '../../components/credit_amount/credit_amounts.dart';
import '../../components/feedback/feedback.dart';
import 'booth_paused_page.dart';
import 'widgets/pay_parts.dart';

/// 결제 화면 단계. 서버가 커밋한 결과(200)를 받은 뒤에만 [receipt] 로 갑니다.
enum _Stage {
  /// 메뉴 고르기 (QRPay)
  selection,

  /// 결제 중 (QRPaying)
  processing,

  /// 응답을 받지 못해 결과를 모름. 같은 키로 "결과 다시 확인" 만 할 수 있습니다.
  unknown,

  /// 결제 완료 (QRDone)
  receipt,

  /// 크레딧 부족 (QRFail)
  insufficient,
}

/// 고른 메뉴 한 줄
class _Line {
  const _Line(this.menu, this.quantity);

  final PayMenu menu;
  final int quantity;
  int get amount => menu.price * quantity;
}

/// QR 결제 (APP-60~63): 메뉴 고르기 → 결제 → 영수증 · 잔액 부족 · 결과 확인.
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.info});

  /// `GET /pay/qr/{code}` 결과
  final QrPayInfo info;

  /// 한 메뉴를 고를 수 있는 최대 수량 (명세 `PaymentItemInput.quantity` ≤ 20)
  static const maxQuantity = 20;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  late QrPayInfo _info = widget.info;
  final Map<int, int> _quantities = {};
  _Stage _stage = _Stage.selection;
  PaymentReceipt? _receipt;
  InsufficientCredit? _shortage;

  /// 결제가 거절된 이유 (빨간 안내)
  String? _error;

  /// 메뉴가 바뀌어 장바구니를 고친 안내 (파란 안내)
  String? _menuNotice;
  bool _reloadingMenus = false;

  /// 이 장바구니의 `Idempotency-Key`. 결과를 모를 때는 같은 키로 다시 보내고,
  /// 장바구니가 바뀌거나 서버가 결과(성공 · 거절)를 준 뒤에만 새로 만듭니다.
  String? _payKey;
  String? _payKeyCart;
  PaymentRequest? _request;

  late final CreditStore _store;

  @override
  void initState() {
    super.initState();
    _store = context.read<CreditStore>();
  }

  List<_Line> get _lines => [
    for (final menu in _info.menus)
      if (menu.onSale && (_quantities[menu.id] ?? 0) > 0)
        _Line(menu, _quantities[menu.id]!),
  ];

  int get _total => _lines.fold(0, (sum, line) => sum + line.amount);

  /// 장바구니가 같은지 비교하는 값 (메뉴 · 수량 · 가격)
  String get _cartSignature => [
    for (final line in _lines)
      '${line.menu.id}x${line.quantity}@${line.menu.price}',
  ].join(',');

  /// 결제 전에 확인할 잔액: QR 정보를 읽을 때 받은 값 또는 앱이 아는 최신 잔액.
  int? get _freshBalance => _store.hasBalance ? _store.balance : _info.balance;

  void _setQuantity(PayMenu menu, int quantity) => setState(() {
    if (quantity <= 0) {
      _quantities.remove(menu.id);
    } else {
      _quantities[menu.id] = quantity;
    }
    _error = null;
  });

  Future<void> _pay() async {
    if (_stage == _Stage.processing || _lines.isEmpty || _reloadingMenus) {
      return;
    }
    final total = _total;
    final balance = _freshBalance;
    if (balance != null && total > balance) {
      setState(() {
        _shortage = InsufficientCredit(
          balance: balance,
          total: total,
          shortfall: total - balance,
        );
        _stage = _Stage.insufficient;
      });
      return;
    }

    final cart = _cartSignature;
    if (_payKey == null || _payKeyCart != cart) {
      _payKey = newIdempotencyKey();
      _payKeyCart = cart;
    }
    _request = PaymentRequest(
      qrCode: _info.code,
      source: _info.source,
      items: [
        for (final line in _lines)
          PaymentItem(menuId: line.menu.id, quantity: line.quantity),
      ],
      clientTotal: total,
    );
    await _send();
  }

  /// [_request] 를 [_payKey] 로 보냅니다. "결과 다시 확인" 도 같은 키 · 같은 본문으로 이 함수를 씁니다.
  Future<void> _send() async {
    final request = _request;
    final key = _payKey;
    if (request == null || key == null || _stage == _Stage.processing) return;
    setState(() {
      _stage = _Stage.processing;
      _error = null;
    });
    try {
      final receipt = await _store.pay(request, idempotencyKey: key);
      if (!mounted) return;
      _forgetKey();
      setState(() {
        _receipt = receipt;
        _stage = _Stage.receipt;
      });
    } on PaymentException catch (error) {
      if (!mounted) return;
      if (error.code == PaymentErrorCode.idempotencyInProgress) {
        // 서버가 아직 처리 중: 결과를 모르므로 같은 키를 남겨 둡니다.
        setState(() => _stage = _Stage.unknown);
        return;
      }
      // 서버가 결과를 줬습니다. 같은 키로 다시 보내면 같은 응답이 오므로 키를 버립니다.
      _forgetKey();
      _handleRejected(error);
    } catch (_) {
      // 응답을 못 받음(시간 초과 · 연결 끊김) 또는 읽을 수 없는 응답: 결제됐을 수도 있습니다.
      if (mounted) setState(() => _stage = _Stage.unknown);
    }
  }

  void _forgetKey() {
    _payKey = null;
    _payKeyCart = null;
    _request = null;
  }

  void _handleRejected(PaymentException error) {
    if (BoothPauseNotice.handles(error)) {
      context.pushReplacement(
        Routes.payPaused,
        extra: BoothPauseNotice.fromError(
          error,
          booth: _info.booth,
          fromPayment: true,
        ),
      );
      return;
    }
    switch (error.code) {
      case PaymentErrorCode.insufficientCredit:
        final total = _total;
        setState(() {
          _shortage =
              error.insufficientCredit ??
              InsufficientCredit(
                balance: _store.balance,
                total: total,
                shortfall: total - _store.balance,
              );
          _stage = _Stage.insufficient;
        });
      case PaymentErrorCode.menuChanged:
        unawaited(_reloadMenus());
      case PaymentErrorCode.rateLimited:
        final seconds = error.retryAfter?.inSeconds;
        setState(() {
          _stage = _Stage.selection;
          _error = seconds == null
              ? '결제 요청이 많아요. 잠시 뒤 다시 결제해 주세요'
              : '결제 요청이 많아요. $seconds초 뒤 다시 결제해 주세요';
        });
      default:
        setState(() {
          _stage = _Stage.selection;
          _error = error.message;
        });
    }
  }

  /// 409 `MENU_CHANGED`: QR 정보를 다시 읽어 품절 · 삭제된 메뉴를 빼고, 남은 메뉴는 새 가격으로 둡니다.
  Future<void> _reloadMenus() async {
    final before = {for (final menu in _info.menus) menu.id: menu.name};
    setState(() {
      _stage = _Stage.selection;
      _reloadingMenus = true;
      _menuNotice = null;
    });
    try {
      final fresh = await _store.qrPayInfo(
        QrPayload(_info.code, source: _info.source),
      );
      if (!mounted) return;
      final available = {
        for (final menu in fresh.menus)
          if (menu.onSale) menu.id,
      };
      final removed = [
        for (final id in _quantities.keys)
          if (!available.contains(id)) before[id] ?? '메뉴',
      ];
      setState(() {
        _info = fresh;
        _quantities.removeWhere((id, _) => !available.contains(id));
        _menuNotice = removed.isEmpty
            ? '메뉴 가격이 바뀌었어요. 바뀐 금액을 확인하고 다시 결제해 주세요'
            : '주문할 수 없게 된 메뉴를 뺐어요: ${removed.join(', ')}. 금액을 확인하고 다시 결제해 주세요';
      });
    } on PaymentException catch (error) {
      if (!mounted) return;
      if (BoothPauseNotice.handles(error)) {
        _handleRejected(error);
      } else {
        setState(() => _error = error.message);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = '바뀐 메뉴를 불러오지 못했어요. 다시 스캔해 주세요');
      }
    } finally {
      if (mounted) setState(() => _reloadingMenus = false);
    }
  }

  void _close() {
    if (_stage == _Stage.receipt) {
      context.go(Routes.home);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CreditStore>();
    final processing = _stage == _Stage.processing;
    final dark = _stage == _Stage.selection;
    return PopScope(
      canPop: !processing,
      child: Scaffold(
        backgroundColor: dark ? AppColors.scannerBackground : AppColors.canvas,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: '결제 화면 닫기',
                  color: dark ? AppColors.onPrimary : AppColors.foreground,
                  icon: const Icon(Icons.close),
                  onPressed: processing ? null : _close,
                ),
              ),
              if (dark)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.s16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 20,
                        color: AppColors.onPrimary,
                      ),
                      const SizedBox(width: AppSpacing.s6),
                      Text(
                        'QR을 인식했어요',
                        style: AppTypography.body.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.canvas,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(dark ? 24 : 0),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    child: switch (_stage) {
                      _Stage.selection => _selection(store),
                      _Stage.processing => _processing(),
                      _Stage.unknown => _unknown(),
                      _Stage.receipt => _completed(_receipt!),
                      _Stage.insufficient => _insufficient(_shortage!),
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: _bottomActions(),
      ),
    );
  }

  Widget _boothHeader() => PayBoothHeader.of(
    _info.booth,
    imageUrl: _store.repository.imageUrl(_info.booth.imageUrl),
  );

  Widget _selection(CreditStore store) {
    final lines = _lines;
    final balance = _freshBalance;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _boothHeader(),
        const SizedBox(height: AppSpacing.s24),
        if (_menuNotice case final notice?) ...[
          AppNotice(notice, icon: Icons.info_rounded),
          const SizedBox(height: AppSpacing.s16),
        ],
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
              '${lines.length}개 선택',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.s8),
        if (_reloadingMenus)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
            child: Center(child: CircularProgressIndicator()),
          )
        else
          for (final menu in _info.menus) _menuRow(menu),
        const SizedBox(height: AppSpacing.s16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.r16),
          ),
          child: Column(
            children: [
              PayAmountRow(label: '결제 금액', amount: _total, bold: true),
              if (balance != null) ...[
                const SizedBox(height: AppSpacing.s8),
                PayAmountRow(
                  label: '결제 후 잔액',
                  amount: balance - _total,
                  tone: _total > balance
                      ? CreditAmountTone.danger
                      : CreditAmountTone.secondary,
                ),
              ],
            ],
          ),
        ),
        if (_error case final error?) ...[
          const SizedBox(height: AppSpacing.s16),
          AppNotice(error, tone: AppNoticeTone.danger),
        ],
      ],
    );
  }

  Widget _menuRow(PayMenu menu) {
    final quantity = _quantities[menu.id] ?? 0;
    final imageUrl = _store.repository.imageUrl(menu.imageUrl);
    const placeholder = ColoredBox(
      color: AppColors.surface,
      child: Center(
        child: Icon(Icons.restaurant_rounded, color: AppColors.muted, size: 24),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Row(
        children: [
          Opacity(
            opacity: menu.onSale ? 1 : 0.4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.r14),
              child: SizedBox.square(
                dimension: 48,
                child: imageUrl == null
                    ? placeholder
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stackTrace) =>
                            placeholder,
                      ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
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
    PayMenu menu,
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
    onPressed: quantity > CheckoutPage.maxQuantity || _reloadingMenus
        ? null
        : () => _setQuantity(menu, quantity),
    icon: Icon(icon),
  );

  Widget _orderSummaryCard() {
    final lines = _lines;
    return PayCard(
      child: Column(
        children: [
          _boothHeader(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
            child: Divider(height: 1, color: AppColors.border),
          ),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
              child: PayAmountRow(
                label: '${line.menu.name} × ${line.quantity}',
                amount: line.amount,
                tone: CreditAmountTone.normal,
              ),
            ),
          const SizedBox(height: AppSpacing.s16),
          PayAmountRow(
            label: '결제할 금액',
            amount: _total,
            bold: true,
            tone: CreditAmountTone.normal,
          ),
        ],
      ),
    );
  }

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
        '${_info.booth.name} · 메뉴 ${_lines.length}개',
        complete: true,
      ),
      _step(
        '크레딧 빼는 중',
        '${AppCreditAmount.format(_total)} 크레딧을 결제하고 있어요',
        loading: true,
      ),
      _step('결제 번호 받기', '차감이 끝나면 바로 보여 드려요'),
      const SizedBox(height: AppSpacing.s24),
      _orderSummaryCard(),
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

  Widget _unknown() => Column(
    children: [
      const PayResultHeading(
        title: '결제 결과를 확인하고 있어요',
        description: '연결이 불안정해 결과를 받지 못했어요.\n같은 결제는 두 번 빠져나가지 않아요.',
        icon: Icons.hourglass_top_rounded,
        tone: PayResultTone.neutral,
      ),
      _orderSummaryCard(),
      const SizedBox(height: AppSpacing.s16),
      const AppNotice(
        '"결과 다시 확인"을 누르면 같은 결제의 결과를 다시 받아요',
        icon: Icons.info_rounded,
        tone: AppNoticeTone.neutral,
      ),
    ],
  );

  Widget _completed(PaymentReceipt receipt) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      PayResultHeading(
        title: '결제가 끝났어요',
        description: '크레딧 ${AppCreditAmount.format(receipt.total)}가 빠져나갔어요',
      ),
      PayCard(
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '결제 번호',
                        style: AppTypography.body.copyWith(
                          fontSize: 15,
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
                  '${receipt.no}',
                  key: const Key('paymentNumber'),
                  style: AppTypography.h1.copyWith(
                    color: AppColors.primary,
                    fontSize: 56,
                    height: 64 / 56,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Divider(height: 1, color: AppColors.border),
            ),
            _boothHeader(),
          ],
        ),
      ),
      const SizedBox(height: 20),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '주문한 메뉴',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.s6),
            for (final line in receipt.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s6),
                child: PayAmountRow(
                  label: '${line.name} × ${line.quantity}',
                  amount: line.amount,
                  tone: CreditAmountTone.normal,
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Divider(height: 1, color: AppColors.border),
            ),
            PayAmountRow(label: '결제 전 크레딧', amount: receipt.balanceBefore),
            const SizedBox(height: AppSpacing.s6),
            PayAmountRow(
              label: '결제',
              amount: -receipt.total,
              bold: true,
              tone: CreditAmountTone.normal,
            ),
            const SizedBox(height: AppSpacing.s6),
            PayAmountRow(
              label: '남은 크레딧',
              amount: receipt.balanceAfter,
              bold: true,
              tone: CreditAmountTone.charge,
            ),
            const SizedBox(height: AppSpacing.s6),
            Text(
              '${_paidAtLabel(receipt.paidAt)} · 거래 내역에도 남아요',
              style: AppTypography.caption.copyWith(
                fontSize: 13,
                color: AppColors.muted,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  String _paidAtLabel(DateTime paidAt) {
    final seoul = toSeoul(paidAt);
    return '${seoul.month}월 ${seoul.day}일 ${seoulHourMinute(paidAt)}';
  }

  Widget _insufficient(InsufficientCredit shortage) => Column(
    children: [
      PayResultHeading(
        title: '크레딧이 부족해요',
        description:
            '${AppCreditAmount.format(shortage.shortfall)} 크레딧을 더 충전하면 결제할 수 있어요',
        icon: Icons.error,
        tone: PayResultTone.danger,
      ),
      PayCard(
        child: Column(
          children: [
            _boothHeader(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.s16),
              child: Divider(height: 1, color: AppColors.border),
            ),
            PayAmountRow(label: '결제할 금액', amount: shortage.total),
            const SizedBox(height: AppSpacing.s6),
            PayAmountRow(label: '보유 크레딧', amount: shortage.balance),
            const SizedBox(height: AppSpacing.s6),
            PayAmountRow(
              label: '부족한 크레딧',
              amount: shortage.shortfall,
              bold: true,
              tone: CreditAmountTone.danger,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.s16),
      const AppNotice('크레딧은 빠져나가지 않았어요', icon: Icons.check_circle),
    ],
  );

  Widget _bottomActions() {
    final total = AppCreditAmount.format(_total);
    return switch (_stage) {
      _Stage.selection => BottomCTA(
        buttons: [
          AppButton(
            '다시 스캔',
            variant: AppButtonVariant.light,
            onPressed: () => context.pop(),
          ),
          AppButton(
            '$total 결제하기',
            key: const Key('submitPayment'),
            enabled: _lines.isNotEmpty && !_reloadingMenus,
            onPressed: _pay,
          ),
        ],
      ),
      _Stage.processing => BottomCTA(
        buttons: [const AppButton('결제 중이에요', onPressed: null)],
      ),
      _Stage.unknown => BottomCTA(
        buttons: [
          AppButton(
            '거래 내역',
            variant: AppButtonVariant.light,
            onPressed: () => context.push(Routes.transactions),
          ),
          AppButton(
            '결과 다시 확인',
            key: const Key('recheckPayment'),
            onPressed: _send,
          ),
        ],
      ),
      _Stage.receipt => BottomCTA(
        buttons: [
          AppButton(
            '거래 내역',
            variant: AppButtonVariant.light,
            onPressed: () => context.pushReplacement(Routes.transactions),
          ),
          AppButton('확인', onPressed: () => context.go(Routes.home)),
        ],
      ),
      _Stage.insufficient => BottomCTA(
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
              if (mounted) setState(() => _stage = _Stage.selection);
            },
          ),
        ],
      ),
    };
  }
}
