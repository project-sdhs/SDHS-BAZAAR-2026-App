import 'package:bazaar_app/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('앱이 켜지면 홈(임시) 화면이 보인다', (tester) async {
    await tester.pumpWidget(const BazaarApp());
    await tester.pumpAndSettle();

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('준비 중'), findsOneWidget);
  });
}
