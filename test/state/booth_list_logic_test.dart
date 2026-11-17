import 'package:bazaar_app/data/models/popular_booth.dart';
import 'package:bazaar_app/state/booth_list_logic.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/booth_fixtures.dart';

List<String> _names(Iterable<BoothSection> sections) => [
  for (final s in sections)
    for (final b in s.booths) b.name,
];

void main() {
  group('buildBoothSections (APP-26 · 27 · 28)', () {
    test('학년 순이면 학년별 구역으로 나누고 구역 안은 반 번호 순이다', () {
      final sections = buildBoothSections(
        fixtureBooths(),
        sort: BoothSort.grade,
        filter: BoothGradeFilter.all,
      );

      expect(sections.map((s) => s.title), ['1학년', '2학년', '3학년', '특별부스']);
      expect(sections[1].booths.map((b) => b.name), ['2-1 츄러스', '2-3 타코야끼']);
    });

    test('학년 필터는 그 학년 구역만 남긴다', () {
      final grade2 = buildBoothSections(
        fixtureBooths(),
        sort: BoothSort.grade,
        filter: BoothGradeFilter.grade2,
      );
      expect(grade2.map((s) => s.title), ['2학년']);

      final special = buildBoothSections(
        fixtureBooths(),
        sort: BoothSort.grade,
        filter: BoothGradeFilter.special,
      );
      expect(_names(special), ['학생회 포토부스']);
    });

    test('부스가 없는 학년이면 빈 목록을 돌려준다', () {
      expect(
        buildBoothSections(
          [fixtureBooth(id: 1, name: '1-1 A', grade: 1)],
          sort: BoothSort.grade,
          filter: BoothGradeFilter.grade3,
        ),
        isEmpty,
      );
    });

    test('인기 순이면 구역 없이 인기 순위대로 놓고 순위 밖은 이름 순으로 뒤에 붙는다', () {
      final sections = buildBoothSections(
        fixtureBooths(),
        sort: BoothSort.popular,
        filter: BoothGradeFilter.all,
        popular: const [
          PopularBooth(rank: 1, boothId: 4, name: 'x', paymentCount: 128),
          PopularBooth(rank: 2, boothId: 2, name: 'x', paymentCount: 97),
        ],
      );

      expect(sections, hasLength(1));
      expect(_names(sections), [
        '3-1 로제떡볶이',
        '2-3 타코야끼',
        '1-2 컵밥분식',
        '2-1 츄러스',
        '학생회 포토부스',
      ]);
    });

    test('인기 순에도 학년 필터가 적용된다', () {
      final sections = buildBoothSections(
        fixtureBooths(),
        sort: BoothSort.popular,
        filter: BoothGradeFilter.grade2,
        popular: const [
          PopularBooth(rank: 1, boothId: 2, name: 'x', paymentCount: 97),
        ],
      );
      expect(_names(sections), ['2-3 타코야끼', '2-1 츄러스']);
    });

    test('인기 정보가 없어도 인기 순은 이름 순으로 보여 준다', () {
      final sections = buildBoothSections(
        fixtureBooths(),
        sort: BoothSort.popular,
        filter: BoothGradeFilter.grade2,
      );
      expect(_names(sections), ['2-1 츄러스', '2-3 타코야끼']);
    });
  });
}
