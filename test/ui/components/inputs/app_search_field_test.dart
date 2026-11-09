import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/ui/components/inputs/inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('검색어를 입력하고 지우기 버튼으로 비운다', (tester) async {
    final semantics = tester.ensureSemantics();
    final changes = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppSearchField(
            label: '부스 검색',
            hintText: '반 · 부스 · 메뉴 검색',
            onChanged: changes.add,
          ),
        ),
      ),
    );

    expect(find.byType(AppTextField), findsOneWidget);
    final searchSemantics = tester.getSemantics(
      find.bySemanticsLabel(RegExp(r'^부스 검색')),
    );
    expect(searchSemantics.flagsCollection.isTextField, isTrue);
    expect(
      searchSemantics.label.indexOf('부스 검색'),
      searchSemantics.label.lastIndexOf('부스 검색'),
    );

    await tester.enterText(find.byType(TextField), '타코');
    await tester.pump();
    expect(find.text('타코'), findsOneWidget);
    expect(find.byTooltip('검색어 지우기'), findsOneWidget);
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(tester.widget<Icon>(find.byIcon(Icons.search)).size, 24);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.search)).color,
      AppColors.foreground,
    );
    final decoration = tester.widget<InputDecorator>(
      find.byType(InputDecorator),
    );
    final focusedBorder =
        decoration.decoration.focusedBorder! as OutlineInputBorder;
    expect(focusedBorder.borderRadius, BorderRadius.circular(16));
    expect(focusedBorder.borderSide.width, 2);
    expect(focusedBorder.borderSide.color, AppColors.primary);

    await tester.tap(find.byTooltip('검색어 지우기'));
    await tester.pump();

    expect(find.text('타코'), findsNothing);
    expect(changes, ['타코', '']);
    semantics.dispose();
  });
}
