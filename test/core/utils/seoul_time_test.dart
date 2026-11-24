import 'package:bazaar_app/core/utils/seoul_time.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('UTC 15:10 은 서울로 다음 날 00:10 이다', () {
    final time = DateTime.utc(2026, 10, 23, 15, 10);
    expect(seoulDay(time), DateTime.utc(2026, 10, 24));
    expect(seoulHourMinute(time), '00:10');
    expect(seoulDayLabel(time), '10월 24일 토요일');
  });

  test('UTC 14:59 는 아직 같은 날이다', () {
    final time = DateTime.utc(2026, 10, 23, 14, 59);
    expect(seoulDay(time), DateTime.utc(2026, 10, 23));
    expect(seoulDayLabel(time), '10월 23일 금요일');
  });

  test('기기 시간대와 상관없이 같은 결과', () {
    final utc = DateTime.utc(2026, 10, 23, 15, 10);
    expect(seoulDay(utc.toLocal()), seoulDay(utc));
    expect(parseSeoulDate('2026-10-24'), DateTime.utc(2026, 10, 24));
  });
}
