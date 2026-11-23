import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// 좁은 화면(320)과 큰 글자(1.0 · 1.5 · 2.0 배)에서 넘치거나 깨지지 않는지 확인할 때 씁니다.
const kTextScales = [1.0, 1.5, 2.0];

const kLongBoothName = '학생회 굿즈샵과 아주 아주 아주 긴 이름의 부스 입니다 정말로';

/// [child] 를 [width] x [height] 화면에 [scale] 배 글자로 그리고 모든 그림이 끝날 때까지 기다립니다.
Future<void> pumpWithScale(
  WidgetTester tester,
  Widget child, {
  double width = 320,
  double scale = 1.0,
  double height = 900,
}) async {
  await tester.binding.setSurfaceSize(Size(width, height));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: app!,
      ),
      home: child,
    ),
  );
  await tester.pumpAndSettle();
}
