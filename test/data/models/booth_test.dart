import 'dart:convert';

import 'package:bazaar_app/data/api/api_client.dart';
import 'package:bazaar_app/data/models/booth.dart';
import 'package:bazaar_app/data/repositories/booth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _normal = {
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
    'label': '신관 2층 복도',
  },
  'openTime': '10:00',
  'closeTime': '15:00',
  'minPrice': 200,
  'menuCount': 5,
  'imageUrl': '/files/booths/23/cover.webp',
};

const _special = {
  'id': 41,
  'name': '학생회 포토부스',
  'class': null,
  'category': '체험',
  'type': 'special',
  'status': 'preparing',
  'location': {'label': '본관 1층 로비'},
  'minPrice': 2000,
  'menuCount': 2,
  'imageUrl': null,
};

BoothRepository _repo(Object body) => BoothRepository(
  ApiClient(
    baseUrl: 'http://test',
    httpClient: MockClient(
      (request) async => http.Response(
        jsonEncode(body),
        200,
        headers: {'content-type': 'application/json; charset=utf-8'},
      ),
    ),
  ),
);

void main() {
  test('일반 부스 JSON 을 읽는다', () {
    final booth = Booth.fromJson(_normal);
    expect(booth.id, 23);
    expect(booth.boothClass!.grade, 2);
    expect(booth.boothClass!.classNo, 3);
    expect(booth.type, BoothType.normal);
    expect(booth.locationLabel, '신관 2층 복도');
    expect(booth.minPrice, 200);
    expect(booth.isOpen, isTrue);
    expect(booth.imageUrl, '/files/booths/23/cover.webp');
  });

  test('특별 부스는 반이 없고 그림이 없을 수 있다', () {
    final booth = Booth.fromJson(_special);
    expect(booth.boothClass, isNull);
    expect(booth.type, BoothType.special);
    expect(booth.imageUrl, isNull);
    expect(booth.isOpen, isFalse);
  });

  test('알 수 없는 부스 종류면 FormatException', () {
    expect(
      () => Booth.fromJson({..._normal, 'type': 'weird'}),
      throwsA(isA<FormatException>()),
    );
  });

  test('status 는 enum 으로 읽는다 (open · preparing · closed)', () {
    expect(Booth.fromJson(_normal).status, BoothStatus.open);
    expect(Booth.fromJson(_special).status, BoothStatus.preparing);
    expect(
      Booth.fromJson({..._normal, 'status': 'closed'}).status,
      BoothStatus.closed,
    );
  });

  test('모르는 status 면 FormatException (오타가 그냥 통과하지 않는다)', () {
    expect(
      () => Booth.fromJson({..._normal, 'status': 'opne'}),
      throwsA(isA<FormatException>()),
    );
  });

  test('위치가 정해지지 않은 부스(location null)도 읽는다', () {
    final booth = Booth.fromJson({..._normal, 'location': null});
    expect(booth.locationLabel, isNull);
    expect(booth.name, '2-3 타코야끼');
  });

  test('location 은 있는데 label 이 없어도 읽는다', () {
    final booth = Booth.fromJson({..._normal, 'location': <String, Object?>{}});
    expect(booth.locationLabel, isNull);
  });

  test('판매 중인 메뉴가 없으면(minPrice null) 가격이 null 이다', () {
    final booth = Booth.fromJson({..._normal, 'minPrice': null});
    expect(booth.minPrice, isNull);
  });

  test('위치와 가격이 둘 다 null 인 부스 하나가 있어도 목록 전체를 읽는다', () async {
    final booths = await _repo({
      'items': [
        _normal,
        {..._special, 'location': null, 'minPrice': null},
      ],
    }).booths();
    expect(booths, hasLength(2));
    expect(booths.last.locationLabel, isNull);
    expect(booths.last.minPrice, isNull);
  });

  test('booths(sort) 는 sort 쿼리를 서버에 보낸다', () async {
    Uri? seen;
    final repo = BoothRepository(
      ApiClient(
        baseUrl: 'http://test',
        httpClient: MockClient((request) async {
          seen = request.url;
          return http.Response('{"items": []}', 200);
        }),
      ),
    );
    await repo.booths(sort: 'popular');
    expect(seen!.path, '/booths');
    expect(seen!.queryParameters['sort'], 'popular');
  });

  test('booths() 는 items 를 부스 목록으로 돌려준다', () async {
    final booths = await _repo({
      'items': [_normal, _special],
    }).booths();
    expect(booths.map((b) => b.id), [23, 41]);
  });

  test('items 가 없으면 FormatException', () async {
    expect(_repo({'x': 1}).booths(), throwsA(isA<FormatException>()));
  });

  test('imageUrl 은 서버 주소와 합치고 null 은 그대로 둔다', () {
    final repo = _repo({'items': []});
    expect(repo.imageUrl('/files/a.webp'), 'http://test/files/a.webp');
    expect(repo.imageUrl(null), isNull);
  });
}
