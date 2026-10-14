import 'package:bazaar_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('앱이 켜지면 온보딩 첫 화면이 보인다', (tester) async {
    await tester.pumpWidget(const BazaarApp());
    await tester.pumpAndSettle();

    expect(find.text('종이 토큰 대신\n크레딧으로 결제해요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);
  });
}
