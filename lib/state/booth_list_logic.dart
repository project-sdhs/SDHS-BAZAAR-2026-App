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
}
