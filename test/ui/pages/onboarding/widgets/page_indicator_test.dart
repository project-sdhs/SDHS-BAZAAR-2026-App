import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/ui/pages/onboarding/widgets/page_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<Container> _dots(WidgetTester tester) => tester
    .widgetList<Container>(
      find.descendant(
        of: find.byType(PageIndicator),
        matching: find.byType(Container),
      ),
    )
    .toList();

Color _color(Container dot) => (dot.decoration! as BoxDecoration).color!;

Widget _wrap(Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(child: child),
);

void main() {
  testWidgets('지금 페이지는 20×6 파란 막대, 나머지는 6×6 회색 점', (tester) async {
    await tester.pumpWidget(_wrap(const PageIndicator(count: 3, index: 1)));

    final sizes = [
      for (final element
          in find
              .descendant(
                of: find.byType(PageIndicator),
                matching: find.byType(Container),
              )
              .evaluate())
        element.size!,
    ];
    expect(sizes, const [Size(6, 6), Size(20, 6), Size(6, 6)]);

    final dots = _dots(tester);
    expect(_color(dots[0]), AppColors.border);
    expect(_color(dots[1]), AppColors.primary);
    expect(_color(dots[2]), AppColors.border);
  });

  testWidgets('점 사이 간격은 6', (tester) async {
    await tester.pumpWidget(_wrap(const PageIndicator(count: 2, index: 0)));
    expect(
      tester.getSize(find.byType(PageIndicator)),
      const Size(20 + 6 + 6, 6),
    );
  });
}
