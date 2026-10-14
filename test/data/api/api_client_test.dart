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
}
