import 'package:bazaar_app/ui/navigation/app_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<void> pumpTopBar(WidgetTester tester, {VoidCallback? onShare}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: AppTopBar(title: '부스 상세', description: '설명', onShare: onShare),
        ),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.pumpAndSettle();
}

void main() {
  // [리뷰 3·4] 첫 화면의 뒤로 버튼과 요청하지 않은 공유 버튼은 숨김
  testWidgets('첫 화면은 뒤로 버튼과 공유 버튼을 표시하지 않는다', (tester) async {
    await pumpTopBar(tester);
    expect(find.byTooltip('뒤로가기'), findsNothing);
    expect(find.byTooltip('공유'), findsNothing);
    expect(find.text('부스 상세'), findsOneWidget);
  });

  // [리뷰 4] 실제 공유 구현 대신 화면에서 전달한 콜백만 호출
  testWidgets('공유 버튼은 선택적으로 표시하고 전달받은 함수를 실행한다', (tester) async {
    var shareCount = 0;
    await pumpTopBar(tester, onShare: () => shareCount++);
    final shareButton = find.byTooltip('공유');
    expect(shareButton, findsOneWidget);
    expect(tester.getSize(shareButton), const Size(48, 48));
    await tester.tap(shareButton);
    expect(shareCount, 1);
    expect(find.byTooltip('뒤로가기'), findsNothing);
  });
}
