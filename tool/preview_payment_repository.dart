import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/charge_request.dart';
import 'package:bazaar_app/data/models/credit_summary.dart';
import 'package:bazaar_app/data/models/credit_transaction.dart';
import 'package:bazaar_app/data/models/payment.dart';
import 'package:bazaar_app/data/models/payment_exception.dart';
import 'package:bazaar_app/data/models/public_settings.dart';
import 'package:bazaar_app/data/models/qr_pay.dart';
import 'package:bazaar_app/data/repositories/payment_repository.dart';

/// 미리보기 전용 가짜 서버 (`tool/preview_payments.dart` 에서만 씀, 앱 빌드에는 들어가지 않음).
///
/// 값은 API 페이지의 응답 예시를 그대로 썼습니다. 충전 요청은 20초 뒤 승인됩니다.
class PreviewPaymentRepository extends PaymentRepository {
  PreviewPaymentRepository() : super(ApiClient());

  static const qrCode = 'K7Q2M9X4TB';
  static const _delay = Duration(milliseconds: 400);

  int _balance = 12400;
  int _used = 17600;
  int _nextPaymentNo = 31;
  int _nextPaymentId = 5821;
  ChargeRequest? _charge;
  final List<CreditTransaction> _history = [
    CreditTransaction(
      id: 'payment-5702',
      type: TransactionType.purchase,
      title: '3-1 로제떡볶이',
      subtitle: '로제떡볶이 외 1개',
      occurredAt: DateTime.utc(2026, 10, 23, 2, 41, 10),
      status: TransactionStatus.completed,
      amount: -3500,
      refId: 5702,
    ),
    CreditTransaction(
      id: 'adjustment-12',
      type: TransactionType.adjustment,
      title: '크레딧 조정',
      subtitle: '같은 입금으로 두 번 승인된 충전 정정',
      occurredAt: DateTime.utc(2026, 10, 23, 2, 20),
      status: TransactionStatus.completed,
      amount: -5000,
      refId: 12,
    ),
    CreditTransaction(
      id: 'charge-498',
      type: TransactionType.charge,
      title: '크레딧 충전',
      subtitle: '입금자명 2205 이재원',
      occurredAt: DateTime.utc(2026, 10, 23, 2, 5),
      status: TransactionStatus.approved,
      amount: 10000,
      refId: 498,
    ),
    CreditTransaction(
      id: 'payment-5641',
      type: TransactionType.purchase,
      title: '1-2 츄러스',
      subtitle: '츄러스',
      occurredAt: DateTime.utc(2026, 10, 23, 1, 20),
      status: TransactionStatus.refunded,
      amount: -2000,
      refId: 5641,
    ),
  ];

  static const _account = DepositAccount(
    bank: '예시은행',
    accountNo: '000-1234-5678-90',
    holder: '디지텍 학생회',
  );

  @override
  Future<PublicSettings> publicSettings() async {
    await Future<void>.delayed(_delay);
    // 미리보기는 항상 바자회 기간 안으로 보이게 오늘을 종료일로 둡니다.
    final today = DateTime.now().toUtc().add(const Duration(hours: 9));
    final date =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return PublicSettings.fromJson({
      'appOpen': true,
      'eventName': '2026 디지텍 바자회',
      'eventStartDate': date,
      'eventEndDate': date,
      'depositAccount': {
        'bank': _account.bank,
        'accountNo': _account.accountNo,
        'holder': _account.holder,
      },
      'depositorNameRule': '{studentNo} {name}',
      'depositorNameExample': '2205 이재원',
      'depositorNameRuleWithCode': '{depositCode} {name}',
      'depositorNameExampleWithCode': 'V3071 김하린',
      'chargeMin': 1000,
      'chargeMax': null,
      'balanceLimit': null,
    });
  }

  @override
  Future<CreditSummary> myCredit() async {
    await Future<void>.delayed(_delay);
    return CreditSummary(
      balance: _balance,
      used: _used,
      pendingChargeAmount: _charge?.status.isWaiting ?? false
          ? _charge!.amount
          : 0,
      asOf: DateTime.now().toUtc(),
    );
  }

  @override
  Future<ChargeResult> requestCharge(
    int amount, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(_delay);
    final current = _charge;
    if (current != null && current.status.isWaiting) {
      return ChargeResult(request: current, created: false);
    }
    final request = ChargeRequest(
      id: 512,
      amount: amount,
      status: ChargeStatus.pending,
      depositorName: '2205 이재원',
      depositAccount: _account,
      requestedAt: DateTime.now().toUtc(),
    );
    _charge = request;
    return ChargeResult(request: request, created: true);
  }

