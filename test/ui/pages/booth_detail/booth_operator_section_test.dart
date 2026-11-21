import 'package:bazaar_app/data/models/booth.dart';
import 'package:bazaar_app/ui/components/basic/basic.dart';
import 'package:bazaar_app/ui/pages/booth_detail/widgets/booth_operator_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _operators = [
  BoothOperator(name: '김서연', role: '반장'),
  BoothOperator(name: '이도윤', role: '캐셔'),
];

Future<void> _pump(WidgetTester tester, List<BoothOperator> operators) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 358,
          child: BoothOperatorSection(operators: operators),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('제목과 운영진의 이름 · 역할 · 첫 글자 아바타를 보여준다', (tester) async {
    await _pump(tester, _operators);

    expect(find.text('부스 운영진'), findsOneWidget);
    expect(find.byType(BoothOperatorTile), findsNWidgets(2));
    expect(find.text('김서연'), findsOneWidget);
    expect(find.text('반장'), findsOneWidget);
    expect(find.text('이도윤'), findsOneWidget);
    expect(find.text('캐셔'), findsOneWidget);
    expect(find.text('김'), findsOneWidget);
    expect(find.text('이'), findsOneWidget);
    expect(
      tester.getSize(find.byType(AppAvatar).first),
      const Size.square(BoothOperatorTile.avatarSize),
    );
  });

  testWidgets('역할이 비어 있으면 이름만 보여준다', (tester) async {
    await _pump(tester, const [BoothOperator(name: '박하늘', role: '')]);

    expect(find.text('박하늘'), findsOneWidget);
    final column = tester.widget<Column>(
      find.descendant(
        of: find.byType(BoothOperatorTile),
        matching: find.byType(Column),
      ),
    );
    expect(column.children, hasLength(1));
  });

  test('운영진 JSON 을 변환하고 없으면 빈 목록이다', () {
    final booth = Booth.fromJson({
      'id': 'b1',
      'name': '2-3 타코야끼',
      'className': '2학년 3반',
      'isOpen': true,
      'location': '신관 2층 복도',
      'openHours': '10:00–15:00',
      'operators': [
        {'name': '김서연', 'role': '반장'},
      ],
    });

    expect(booth.operators.single.name, '김서연');
    expect(booth.operators.single.role, '반장');
    expect(Booth.fromJson(booth.toJson()).operators.single.role, '반장');

    final withoutOperators = Booth.fromJson({
      'id': 'b2',
      'name': '1-1 떡볶이',
      'className': '1학년 1반',
      'isOpen': false,
      'location': '본관 1층',
      'openHours': '11:00–14:00',
    });
    expect(withoutOperators.operators, isEmpty);
  });
}
