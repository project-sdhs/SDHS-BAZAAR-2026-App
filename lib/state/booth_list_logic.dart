import '../data/models/booth.dart';

/// 부스 목록 정렬 기준 (APP-26).
enum BoothSort {
  /// 학년 순 (1학년 → 3학년 → 특별부스)
  grade('학년 순'),

  /// 인기 순 (주문 수가 많은 순)
  popular('인기 순');

  const BoothSort(this.label);

  final String label;
}

/// 부스 목록을 거르는 학년 필터 (APP-27).
enum BoothGradeFilter {
  all('전체'),
  grade1('1학년'),
  grade2('2학년'),
  grade3('3학년'),
  special('특별부스');

  const BoothGradeFilter(this.label);

  final String label;

  bool accepts(Booth booth) => switch (this) {
    all => true,
    grade1 => booth.boothClass?.grade == 1,
    grade2 => booth.boothClass?.grade == 2,
    grade3 => booth.boothClass?.grade == 3,
    special => booth.type == BoothType.special,
  };
}

/// 목록에서 제목 한 줄과 그 아래 부스들 (APP-28).
class BoothSection {
  const BoothSection({required this.title, required this.booths});

  /// 예: `1학년`, `특별부스`
  final String title;
  final List<Booth> booths;
}

/// 학년 필터를 적용하고 정렬한 뒤 학년별 구역으로 나눕니다.
///
/// - [BoothSort.grade]: 1·2·3학년, 특별부스 순서로 구역을 만들고 구역 안은 반 번호 순입니다.
///   부스가 없는 구역은 만들지 않습니다.
/// - [BoothSort.popular]: 구역 없이 `인기` 한 구역에 서버가 준 순서(`GET /booths?sort=popular`,
///   주문 수 순) 그대로 늘어놓습니다. [booths] 를 인기 순으로 받아 와야 합니다.
List<BoothSection> buildBoothSections(
  List<Booth> booths, {
  required BoothSort sort,
  required BoothGradeFilter filter,
}) {
  final visible = booths.where(filter.accepts).toList();
  if (visible.isEmpty) return const [];

  if (sort == BoothSort.popular) {
    return [BoothSection(title: '인기', booths: visible)];
  }

  int classNo(Booth booth) => booth.boothClass?.classNo ?? 0;
  final sections = <BoothSection>[];
  for (final group in [
    BoothGradeFilter.grade1,
    BoothGradeFilter.grade2,
    BoothGradeFilter.grade3,
    BoothGradeFilter.special,
  ]) {
    final inGroup = visible.where(group.accepts).toList()
      ..sort((a, b) {
        final byClass = classNo(a).compareTo(classNo(b));
        return byClass != 0 ? byClass : a.name.compareTo(b.name);
      });
    if (inGroup.isNotEmpty) {
      sections.add(BoothSection(title: group.label, booths: inGroup));
    }
  }
  return sections;
}
