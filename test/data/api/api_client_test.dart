import 'dart:async';
import 'dart:convert';

import 'package:bazaar_app/data/api/api_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('기본 서버 주소는 localhost:3000 이다', () {
    expect(ApiClient.defaultBaseUrl, 'http://localhost:3000');
  });

  test('baseUrl 과 경로를 이어 붙인다', () {
    final client = ApiClient(baseUrl: 'http://example.com/');
    expect(client.uri('/health').toString(), 'http://example.com/health');
    expect(client.uri('booths').toString(), 'http://example.com/booths');
    expect(client.uri('/booths', {'q': '타코'}).queryParameters, {'q': '타코'});
  });

  test('2xx 응답이면 JSON 을 돌려준다', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient((request) async {
        expect(request.url.toString(), 'http://example.com/health');
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      }),
    );

    expect(await client.getJson('/health'), {'status': 'ok'});
  });

  test('에러 응답이면 서버의 code / message 로 ApiException 을 던진다', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({'code': 'NOT_FOUND', 'message': 'Not Found'}),
          404,
        ),
      ),
    );

    await expectLater(
      client.getJson('/nope'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)
            .having((e) => e.code, 'code', 'NOT_FOUND'),
      ),
    );
  });

  test('headers 는 기본 헤더에 덧붙이고 postResponse 는 상태 코드를 준다', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient((request) async {
        expect(request.headers['Idempotency-Key'], 'key-1');
        expect(request.headers['Content-Type'], startsWith('application/json'));
        expect(jsonDecode(request.body), {'amount': 10000});
        return http.Response(jsonEncode({'id': 512}), 201);
      }),
    );

    final response = await client.postResponse(
      '/credits/charge',
      body: {'amount': 10000},
      headers: {'Idempotency-Key': 'key-1'},
    );
    expect(response.statusCode, 201);
    expect(response.body, {'id': 512});
  });

  test('에러 본문의 fields · 추가 필드 · Retry-After 를 잃지 않는다', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient(
        (request) async => http.Response(
          jsonEncode({
            'code': 'INSUFFICIENT_CREDIT',
            'message': '크레딧이 1,800 부족해요',
            'fields': {'items.0.quantity': '1 이상이어야 해요'},
            'balance': 3000,
            'total': 4800,
            'shortfall': 1800,
          }),
          409,
          headers: {
            'content-type': 'application/json; charset=utf-8',
            'retry-after': '42',
          },
        ),
      ),
    );

    await expectLater(
      client.postJson('/payments'),
      throwsA(
        isA<ApiException>()
            .having((e) => e.fields, 'fields', {
              'items.0.quantity': '1 이상이어야 해요',
            })
            .having((e) => e.details['shortfall'], 'shortfall', 1800)
            .having(
              (e) => e.retryAfter,
              'retryAfter',
              const Duration(seconds: 42),
            ),
      ),
    );
  });

  test('응답이 timeout 안에 오지 않으면 ApiTimeoutException', () async {
    final never = Completer<http.Response>();
    final client = ApiClient(
      baseUrl: 'http://example.com',
      timeout: const Duration(milliseconds: 10),
      httpClient: MockClient((request) => never.future),
    );

    await expectLater(
      client.getJson('/me/credit'),
      throwsA(isA<ApiTimeoutException>()),
    );
    expect(ApiClient.defaultTimeout, const Duration(seconds: 15));
  });

  test('연결 실패는 ApiNetworkException 으로 바꾼다', () async {
    final client = ApiClient(
      baseUrl: 'http://example.com',
      httpClient: MockClient(
        (request) async => throw http.ClientException('Connection reset'),
      ),
    );

    await expectLater(
      client.getJson('/me/credit'),
      throwsA(isA<ApiNetworkException>()),
    );
  });
}
