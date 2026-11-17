import 'package:bazaar_app/core/router/app_router.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/ui/pages/booths/booth_search_page.dart';
import 'package:bazaar_app/ui/pages/booths/booths_page.dart';
import 'package:bazaar_app/ui/pages/booths/widgets/booth_search_bar.dart';
import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/ui/components/inputs/inputs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('BoothSearchBar', () {
    testWidgets('바 높이 56, 필드 높이 48, 취소 영역 높이 48, 간격 8 (Figma)', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoothSearchBar(
            controller: TextEditingController(),
            onChanged: (_) {},
            onSubmitted: (_) {},
            onCancel: () {},
          ),
        ),
      );

      expect(tester.getSize(find.byType(BoothSearchBar)).height, 56);
      expect(tester.getSize(find.byType(AppSearchField)).height, 48);
      expect(find.text('반 · 부스 · 메뉴 검색'), findsOneWidget);

      final field = tester.getRect(find.byType(AppSearchField));
      expect(field.left, 16);
      final cancel = tester.getRect(
        find
            .ancestor(
              of: find.text('취소'),
              matching: find.byType(ConstrainedBox),
            )
            .first,
      );
      expect(cancel.height, 48);
      expect(cancel.left - field.right, 8);
    });

    testWidgets('취소는 16px 600 이고 입력창 모서리는 14, 아이콘은 20 이다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoothSearchBar(
            controller: TextEditingController(text: '타'),
            onChanged: (_) {},
            onSubmitted: (_) {},
            onCancel: () {},
          ),
        ),
      );

      final cancel = tester.widget<Text>(find.text('취소'));
      expect(cancel.style!.fontSize, 16);
      expect(cancel.style!.fontWeight, FontWeight.w600);
      expect(cancel.style!.color, AppColors.body);
      expect(tester.widget<Icon>(find.byIcon(Icons.search)).size, 20);
      expect(tester.widget<Icon>(find.byIcon(Icons.cancel)).size, 20);
      final text = tester.widget<EditableText>(find.byType(EditableText));
      expect(text.style.fontSize, 16);
    });

    testWidgets('화면이 열리면 입력창에 포커스가 간다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoothSearchBar(
            controller: TextEditingController(),
            onChanged: (_) {},
            onSubmitted: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isTrue);
    });

    testWidgets('autofocus 를 끄면 포커스가 가지 않는다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          BoothSearchBar(
            controller: TextEditingController(),
            autofocus: false,
            onChanged: (_) {},
            onSubmitted: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pump();

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.focusNode.hasFocus, isFalse);
    });

    testWidgets('입력하면 onChanged 로 전달하고 지우기 버튼으로 비운다', (tester) async {
      final controller = TextEditingController();
      final changes = <String>[];
      await tester.pumpWidget(
        _wrap(
          BoothSearchBar(
            controller: controller,
            onChanged: changes.add,
            onSubmitted: (_) {},
            onCancel: () {},
          ),
        ),
      );

      expect(find.byTooltip('검색어 지우기'), findsNothing);

      await tester.enterText(find.byType(TextField), '타코');
      await tester.pump();
      expect(changes, ['타코']);
      expect(find.byTooltip('검색어 지우기'), findsOneWidget);

      await tester.tap(find.byTooltip('검색어 지우기'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(changes.last, '');
      expect(find.byTooltip('검색어 지우기'), findsNothing);
    });

    testWidgets('키보드 검색 버튼을 누르면 onSubmitted 로 전달한다', (tester) async {
      final submitted = <String>[];
      await tester.pumpWidget(
        _wrap(
          BoothSearchBar(
            controller: TextEditingController(),
            onChanged: (_) {},
            onSubmitted: submitted.add,
            onCancel: () {},
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), '떡볶이');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(submitted, ['떡볶이']);
    });

    testWidgets('취소를 누르면 onCancel 을 부르고 접근성 버튼으로 읽힌다', (tester) async {
      final semantics = tester.ensureSemantics();
      var cancelled = 0;
      await tester.pumpWidget(
        _wrap(
          BoothSearchBar(
            controller: TextEditingController(),
            onChanged: (_) {},
            onSubmitted: (_) {},
            onCancel: () => cancelled++,
          ),
        ),
      );

      expect(
        tester
            .getSemantics(find.bySemanticsLabel('취소'))
            .flagsCollection
            .isButton,
        isTrue,
      );
      await tester.tap(find.text('취소'));
      expect(cancelled, 1);
      semantics.dispose();
    });
  });

  group('BoothSearchPage 경로', () {
    testWidgets('검색 경로는 탭 바 없이 검색 화면을 연다', (tester) async {
      final router = createAppRouter(initialLocation: Routes.boothSearch);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(BoothSearchPage), findsOneWidget);
      expect(find.byKey(const Key('bottomTabBar')), findsNothing);
    });

    testWidgets('이전 화면이 없을 때 취소하면 부스 탭으로 간다', (tester) async {
      final router = createAppRouter(initialLocation: Routes.boothSearch);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();

      expect(find.byType(BoothsPage), findsOneWidget);
      expect(find.byType(BoothSearchPage), findsNothing);
    });
  });
}
