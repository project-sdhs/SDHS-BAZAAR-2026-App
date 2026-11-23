import '../models/payment_models.dart';

/// 화면이 사용하는 결제 데이터 계약. 서버 연동 시 이 구현을 교체합니다.
abstract class PaymentRepository {
  int get balance;
  int get chargedTotal;
  int get usedTotal;
  String get depositorName;
  ChargeSettings get settings;
  List<CreditTransaction> get transactions;
  ChargeRequest? get chargeRequest;
  bool get isPreview;

  Future<ChargeRequest> requestCharge(int amount);
  Future<ChargeRequest?> refreshCharge();
  Future<PaymentBooth> resolveQr(String value);
  Future<PaymentReceipt> pay(PaymentBooth booth, List<OrderLine> items);
}

/// 피그마 화면과 동작을 확인하는 로컬 예시 데이터입니다.
class PreviewPaymentRepository implements PaymentRepository {
  PreviewPaymentRepository({
    int balance = 12400,
    ChargeSettings? settings,
    ChargeRequest? chargeRequest,
  }) : _creditBalance = balance,
       settings = settings ?? _previewSettings,
       _pendingChargeRequest = chargeRequest;

  static const _previewSettings = ChargeSettings(
    account: DepositAccount(
      bank: '은행 확인 중',
      accountNo: '계좌 확인 중',
      holder: '예금주 확인 중',
    ),
  );

  static const _qrCode = 'K7Q2M9X4TB';
  static final _booth = PaymentBooth(
    code: _qrCode,
    name: '2-3 타코야끼',
    location: '2학년 3반 · 신관 2층 복도',
    menus: const [
      MenuItem(id: 301, name: '타코야끼 8알', price: 3000),
      MenuItem(id: 302, name: '타코야끼 4알', price: 1800),
      MenuItem(id: 303, name: '치즈 타코야끼 6알', price: 3500),
      MenuItem(id: 304, name: '라무네', price: 2000, onSale: false, emoji: '🧃'),
    ],
  );

  int _creditBalance;
  int _usedTotal = 17600;
  int _nextPaymentNumber = 31;
  int _nextChargeId = 512;
  ChargeRequest? _pendingChargeRequest;
  bool _paying = false;
  bool _requestingCharge = false;

  final List<CreditTransaction> _transactions = [
    CreditTransaction(
      id: 'purchase-5702',
      type: TransactionType.purchase,
      title: '3-1 로제떡볶이',
      subtitle: '메뉴 2건',
      occurredAt: DateTime.parse('2026-10-24T12:40:00+09:00'),
      status: 'completed',
      amount: -4500,
    ),
    CreditTransaction(
      id: 'charge-511',
      type: TransactionType.charge,
      title: '계좌이체 충전',
      subtitle: '승인',
      occurredAt: DateTime.parse('2026-10-24T09:12:00+09:00'),
      status: 'approved',
      amount: 10000,
    ),
    CreditTransaction(
      id: 'purchase-5621',
      type: TransactionType.purchase,
      title: '학생회 굿즈샵',
      subtitle: '메뉴 1건',
      occurredAt: DateTime.parse('2026-10-23T16:52:00+09:00'),
      status: 'completed',
      amount: -6000,
    ),
    CreditTransaction(
      id: 'purchase-5620',
      type: TransactionType.purchase,
      title: '2-5 보드게임',
      subtitle: '메뉴 2건',
      occurredAt: DateTime.parse('2026-10-23T16:30:00+09:00'),
      status: 'completed',
      amount: -7100,
    ),
    CreditTransaction(
      id: 'charge-509',
      type: TransactionType.charge,
      title: '계좌이체 충전',
      subtitle: '승인',
      occurredAt: DateTime.parse('2026-10-23T16:05:00+09:00'),
      status: 'approved',
      amount: 20000,
    ),
  ];

  @override
  int get balance => _creditBalance;

  @override
  int get chargedTotal => 30000;

  @override
  int get usedTotal => _usedTotal;

  @override
  String get depositorName => '2205 이재원';

  @override
  final ChargeSettings settings;

  @override
  List<CreditTransaction> get transactions => List.unmodifiable(_transactions);

  @override
  ChargeRequest? get chargeRequest => _pendingChargeRequest;

  @override
  bool get isPreview => true;

