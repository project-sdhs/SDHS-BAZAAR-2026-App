import 'package:bazaar_app/data/models/booth.dart';
import 'package:bazaar_app/ui/components/basic/basic.dart';
import 'package:bazaar_app/ui/pages/booth_detail/widgets/booth_info_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _booth = Booth(
  id: 'b1',
  name: '2-3 타코야끼',
  className: '2학년 3반',
  isOpen: true,
  location: '신관 2층 복도',
  openHours: '10:00–15:00',
);

Future<void> _pump(WidgetTester tester, Booth booth) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 358, child: BoothInfoHeader(booth: booth)),
      ),
    ),
  );
}

void main() {
  testWidgets('반 · 운영 상태 · 이름 · 위치와 시간을 보여준다', (tester) async {
    await _pump(tester, _booth);

    expect(find.widgetWithText(AppBadge, '2학년 3반'), findsOneWidget);
    expect(find.widgetWithText(AppBadge, '운영 중'), findsOneWidget);
    expect(find.text('2-3 타코야끼'), findsOneWidget);
    expect(find.text('신관 2층 복도 · 10:00–15:00'), findsOneWidget);
  });

  testWidgets('운영 중이 아니면 운영 종료로 보여준다', (tester) async {
    await _pump(
      tester,
      const Booth(
        id: 'b2',
        name: '1-1 떡볶이',
        className: '1학년 1반',
        isOpen: false,
        location: '본관 1층',
        openHours: '11:00–14:00',
      ),
    );

    final badge = tester.widget<AppBadge>(
      find.widgetWithText(AppBadge, '운영 종료'),
    );
    expect(badge.variant, AppBadgeVariant.neutral);
    expect(find.text('운영 중'), findsNothing);
  });

  testWidgets('이미지가 없으면 대체 이미지를 296:148 비율로 보여준다', (tester) async {
    await _pump(tester, _booth);

    expect(find.byIcon(Icons.storefront_outlined), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    final size = tester.getSize(find.byType(AspectRatio));
    expect(size.width / size.height, closeTo(296 / 148, 0.001));
  });

  test('Booth 는 JSON 으로 주고받을 수 있다', () {
    final json = {
      'id': 'b1',
      'name': '2-3 타코야끼',
      'className': '2학년 3반',
      'isOpen': true,
      'location': '신관 2층 복도',
      'openHours': '10:00–15:00',
      'imageUrl': 'https://example.com/a.png',
      'operators': [
        {'name': '김서연', 'role': '반장'},
      ],
    };
    final booth = Booth.fromJson(json);
    expect(booth.imageUrl, 'https://example.com/a.png');
    expect(booth.toJson(), json);
  });
}
