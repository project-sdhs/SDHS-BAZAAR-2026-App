import 'package:bazaar_app/data/models/charge_request.dart';
import 'package:bazaar_app/data/models/credit_summary.dart';
import 'package:bazaar_app/data/models/credit_transaction.dart';
import 'package:bazaar_app/data/models/payment.dart';
import 'package:bazaar_app/data/models/payment_exception.dart';
import 'package:bazaar_app/data/models/public_settings.dart';
import 'package:bazaar_app/data/models/qr_pay.dart';

// API 페이지 응답 예시 값으로 만든 결제 테스트 데이터.

/// 바자회 첫날 낮 (2026-10-23 12:00 서울). 종료일(10-24) 전입니다.
final eventDay = DateTime.utc(2026, 10, 23, 3);

/// 바자회가 끝난 다음 날 (2026-10-25 09:00 서울)
final afterEvent = DateTime.utc(2026, 10, 25);

const sampleQrCode = 'K7Q2M9X4TB';

Map<String, Object?> settingsJson({
  String eventEndDate = '2026-10-24',
  int chargeMin = 1000,
  int? chargeMax,
  int? balanceLimit,
  bool withAccount = true,
}) => {
  'appOpen': true,
  'eventName': '2026 디지텍 바자회',
  'eventStartDate': '2026-10-23',
  'eventEndDate': eventEndDate,
  'depositAccount': withAccount
      ? {'bank': '예시은행', 'accountNo': '000-1234-5678-90', 'holder': '디지텍 학생회'}
      : null,
  'depositorNameRule': '{studentNo} {name}',
  'depositorNameExample': '2205 이재원',
  'depositorNameRuleWithCode': '{depositCode} {name}',
  'depositorNameExampleWithCode': 'V3071 김하린',
  'chargeMin': chargeMin,
  'chargeMax': chargeMax,
  'balanceLimit': balanceLimit,
};

PublicSettings fixtureSettings({
  String eventEndDate = '2026-10-24',
  int chargeMin = 1000,
  int? chargeMax,
  int? balanceLimit,
}) => PublicSettings.fromJson(
  settingsJson(
    eventEndDate: eventEndDate,
    chargeMin: chargeMin,
    chargeMax: chargeMax,
    balanceLimit: balanceLimit,
  ),
);

CreditSummary fixtureCredit({
  int balance = 12400,
  int used = 17600,
  int pendingChargeAmount = 0,
}) => CreditSummary(
  balance: balance,
  used: used,
  pendingChargeAmount: pendingChargeAmount,
  asOf: DateTime.utc(2026, 10, 23, 3, 5),
);

Map<String, Object?> chargeJson({
  int id = 512,
  int amount = 10000,
  String status = 'pending',
  String? reason,
}) => {
  'id': id,
  'amount': amount,
  'status': status,
  'depositorName': '2205 이재원',
  'depositAccount': {
    'bank': '예시은행',
    'accountNo': '000-1234-5678-90',
    'holder': '디지텍 학생회',
  },
  'reason': reason,
  'requestedAt': '2026-10-23T03:20:00Z',
  'approvedAt': status == 'approved' ? '2026-10-23T03:24:10Z' : null,
  'rejectedAt': status == 'rejected' ? '2026-10-23T03:30:00Z' : null,
};

ChargeRequest fixtureCharge({
  int id = 512,
  int amount = 10000,
  ChargeStatus status = ChargeStatus.pending,
  String? reason,
}) => ChargeRequest.fromJson(
  chargeJson(
    id: id,
    amount: amount,
    status: switch (status) {
      ChargeStatus.needsReview => 'needs_review',
      _ => status.name,
    },
    reason: reason,
  ),
);

Map<String, Object?> menuJson(
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

/// 2-3 타코야끼: 8알 3,000 · 4알 1,800 · 치즈 6알 3,500 · 라무네 2,000(품절)
List<Map<String, Object?>> defaultMenus() => [
  menuJson(301, '타코야끼 8알', 3000, 1),
  menuJson(302, '타코야끼 4알', 1800, 2),
  menuJson(303, '치즈 타코야끼 6알', 3500, 3),
  menuJson(304, '라무네', 2000, 4, onSale: false),
];

Map<String, Object?> qrInfoJson({
  int? balance = 12400,
  List<Map<String, Object?>>? menus,
  String source = 'board',
}) => {
  'code': sampleQrCode,
  'source': source,
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
  'menus': menus ?? defaultMenus(),
  'balance': ?balance,
};

QrPayInfo fixtureQrInfo({
  int? balance = 12400,
  List<Map<String, Object?>>? menus,
}) => QrPayInfo.fromJson(qrInfoJson(balance: balance, menus: menus));

Map<String, Object?> receiptJson({
  int no = 31,
  int balanceBefore = 12400,
  List<(int, String, int, int)> lines = const [
    (301, '타코야끼 8알', 3000, 1),
    (302, '타코야끼 4알', 1800, 1),
  ],
}) {
  final total = lines.fold(0, (sum, line) => sum + line.$3 * line.$4);
  return {
    'id': 5821,
    'no': no,
    'booth': {'id': 23, 'name': '2-3 타코야끼'},
    'total': total,
    'balanceBefore': balanceBefore,
    'balanceAfter': balanceBefore - total,
    'items': [
      for (final (menuId, name, unitPrice, quantity) in lines)
        {
          'menuId': menuId,
          'name': name,
          'unitPrice': unitPrice,
          'quantity': quantity,
          'amount': unitPrice * quantity,
        },
    ],
    'paidAt': '2026-10-23T03:12:45Z',
  };
}

PaymentReceipt fixtureReceipt({int balanceBefore = 12400}) =>
    PaymentReceipt.fromJson(receiptJson(balanceBefore: balanceBefore));

CreditTransaction fixtureTransaction(
  String id, {
  TransactionType type = TransactionType.purchase,
  TransactionStatus status = TransactionStatus.completed,
  int amount = -3500,
  String title = '3-1 로제떡볶이',
  String? subtitle = '로제떡볶이 외 1개',
  DateTime? occurredAt,
}) => CreditTransaction(
  id: id,
  type: type,
  title: title,
  subtitle: subtitle,
  occurredAt: occurredAt ?? DateTime.utc(2026, 10, 23, 2, 41, 10),
  status: status,
  amount: amount,
  refId: int.tryParse(id.split('-').last) ?? 0,
);

/// 서버 에러 응답 (409 추가 필드는 [details] 로)
PaymentException paymentError(
  String code, {
  int statusCode = 409,
  String message = '요청을 처리하지 못했어요',
  Map<String, Object?> details = const {},
  Map<String, String> fields = const {},
  Duration? retryAfter,
}) => PaymentException(
  code: code,
  message: message,
  statusCode: statusCode,
  details: {'code': code, 'message': message, ...details},
  fields: fields,
  retryAfter: retryAfter,
);
