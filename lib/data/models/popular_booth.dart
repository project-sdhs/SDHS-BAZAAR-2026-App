/// 인기 부스 한 줄 (`GET /booths/popular` 의 `items` 한 개).
class PopularBooth {
  const PopularBooth({
    required this.rank,
    required this.boothId,
    required this.name,
    required this.paymentCount,
  });

  factory PopularBooth.fromJson(Map<String, Object?> json) => PopularBooth(
    rank: json['rank']! as int,
    boothId: json['boothId']! as int,
    name: json['name']! as String,
    paymentCount: json['paymentCount']! as int,
  );

  /// 1부터 시작하는 순위
  final int rank;
  final int boothId;
  final String name;

  /// 주문(결제) 수
  final int paymentCount;
}