  @override
  Future<ChargeRequest> chargeRequest(int id) async {
    await Future<void>.delayed(_delay);
    final current = _charge;
    if (current == null || current.id != id) {
      throw const PaymentException(
        code: PaymentErrorCode.notFound,
        message: '충전 요청을 찾을 수 없어요',
        statusCode: 404,
      );
    }
    final waited = DateTime.now().toUtc().difference(current.requestedAt);
    if (current.status.isWaiting && waited > const Duration(seconds: 20)) {
      final approved = ChargeRequest(
        id: current.id,
        amount: current.amount,
        status: ChargeStatus.approved,
        depositorName: current.depositorName,
        depositAccount: current.depositAccount,
        requestedAt: current.requestedAt,
        approvedAt: DateTime.now().toUtc(),
      );
      _charge = approved;
      _balance += approved.amount;
      _history.insert(
        0,
        CreditTransaction(
          id: 'charge-${approved.id}',
          type: TransactionType.charge,
          title: '크레딧 충전',
          subtitle: '입금자명 ${approved.depositorName}',
          occurredAt: approved.approvedAt!,
          status: TransactionStatus.approved,
          amount: approved.amount,
          refId: approved.id,
        ),
      );
    }
    return _charge!;
  }

  @override
  Future<TransactionPage> transactions({
    TransactionFilter? type,
    String? cursor,
    int limit = 20,
  }) async {
    await Future<void>.delayed(_delay);
    final filtered = [
      for (final item in _history)
        if (switch (type) {
          null => true,
          TransactionFilter.charge =>
            item.type == TransactionType.charge ||
                item.type == TransactionType.adjustment,
          TransactionFilter.purchase =>
            item.type == TransactionType.purchase ||
                item.type == TransactionType.refund,
        })
          item,
    ];
    final start = int.tryParse(cursor ?? '') ?? 0;
    final end = (start + limit).clamp(0, filtered.length);
    return TransactionPage(
      items: filtered.sublist(start.clamp(0, filtered.length), end),
      nextCursor: end < filtered.length ? '$end' : null,
      summary: cursor == null
          ? TransactionSummary(chargeTotal: 30000, useTotal: _used)
          : null,
    );
  }

  @override
  Future<QrPayInfo> qrPayInfo(
    String code, {
    PaymentSource source = PaymentSource.print,
  }) async {
    await Future<void>.delayed(_delay);
    if (code != qrCode) {
      throw const PaymentException(
        code: PaymentErrorCode.qrInvalid,
        message: '알 수 없는 QR이에요',
        statusCode: 404,
      );
    }
    return QrPayInfo.fromJson({
      'code': qrCode,
      'source': source.name,
      'booth': {
        'id': 23,
        'name': '2-3 타코야끼',
        'class': {'id': 8, 'grade': 2, 'classNo': 3, 'name': '2학년 3반'},
        'category': '간식',
        'type': 'normal',
        'status': 'open',
        'location': {
          'floorId': 12,
          'building': '신관',
          'floor': 2,
          'zone': '복도',
          'label': '신관 2층 복도',
          'x': 0.42,
          'y': 0.31,
        },
        'openTime': '10:00',
        'closeTime': '15:00',
        'minPrice': 1800,
        'menuCount': 3,
        'imageUrl': null,
      },
      'menus': [
        _menu(301, '타코야끼 8알', 3000, 1),
        _menu(302, '타코야끼 4알', 1800, 2),
        _menu(303, '치즈 타코야끼 6알', 3500, 3),
        _menu(304, '라무네', 2000, 4, onSale: false),
      ],
      'balance': _balance,
    });
  }

  static Map<String, Object?> _menu(
    int id,
    String name,
    int price,
    int sortOrder, {
    bool onSale = true,
  }) => {
    'id': id,
    'name': name,
    'price': price,
    'onSale': onSale,
    'sortOrder': sortOrder,
    'imageUrl': null,
  };

  @override
  Future<PaymentReceipt> pay(
    PaymentRequest request, {
    required String idempotencyKey,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final menus = {
      for (final menu in (await qrPayInfo(request.qrCode)).menus) menu.id: menu,
    };
    final lines = [
      for (final item in request.items)
        PaymentLine(
          menuId: item.menuId,
          name: menus[item.menuId]!.name,
          unitPrice: menus[item.menuId]!.price,
          quantity: item.quantity,
          amount: menus[item.menuId]!.price * item.quantity,
        ),
    ];
    final total = lines.fold(0, (sum, line) => sum + line.amount);
    if (total > _balance) {
      throw PaymentException(
        code: PaymentErrorCode.insufficientCredit,
        message: '크레딧이 부족해요',
        statusCode: 409,
        details: {
          'balance': _balance,
          'total': total,
          'shortfall': total - _balance,
        },
      );
    }
    final receipt = PaymentReceipt(
      id: _nextPaymentId++,
      no: _nextPaymentNo++,
      booth: const BoothRef(id: 23, name: '2-3 타코야끼'),
      total: total,
      balanceBefore: _balance,
      balanceAfter: _balance - total,
      items: lines,
      paidAt: DateTime.now().toUtc(),
    );
    _balance = receipt.balanceAfter;
    _used += total;
    _history.insert(
      0,
      CreditTransaction(
        id: 'payment-${receipt.id}',
        type: TransactionType.purchase,
        title: receipt.booth.name,
        subtitle: lines.length == 1
            ? lines.single.name
            : '${lines.first.name} 외 ${lines.length - 1}개',
        occurredAt: receipt.paidAt,
        status: TransactionStatus.completed,
        amount: -total,
        refId: receipt.id,
      ),
    );
    return receipt;
  }
}
