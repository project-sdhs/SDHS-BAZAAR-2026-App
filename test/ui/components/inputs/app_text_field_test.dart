import 'package:bazaar_app/ui/components/inputs/inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('초기값과 오류 안내를 표시한다', (tester) async {
    await tester.pumpWidget(
      appWith(
        const AppTextField(initialValue: '22-5', errorText: '학번 형식이 맞지 않아요.'),
      ),
    );

    expect(find.text('22-5'), findsOneWidget);
    expect(find.text('학번 형식이 맞지 않아요.'), findsOneWidget);
  });

  testWidgets('비활성 필드는 편집할 수 없다', (tester) async {
    await tester.pumpWidget(
      appWith(const AppTextField(initialValue: '2학년 3반', enabled: false)),
    );

    await tester.tap(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '변경');
    await tester.pump();

    expect(find.text('2학년 3반'), findsOneWidget);
  });
}
