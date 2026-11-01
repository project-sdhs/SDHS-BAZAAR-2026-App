import 'package:bazaar_app/ui/components/feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('빈 상태에 제목과 안내를 표시한다', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(title: '검색 결과가 없어요', message: '다시 검색해 보세요'),
        ),
      ),
    );

    expect(find.text('검색 결과가 없어요'), findsOneWidget);
    expect(find.text('다시 검색해 보세요'), findsOneWidget);
  });

  testWidgets('다이얼로그 확인 결과를 반환한다', (tester) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await AppDialog.show(
                  context,
                  title: '캐셔 권한을 줄까요?',
                  message: '학생이 결제를 받을 수 있게 돼요.',
                );
              },
              child: const Text('열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('캐셔 권한을 줄까요?'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });

  testWidgets('토스트 메시지를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppToast.show(context, message: '저장됐어요'),
              child: const Text('토스트'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('토스트'));
    await tester.pump();

    expect(find.text('저장됐어요'), findsOneWidget);
  });

  testWidgets('바텀시트를 표시한다', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => AppBottomSheet.show<void>(
                context,
                builder: (_) => const SizedBox(
                  height: 100,
                  child: Center(child: Text('시트 콘텐츠')),
                ),
              ),
              child: const Text('시트 열기'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('시트 열기'));
    await tester.pumpAndSettle();

    expect(find.text('시트 콘텐츠'), findsOneWidget);
  });
}
