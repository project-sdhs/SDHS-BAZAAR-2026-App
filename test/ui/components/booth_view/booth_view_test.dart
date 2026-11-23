import 'dart:typed_data';

import 'package:bazaar_app/core/theme/app_colors.dart';
import 'package:bazaar_app/ui/components/booth_view/booth_views.dart';
import 'package:bazaar_app/ui/components/credit_amount/credit_amount.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {double width = 390}) => MaterialApp(
  home: Scaffold(
    body: Center(
      child: SizedBox(
        width: width,
        child: Align(alignment: Alignment.topLeft, child: child),
      ),
    ),
  ),
);

BoothView _booth({
  BoothViewSize size = BoothViewSize.list,
  int? rank,
  String? trailingLabel = '주문 128',
  ImageProvider? thumbnail,
  VoidCallback? onTap,
  String name = '3-1 로제떡볶이',
}) => BoothView(
  name: name,
  category: '분식',
  locationLabel: '본관 1층 로비',
  minPrice: 1500,
  trailingLabel: trailingLabel,
  rank: rank,
  size: size,
  thumbnail: thumbnail,
  onTap: onTap,
);

void main() {
  group('크기 (Figma)', () {
    testWidgets('home 은 264 × 180', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      expect(tester.getSize(find.byType(BoothView)), const Size(264, 180));
    });

    testWidgets('map 은 264 × 176', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.map)));
      expect(tester.getSize(find.byType(BoothView)), const Size(264, 176));
    });

    testWidgets('list 는 부모 너비를 가득 채우고 높이 176', (tester) async {
      await tester.pumpWidget(_wrap(_booth(), width: 358));
      expect(tester.getSize(find.byType(BoothView)), const Size(358, 176));
    });

    testWidgets('기본 크기는 list 이고 모서리는 16', (tester) async {
      await tester.pumpWidget(_wrap(_booth(), width: 358));
      expect(_booth().size, BoothViewSize.list);
      final clip = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
      expect(clip.borderRadius, BorderRadius.circular(16));
    });
  });

  group('내용', () {
    testWidgets('이름 · 분류 · 위치 · 가격 · 주문 수를 보여 준다', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));

      expect(find.text('3-1 로제떡볶이'), findsOneWidget);
      expect(find.text('분식'), findsOneWidget);
      expect(find.text('본관 1층 로비'), findsOneWidget);
      expect(find.text('주문 128'), findsOneWidget);
      final price = tester.widget<AppCreditAmount>(
        find.byType(AppCreditAmount),
      );
      expect(price.amount, 1500);
      expect(price.fontSize, 16);
      expect(price.fontWeight, FontWeight.w700);
      expect(price.color, AppColors.onPrimary);
      expect(price.suffix, '~');
    });

    testWidgets('이름은 Bold 17 흰색 · 자간 -0.17', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      final style = tester.widget<Text>(find.text('3-1 로제떡볶이')).style!;
      expect(style.fontSize, 17);
      expect(style.fontWeight, FontWeight.w700);
      expect(style.letterSpacing, -0.17);
      expect(style.color, AppColors.onPrimary);
    });

    testWidgets('분류 배지는 높이 20 모서리 6 글자 12 SemiBold', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      final badge = tester.widget<Container>(
        find.ancestor(of: find.text('분식'), matching: find.byType(Container)),
      );
      final decoration = badge.decoration! as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(6));
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text('분식'),
                matching: find.byType(Container),
              ),
            )
            .height,
        20,
      );
      final text = tester.widget<Text>(find.text('분식')).style!;
      expect(text.fontSize, 12);
      expect(text.fontWeight, FontWeight.w600);
    });

    testWidgets('위치와 주문 수는 13 흰색', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      for (final label in ['본관 1층 로비', '주문 128']) {
        final style = tester.widget<Text>(find.text(label)).style!;
        expect(style.fontSize, 13);
        expect(style.color, AppColors.onPrimary);
      }
    });

    testWidgets('오른쪽 글자가 null 이면 숨긴다', (tester) async {
      await tester.pumpWidget(
        _wrap(_booth(size: BoothViewSize.home, trailingLabel: null)),
      );
      expect(find.textContaining('주문'), findsNothing);
    });

    testWidgets('오른쪽 글자는 문자열이라 메뉴 N개 · 도보 N분도 적을 수 있다', (tester) async {
      await tester.pumpWidget(
        _wrap(_booth(size: BoothViewSize.home, trailingLabel: '메뉴 9개')),
      );
      expect(find.text('메뉴 9개'), findsOneWidget);
    });

    testWidgets('위치와 가격이 null 이어도 그리고 그 자리는 숨긴다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BoothView(
            name: '3-3 준비 중',
            category: '체험',
            size: BoothViewSize.home,
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('3-3 준비 중'), findsOneWidget);
      expect(find.byType(AppCreditAmount), findsNothing);
    });

    testWidgets('이름이 길면 한 줄로 줄이고 넘치지 않는다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booth(
            size: BoothViewSize.map,
            name: '학생회 굿즈샵과 아주 아주 아주 긴 이름의 부스입니다',
          ),
        ),
      );
      final text = tester.widget<Text>(find.textContaining('학생회'));
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
      expect(tester.takeException(), isNull);
    });
  });

  group('배치 (Figma)', () {
    testWidgets('정보 띠 높이는 70 (이름 첫 줄 20 + 줄 사이 6 + 둘째 줄 20 + 위아래 12)', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      final panel = tester.getRect(
        find
            .ancestor(
              of: find.text('3-1 로제떡볶이'),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(panel.height, 70);
      expect(panel.top, 110);
      expect(tester.getSize(find.text('3-1 로제떡볶이')).height, 20);
    });

    testWidgets('이름은 가격을 뺀 남은 폭을 모두 쓴다 (폭의 절반에서 잘리지 않는다)', (tester) async {
      await tester.pumpWidget(
        _wrap(_booth(size: BoothViewSize.home, name: '학부모회 커피트럭 아주 긴 이름의 부스')),
      );
      final name = tester.getSize(find.textContaining('학부모회'));
      final price = tester.getSize(find.byType(AppCreditAmount));
      // 안쪽 폭 236(264 - 좌우 14) 에서 가격 칸과 간격 8 을 뺀 나머지를 모두 쓴다.
      expect(name.width, closeTo(236 - 8 - price.width, 0.5));
    });

    testWidgets('오른쪽 글자는 카드 오른쪽 안쪽 여백(14) 끝에 붙는다', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      final card = tester.getRect(find.byType(BoothView));
      final label = tester.getRect(find.text('주문 128'));
      expect(label.right, closeTo(card.right - 14, 0.5));
    });

    testWidgets('분류 배지와 위치 사이 간격은 6', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      final badge = tester.getRect(
        find.ancestor(of: find.text('분식'), matching: find.byType(Container)),
      );
      final location = tester.getRect(find.text('본관 1층 로비'));
      expect(location.left - badge.right, 6);
    });
  });

  group('색', () {
    testWidgets('정보 띠는 scrim 46% · 순위 배지는 scrim 42%', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home, rank: 1)));

      final colors = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((box) => box.color)
          .toList();
      expect(colors, contains(AppColors.scrim.withValues(alpha: 0.46)));
      final badge = tester.widget<Container>(
        find.ancestor(of: find.text('1'), matching: find.byType(Container)),
      );
      expect(badge.color, AppColors.scrim.withValues(alpha: 0.42));
    });
  });

  group('순위 배지', () {
    testWidgets('rank 가 있으면 32 지름 원에 순위를 보여 준다', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home, rank: 2)));
      expect(find.text('2'), findsOneWidget);
      final badge = find.ancestor(
        of: find.text('2'),
        matching: find.byType(Container),
      );
      expect(tester.getSize(badge), const Size(32, 32));
      final text = tester.widget<Text>(find.text('2')).style!;
      expect(text.fontSize, 15);
      expect(text.fontWeight, FontWeight.w700);
      expect(text.color, AppColors.onPrimary);
      // 카드 왼쪽 위에서 12 · 12
      final card = tester.getTopLeft(find.byType(BoothView));
      final circle = tester.getTopLeft(badge);
      expect(circle - card, const Offset(12, 12));
      expect(find.byType(ClipOval), findsOneWidget);
    });

    testWidgets('rank 가 없으면 배지를 그리지 않는다', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      expect(find.byType(ClipOval), findsNothing);
    });
  });

  group('썸네일', () {
    // 가격 옆 코인도 Image 라서, 카드 배경(BoxFit.cover)만 따로 찾습니다.
    final thumbnailFinder = find.byWidgetPredicate(
      (widget) => widget is Image && widget.fit == BoxFit.cover,
    );

    bool hasFallback(WidgetTester tester) => tester
        .widgetList<ColoredBox>(find.byType(ColoredBox))
        .any((box) => box.color == AppColors.body);

    testWidgets('thumbnail 이 없으면 fallbackColor 로 채운다', (tester) async {
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      expect(thumbnailFinder, findsNothing);
      expect(hasFallback(tester), isTrue);
    });

    testWidgets('thumbnail 이 있으면 가득 채워 그린다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booth(
            size: BoothViewSize.home,
            thumbnail: MemoryImage(_transparentPng),
          ),
        ),
      );
      await tester.pump();
      expect(thumbnailFinder, findsOneWidget);
    });

    testWidgets('그림을 불러오지 못하면 fallbackColor 로 바꾸고 카드는 그대로다', (tester) async {
      await tester.pumpWidget(
        _wrap(
          _booth(
            size: BoothViewSize.home,
            thumbnail: MemoryImage(Uint8List.fromList([0, 1, 2])),
          ),
        ),
      );
      expect(hasFallback(tester), isFalse); // 아직 불러오는 중
      // 이미지 해독은 실제 비동기라서 잠시 기다린 뒤 다시 그립니다.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 200)),
      );
      await tester.pump();

      expect(hasFallback(tester), isTrue);
      expect(find.text('3-1 로제떡볶이'), findsOneWidget);
    });
  });

  group('동작과 접근성', () {
    testWidgets('누르면 onTap 이 불린다', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _wrap(_booth(size: BoothViewSize.home, onTap: () => taps++)),
      );
      await tester.tap(find.byType(BoothView));
      expect(taps, 1);
    });

    testWidgets('접근성 라벨에 순위 · 이름 · 분류 · 위치 · 가격 · 주문 수가 들어 있다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(
        _wrap(_booth(size: BoothViewSize.home, rank: 1, onTap: () {})),
      );
      final node = tester.getSemantics(find.byType(BoothView));
      expect(node.label, '1위, 3-1 로제떡볶이, 분식, 본관 1층 로비, 1,500크레딧부터, 주문 128');
      expect(node.flagsCollection.isButton, isTrue);
      semantics.dispose();
    });

    testWidgets('onTap 이 없으면 버튼으로 읽히지 않는다', (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_wrap(_booth(size: BoothViewSize.home)));
      expect(
        tester.getSemantics(find.byType(BoothView)).flagsCollection.isButton,
        isFalse,
      );
      semantics.dispose();
    });
  });
}

/// 1×1 투명 PNG
final Uint8List _transparentPng = Uint8List.fromList(const [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xFF, 0xFF, 0x3F,
  0x00, 0x05, 0xFE, 0x02, 0xFE, 0xDC, 0xCC, 0x59, 0xE7, 0x00, 0x00, 0x00,
  0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);
