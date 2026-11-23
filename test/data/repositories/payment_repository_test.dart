import 'dart:convert';

import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/charge_request.dart';
import 'package:bazaar_app/data/models/credit_transaction.dart';
import 'package:bazaar_app/data/models/payment.dart';
import 'package:bazaar_app/data/models/payment_exception.dart';
import 'package:bazaar_app/data/models/qr_pay.dart';
import 'package:bazaar_app/data/repositories/payment_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../support/payment_fixtures.dart';

/// 요청을 [onRequest] 로 확인하고 [body] 를 [status] 로 돌려주는 저장소.
PaymentRepository _repo(
  Object body, {
  int status = 200,
  Map<String, String> headers = const {},
  void Function(http.Request request)? onRequest,
}) => PaymentRepository(
  ApiClient(
    baseUrl: 'http://test',
    httpClient: MockClient((request) async {
      onRequest?.call(request);
      return http.Response(
        jsonEncode(body),
        status,
        headers: {
          'content-type': 'application/json; charset=utf-8',
          ...headers,
        },
      );
    }),
  ),
);

void main() {
  test('공개 설정: 입금 계좌 · 입금자명 규칙 · 충전 한도를 읽는다', () async {
    final settings = await _repo(
      settingsJson(),
      onRequest: (request) => expect(request.url.path, '/settings/public'),
    ).publicSettings();

    expect(settings.depositAccount!.bank, '예시은행');
    expect(settings.depositAccount!.accountNo, '000-1234-5678-90');
    expect(settings.depositAccount!.holder, '디지텍 학생회');
    expect(settings.depositorNameRule, '{studentNo} {name}');
    expect(settings.depositorNameRuleWithCode, '{depositCode} {name}');
    expect(settings.chargeMin, 1000);
    expect(settings.chargeMax, isNull);
    expect(settings.balanceLimit, isNull);
    expect(settings.eventEndDate, DateTime.utc(2026, 10, 24));
    // 종료일(서울 10-24) 23:59 까지는 열려 있고, 서울 날짜가 10-25 가 되면 끝
    expect(settings.hasEndedAt(DateTime.utc(2026, 10, 24, 14, 59)), isFalse);
    expect(settings.hasEndedAt(DateTime.utc(2026, 10, 24, 15)), isTrue);
  });

  test('내 크레딧: 잔액 · 사용액 · 확인 중 금액', () async {
    final credit = await _repo(
      {
        'balance': 12400,
        'used': 17600,
        'pendingChargeAmount': 0,
        'asOf': '2026-10-23T03:05:00Z',
      },
      onRequest: (request) => expect(request.url.path, '/me/credit'),
    ).myCredit();

    expect(credit.balance, 12400);
    expect(credit.used, 17600);
    expect(credit.pendingChargeAmount, 0);
    expect(credit.asOf, DateTime.utc(2026, 10, 23, 3, 5));
  });

  group('충전 요청', () {
    test('201 은 새 요청, Idempotency-Key 헤더와 금액을 보낸다', () async {
      final result = await _repo(
        chargeJson(),
        status: 201,
        onRequest: (request) {
          expect(request.method, 'POST');
          expect(request.url.path, '/credits/charge');
          expect(request.headers['Idempotency-Key'], 'key-1');
          expect(jsonDecode(request.body), {'amount': 10000});
        },
      ).requestCharge(10000, idempotencyKey: 'key-1');

      expect(result.created, isTrue);
      expect(result.request.id, 512);
      expect(result.request.status, ChargeStatus.pending);
      expect(result.request.depositorName, '2205 이재원');
      expect(result.request.depositAccount!.accountNo, '000-1234-5678-90');
      expect(result.request.requestedAt, DateTime.utc(2026, 10, 23, 3, 20));
    });

    test('200 은 이미 있던 대기 요청 (created = false)', () async {
      final result = await _repo(chargeJson(id: 509, amount: 5000))
          .requestCharge(10000, idempotencyKey: 'key-2');

      expect(result.created, isFalse);
      expect(result.request.id, 509);
      expect(result.request.amount, 5000);
    });

    test('상태 조회: needs_review 를 needsReview 로 읽는다', () async {
      final request = await _repo(
        chargeJson(id: 509, status: 'needs_review', reason: '30분째 입금이 없어요'),
        onRequest: (request) => expect(request.url.path, '/credits/charge/509'),
      ).chargeRequest(509);

      expect(request.status, ChargeStatus.needsReview);
      expect(request.reason, '30분째 입금이 없어요');
    });

    test('400 VALIDATION_FAILED 의 fields.amount 를 남긴다', () async {
      await expectLater(
        _repo({
          'code': 'VALIDATION_FAILED',
          'message': '입력값을 확인해 주세요.',
          'fields': {'amount': '1,000 이상이어야 해요'},
        }, status: 400).requestCharge(500, idempotencyKey: 'k'),
        throwsA(
          isA<PaymentException>()
              .having((e) => e.code, 'code', PaymentErrorCode.validationFailed)
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.fields['amount'], 'amount', '1,000 이상이어야 해요'),
        ),
      );
    });

    test('429 RATE_LIMITED 의 Retry-After 를 남긴다', () async {
      await expectLater(
        _repo(
          {'code': 'RATE_LIMITED', 'message': '요청이 너무 많아요'},
          status: 429,
          headers: {'retry-after': '42'},
        ).requestCharge(10000, idempotencyKey: 'k'),
        throwsA(
          isA<PaymentException>().having(
            (e) => e.retryAfter,
            'retryAfter',
            const Duration(seconds: 42),
          ),
        ),
      );
    });
  });

  test('거래 내역: type · cursor · limit 을 보내고 서버 순서를 그대로 둔다', () async {
    final page = await _repo(
      {
        'items': [
          {
            'id': 'payment-5702',
            'type': 'purchase',
            'title': '3-1 로제떡볶이',
            'subtitle': '로제떡볶이 외 1개',
            'occurredAt': '2026-10-23T02:41:10Z',
            'status': 'completed',
            'amount': -3500,
            'refId': 5702,
          },
          {
            'id': 'adjustment-12',
            'type': 'adjustment',
            'title': '크레딧 조정',
            'subtitle': '같은 입금으로 두 번 승인된 충전 정정',
            'occurredAt': '2026-10-23T02:20:00Z',
            'status': 'completed',
            'amount': -5000,
            'refId': 12,
          },
          {
            'id': 'charge-498',
            'type': 'charge',
            'title': '크레딧 충전',
            'subtitle': '입금자명 2205 이재원',
            'occurredAt': '2026-10-23T02:05:00Z',
            'status': 'approved',
            'amount': 10000,
            'refId': 498,
          },
        ],
        'nextCursor': 'eyJ0IjoiMjAyNi0xMC0yM1QwMToyMDowMFoiLCJpZCI6NTY0MX0',
        'summary': {'chargeTotal': 30000, 'useTotal': 17600},
      },
      onRequest: (request) {
        expect(request.url.path, '/transactions');
        expect(request.url.queryParameters, {
          'type': 'charge',
          'cursor': 'abc',
          'limit': '20',
        });
      },
    ).transactions(type: TransactionFilter.charge, cursor: 'abc');

    expect(page.items.map((t) => t.id), [
      'payment-5702',
      'adjustment-12',
      'charge-498',
    ]);
    expect(page.items[1].type, TransactionType.adjustment);
    expect(page.items[2].status, TransactionStatus.approved);
    expect(page.items.first.amount, -3500);
    expect(page.items.first.occurredAt.isUtc, isTrue);
    expect(page.nextCursor, isNotNull);
    expect(page.summary!.chargeTotal, 30000);
  });

  test('거래 내역 첫 페이지는 cursor 를 보내지 않는다', () async {
    final page = await _repo(
      {'items': <Object>[], 'nextCursor': null, 'summary': null},
      onRequest: (request) =>
          expect(request.url.queryParameters, {'limit': '20'}),
    ).transactions();

    expect(page.items, isEmpty);
    expect(page.nextCursor, isNull);
    expect(page.summary, isNull);
  });

  test('모르는 거래 상태면 FormatException', () async {
    await expectLater(
      _repo({
        'items': [
          {
            'id': 'x-1',
            'type': 'purchase',
            'title': 't',
            'occurredAt': '2026-10-23T02:41:10Z',
            'status': 'teleported',
            'amount': 1,
            'refId': 1,
          },
        ],
      }).transactions(),
      throwsA(isA<FormatException>()),
    );
  });

  test('QR 결제 정보: 코드 · src 를 보내고 부스 · 메뉴 · 잔액을 읽는다', () async {
    final info = await _repo(
      qrInfoJson(),
      onRequest: (request) {
        expect(request.url.path, '/pay/qr/$sampleQrCode');
        expect(request.url.queryParameters, {'src': 'board'});
      },
    ).qrPayInfo(sampleQrCode, source: PaymentSource.board);

    expect(info.code, sampleQrCode);
    expect(info.source, PaymentSource.board);
    expect(info.booth.id, 23);
    expect(info.booth.name, '2-3 타코야끼');
    expect(info.booth.locationLabel, '신관 2층 복도');
    expect(info.menus.map((m) => m.name), [
      '타코야끼 8알',
      '타코야끼 4알',
      '치즈 타코야끼 6알',
      '라무네',
    ]);
    expect(info.menus.last.onSale, isFalse);
    expect(info.balance, 12400);
  });

  test('QR 409 ORDERING_PAUSED 의 pausedAt · booth 를 꺼낸다', () async {
    await expectLater(
      _repo({
        'code': 'ORDERING_PAUSED',
        'message': '지금은 주문을 받지 않아요',
        'pausedAt': '2026-10-23T03:05:00Z',
        'booth': {'id': 23, 'name': '2-3 타코야끼'},
      }, status: 409).qrPayInfo(sampleQrCode),
      throwsA(
        isA<PaymentException>()
            .having((e) => e.orderingPaused?.booth?.id, 'booth', 23)
            .having((e) => e.orderingPaused?.pausedAtLabel, 'KST', '12:05'),
      ),
    );
  });

  group('결제', () {
    test('본문 · Idempotency-Key 를 보내고 영수증을 읽는다', () async {
      final receipt =
          await _repo(
            receiptJson(),
            onRequest: (request) {
              expect(request.url.path, '/payments');
              expect(request.headers['Idempotency-Key'], 'pay-key');
              expect(jsonDecode(request.body), {
                'qrCode': sampleQrCode,
                'source': 'board',
                'items': [
                  {'menuId': 301, 'quantity': 1},
                  {'menuId': 302, 'quantity': 1},
                ],
                'clientTotal': 4800,
              });
            },
          ).pay(
            PaymentRequest(
              qrCode: sampleQrCode,
              source: PaymentSource.board,
              items: const [
                PaymentItem(menuId: 301, quantity: 1),
                PaymentItem(menuId: 302, quantity: 1),
              ],
              clientTotal: 4800,
            ),
            idempotencyKey: 'pay-key',
          );

      expect(receipt.id, 5821);
      expect(receipt.no, 31);
      expect(receipt.total, 4800);
      expect(receipt.balanceBefore, 12400);
      expect(receipt.balanceAfter, 7600);
      expect(receipt.items.first.name, '타코야끼 8알');
      expect(receipt.paidAt, DateTime.utc(2026, 10, 23, 3, 12, 45));
    });

    test('409 INSUFFICIENT_CREDIT 의 balance · total · shortfall', () async {
      await expectLater(
        _repo({
          'code': 'INSUFFICIENT_CREDIT',
          'message': '크레딧이 1,800 부족해요',
          'balance': 3000,
          'total': 4800,
          'shortfall': 1800,
        }, status: 409).pay(_request(), idempotencyKey: 'k'),
        throwsA(
          isA<PaymentException>()
              .having((e) => e.insufficientCredit?.balance, 'balance', 3000)
              .having((e) => e.insufficientCredit?.total, 'total', 4800)
              .having(
                (e) => e.insufficientCredit?.shortfall,
                'shortfall',
                1800,
              ),
        ),
      );
    });

    test('409 MENU_CHANGED 의 serverTotal · changedMenuIds', () async {
      await expectLater(
        _repo({
          'code': 'MENU_CHANGED',
          'message': '메뉴 가격이나 판매 상태가 바뀌었어요',
          'serverTotal': null,
          'changedMenuIds': [302],
        }, status: 409).pay(_request(), idempotencyKey: 'k'),
        throwsA(
          isA<PaymentException>()
              .having((e) => e.menuChanged?.serverTotal, 'serverTotal', isNull)
              .having((e) => e.menuChanged?.changedMenuIds, 'ids', [302]),
        ),
      );
    });
  });
}

PaymentRequest _request() => PaymentRequest(
  qrCode: sampleQrCode,
  source: PaymentSource.print,
  items: const [PaymentItem(menuId: 301, quantity: 1)],
  clientTotal: 3000,
);
