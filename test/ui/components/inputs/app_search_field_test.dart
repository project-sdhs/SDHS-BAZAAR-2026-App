import 'package:bazaar_app/ui/components/inputs/inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('검색어를 입력하고 지우기 버튼으로 비운다', (tester) async {
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            hintText: '반 · 부스 · 메뉴 검색',
            onChanged: changes.add,
          ),
        ),
      ),
    );

    expect(find.byType(AppTextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), '타코');
    await tester.pump();
    expect(find.text('타코'), findsOneWidget);
    expect(find.byTooltip('검색어 지우기'), findsOneWidget);

    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump();

    expect(find.text('타코'), findsNothing);
    expect(changes, ['타코', '']);
  });
}
