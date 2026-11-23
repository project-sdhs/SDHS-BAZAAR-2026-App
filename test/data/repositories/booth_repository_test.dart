import 'dart:convert';

import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/repositories/booth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

BoothRepository _repo(Object body, {int status = 200}) => BoothRepository(
  ApiClient(
    baseUrl: 'http://test',
    httpClient: MockClient((request) async {
      expect(request.url.path, '/booths/popular');
      return http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
    }),
  ),
);

void main() {
  test('인기 부스를 순위 순서로 돌려준다', () async {
    final booths = await _repo({
      'baseTime': '2026-10-23T03:10:00Z',
      'items': [
        {'rank': 2, 'boothId': 23, 'name': '2-3 타코야끼', 'paymentCount': 97},
        {'rank': 1, 'boothId': 7, 'name': '3-1 로제떡볶이', 'paymentCount': 128},
      ],
    }).popularBooths();

    expect(booths.map((b) => b.rank), [1, 2]);
    expect(booths.first.name, '3-1 로제떡볶이');
    expect(booths.first.paymentCount, 128);
  });

  test('응답에 items 가 없으면 FormatException', () async {
    expect(
      _repo({'baseTime': 'x'}).popularBooths(),
      throwsA(isA<FormatException>()),
    );
  });
}
