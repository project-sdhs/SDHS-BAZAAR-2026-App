import 'package:bazaar_app/data/models/qr_pay.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('코드만 있으면 그 코드와 print 출처', () {
    expect(QrPayload.parse('K7Q2M9X4TB'), const QrPayload('K7Q2M9X4TB'));
    expect(QrPayload.parse('  K7Q2M9X4TB\n').code, 'K7Q2M9X4TB');
  });

  test('https://<아무 주소>/q/<코드>?src= 에서 코드와 출처를 꺼낸다', () {
    expect(
      QrPayload.parse('https://bazaar.example.com/q/K7Q2M9X4TB?src=board'),
      const QrPayload('K7Q2M9X4TB', source: PaymentSource.board),
    );
    expect(
      QrPayload.parse('https://other.host.kr/q/K7Q2M9X4TB?src=print').source,
      PaymentSource.print,
    );
    // src 가 없으면 print
    expect(
      QrPayload.parse('https://bazaar.example.com/q/K7Q2M9X4TB'),
      const QrPayload('K7Q2M9X4TB'),
    );
  });

  test('바자회 QR 이 아니면 tryParse 는 null, parse 는 FormatException', () {
    for (final bad in [
      '',
      'hello',
      'K7Q2M9X4T', // 9자리
      'K7Q2M9X4TB1', // 11자리
      'K7Q2-9X4TB',
      'https://example.com/unrelated',
      'https://bazaar.example.com/q/',
      'https://bazaar.example.com/q/SHORT',
      'https://bazaar.example.com/x/K7Q2M9X4TB',
      'https://bazaar.example.com/q/K7Q2M9X4TB/extra',
      'ftp://bazaar.example.com/q/K7Q2M9X4TB',
      'WIFI:S:school;T:WPA;P:secret;;',
    ]) {
      expect(QrPayload.tryParse(bad), isNull, reason: bad);
      expect(() => QrPayload.parse(bad), throwsFormatException, reason: bad);
    }
  });
}