  @override
  Future<ChargeRequest> requestCharge(int amount) async {
    if (_requestingCharge) {
      throw const PaymentException(
        code: 'CHARGE_IN_PROGRESS',
        message: '충전 요청을 보내고 있어요. 잠시만 기다려 주세요.',
      );
    }
    _validateCharge(amount);
    final current = _pendingChargeRequest;
    if (current != null &&
        (current.status == ChargeStatus.pending ||
            current.status == ChargeStatus.needsReview)) {
      throw const PaymentException(
        code: 'CHARGE_PENDING',
        message: '확인 중인 충전 요청이 있어요.',
      );
    }

    _requestingCharge = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      final request = ChargeRequest(
        id: _nextChargeId++,
        amount: amount,
        status: ChargeStatus.pending,
        depositorName: depositorName,
      );
      _pendingChargeRequest = request;
      return request;
    } finally {
      _requestingCharge = false;
    }
  }

  void _validateCharge(int amount) {
    if (settings.eventEnded) {
      throw const PaymentException(
        code: 'EVENT_ENDED',
        message: '바자회가 끝나서 충전할 수 없어요.',
      );
    }
    if (amount < settings.minimumAmount ||
        (settings.maximumAmount != null && amount > settings.maximumAmount!) ||
        (settings.balanceLimit != null &&
            balance + amount > settings.balanceLimit!)) {
      throw const PaymentException(
        code: 'VALIDATION_FAILED',
        message: '충전할 수 있는 금액을 확인해 주세요.',
      );
    }
  }

  @override
  Future<ChargeRequest?> refreshCharge() async => _pendingChargeRequest;

  @override
  Future<PaymentBooth> resolveQr(String value) async {
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    final isQrUrl =
        uri != null &&
        (uri.scheme == 'https' || uri.scheme == 'http') &&
        uri.host.isNotEmpty &&
        uri.pathSegments.length == 2 &&
        uri.pathSegments.first == 'q' &&
        uri.pathSegments.last == _qrCode;
    if (trimmed != _qrCode && !isQrUrl) {
      throw const PaymentException(
        code: 'QR_INVALID',
        message: '바자회 부스의 QR인지 확인하고 다시 스캔해 주세요.',
      );
    }
    return _booth;
  }

  @override
  Future<PaymentReceipt> pay(PaymentBooth booth, List<OrderLine> items) async {
    if (_paying) {
      throw const PaymentException(
        code: 'PAYMENT_IN_PROGRESS',
        message: '결제를 처리하고 있어요. 잠시만 기다려 주세요.',
      );
    }
    if (booth.code != _qrCode) {
      throw const PaymentException(
        code: 'QR_INVALID',
        message: '부스 QR을 다시 스캔해 주세요.',
      );
    }
    if (!booth.isOpen) {
      throw const PaymentException(
        code: 'BOOTH_CLOSED',
        message: '지금은 주문을 받고 있지 않아요.',
      );
    }
    final frozenItems = List<OrderLine>.unmodifiable(items);
    final validatedItems = _validateItems(frozenItems);
    final total = validatedItems.fold(0, (sum, item) => sum + item.amount);
    if (total > _creditBalance) {
      throw const PaymentException(
        code: 'INSUFFICIENT_CREDIT',
        message: '크레딧이 부족해요.',
      );
    }

    _paying = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final balanceBefore = _creditBalance;
      final receipt = PaymentReceipt(
        number: _nextPaymentNumber++,
        booth: _booth,
        items: validatedItems,
        total: total,
        balanceBefore: balanceBefore,
        balanceAfter: balanceBefore - total,
        paidAt: DateTime.now(),
      );
      _creditBalance = receipt.balanceAfter;
      _usedTotal += total;
      _transactions.insert(
        0,
        CreditTransaction(
          id: 'preview-payment-${receipt.number}',
          type: TransactionType.purchase,
          title: receipt.booth.name,
          subtitle: '메뉴 ${validatedItems.length}건',
          occurredAt: receipt.paidAt,
          status: 'completed',
          amount: -total,
        ),
      );
      return receipt;
    } finally {
      _paying = false;
    }
  }

  List<OrderLine> _validateItems(List<OrderLine> items) {
    if (items.isEmpty ||
        items.map((line) => line.menu.id).toSet().length != items.length) {
      throw const PaymentException(
        code: 'VALIDATION_FAILED',
        message: '결제할 메뉴를 골라 주세요.',
      );
    }
    final menus = {for (final menu in _booth.menus) menu.id: menu};
    return [for (final line in items) _validateLine(line, menus[line.menu.id])];
  }

  OrderLine _validateLine(OrderLine line, MenuItem? menu) {
    if (line.quantity < 1) {
      throw const PaymentException(
        code: 'VALIDATION_FAILED',
        message: '메뉴 수량은 1개 이상 골라 주세요.',
      );
    }
    if (menu == null || !menu.onSale || menu.price != line.menu.price) {
      throw const PaymentException(
        code: 'MENU_CHANGED',
        message: '메뉴 가격이나 판매 상태가 바뀌었어요. 다시 확인해 주세요.',
      );
    }
    return OrderLine(menu: menu, quantity: line.quantity);
  }
}
