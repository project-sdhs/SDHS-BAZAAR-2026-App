import 'package:bazaar_app/app.dart';
import 'package:bazaar_app/core/router/routes.dart';
import 'package:bazaar_app/core/theme/app_theme.dart';
import 'package:bazaar_app/ui/components/basic/basic.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(
  home: Scaffold(body: child),
  theme: AppTheme.light,
);

void main() {
  testWidgets('칩은 부모 선택 값을 갱신하고 비활성 칩은 반응하지 않는다', (tester) async {
    bool selected = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => Column(
            children: [
              AppChip(
                '1학년',
                selected: selected,
                onSelected: (value) => setState(() => selected = value),
              ),
              const AppChip('비활성', onSelected: null),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.text('1학년'));
    await tester.pumpAndSettle();
    expect(selected, isTrue);
    await tester.tap(find.text('비활성'));
    expect(selected, isTrue);
    await tester.tap(find.text('1학년'));
    await tester.pumpAndSettle();
    expect(selected, isFalse);
  });

  testWidgets('세그먼트는 키보드와 터치로 선택하고 null 콜백이면 변경하지 않는다', (tester) async {
    String value = 'grade';
    Widget control(ValueChanged<String>? callback) =>
        AppSegmentedControl<String>(
          items: const {'grade': '학년 순', 'popular': '인기 순'},
          value: value,
          onChanged: callback,
        );
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) =>
              control((next) => setState(() => value = next)),
        ),
      ),
    );
    await tester.tap(find.text('인기 순'));
    await tester.pumpAndSettle();
    expect(value, 'popular');
    await tester.pumpWidget(host(control(null)));
    await tester.tap(find.text('학년 순'));
    await tester.pumpAndSettle();
    expect(value, 'popular');
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) =>
              control((next) => setState(() => value = next)),
        ),
      ),
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(value, 'grade');
  });

  testWidgets('스위치는 외부 값을 갱신한다', (tester) async {
    bool value = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => AppToggle(
            label: '주문 알림',
            value: value,
            onChanged: (next) => setState(() => value = next),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(AppToggle));
    await tester.pumpAndSettle();
    expect(value, isTrue);
  });

  testWidgets('아바타는 첫 유니코드 문자와 빈 이름을 처리한다', (tester) async {
    await tester.pumpWidget(
      host(
        const Row(
          children: [
            AppAvatar(name: '👨‍👩‍👧 가족'),
            AppAvatar(name: '  '),
          ],
        ),
      ),
    );
    expect(find.text('👨‍👩‍👧'), findsOneWidget);
    expect(find.byIcon(Icons.person_outline), findsOneWidget);
  });

  testWidgets('좁은 화면과 큰 글씨에서도 목록과 스켈레톤은 넘치지 않는다', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      host(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Column(
            children: [
              AppListRow(
                title: '아주 긴 부스 이름입니다',
                subtitle: '신관 2층 복도에 있는 부스',
                leading: AppAvatar(name: '홍길동'),
                trailing: AppBadge('품절', variant: AppBadgeVariant.danger),
              ),
              AppSkeletonList(),
            ],
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('카탈로그가 앱 경로에서 열리고 미리보기 스위치로 로딩을 끝낸다', (tester) async {
    await tester.pumpWidget(const BazaarApp(initialLocation: Routes.devBasics));
    await tester.pumpAndSettle();
    expect(find.text('APP-08 · 기본 위젯'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('로딩 미리보기'), 350);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppToggle).last);
    await tester.pumpAndSettle();
    expect(find.byType(AppSkeletonList), findsNothing);
    expect(find.text('2-3 타코야끼'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
