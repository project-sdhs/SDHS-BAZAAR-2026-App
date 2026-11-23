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

    test('인기 순이면 구역 없이 서버가 준 순서 그대로 놓는다', () {
      // 서버가 인기 순으로 정렬해 준 목록 (주문 수 많은 순)
      final byPopularity = fixtureBooths().reversed.toList();
      final sections = buildBoothSections(
        byPopularity,
        sort: BoothSort.popular,
        filter: BoothGradeFilter.all,
      );

      expect(sections, hasLength(1));
      expect(
        _names(sections),
        byPopularity.map((booth) => booth.name).toList(),
      );
    });

    test('인기 순에도 학년 필터가 적용되고 서버 순서를 지킨다', () {
      final byPopularity = [
        fixtureBooths()[2], // 2-1 츄러스
        fixtureBooths()[0],
        fixtureBooths()[1], // 2-3 타코야끼
      ];
      final sections = buildBoothSections(
        byPopularity,
        sort: BoothSort.popular,
        filter: BoothGradeFilter.grade2,
      );
      expect(_names(sections), ['2-1 츄러스', '2-3 타코야끼']);
    });
  });
}
