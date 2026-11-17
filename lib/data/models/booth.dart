/// 부스가 속한 반 (특별 부스는 반이 없어서 [Booth.boothClass] 가 null 입니다).
class BoothClass {
  const BoothClass({
    required this.id,
    required this.grade,
    required this.classNo,
    required this.name,
  });

  factory BoothClass.fromJson(Map<String, Object?> json) => BoothClass(
    id: json['id']! as int,
    grade: json['grade']! as int,
    classNo: json['classNo']! as int,
    name: json['name']! as String,
  );

  final int id;
  final int grade;
  final int classNo;

  /// 예: `2학년 3반`
  final String name;
}

enum BoothType {
  /// 반에서 운영하는 일반 부스
  normal,

  /// 선생님 · 학생회 등이 운영하는 특별 부스
  special;

  static BoothType parse(String value) => switch (value) {
    'normal' => normal,
    'special' => special,
    _ => throw FormatException('알 수 없는 부스 종류예요: $value'),
  };
}

/// 부스 한 곳 (`GET /booths` 의 `items` 한 개).
class Booth {
  const Booth({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.status,
    required this.locationLabel,
    required this.minPrice,
    required this.menuCount,
    this.boothClass,
    this.imageUrl,
  });

  factory Booth.fromJson(Map<String, Object?> json) {
    final boothClass = json['class'];
    final location = json['location']! as Map<String, Object?>;
    return Booth(
      id: json['id']! as int,
      name: json['name']! as String,
      boothClass: boothClass == null
          ? null
          : BoothClass.fromJson(boothClass as Map<String, Object?>),
      category: json['category']! as String,
      type: BoothType.parse(json['type']! as String),
      status: json['status']! as String,
      locationLabel: location['label']! as String,
      minPrice: json['minPrice']! as int,
      menuCount: json['menuCount']! as int,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final int id;
  final String name;
  final BoothClass? boothClass;
  final String category;
  final BoothType type;

  /// 서버 값 그대로 (`open` 등)
  final String status;
  final String locationLabel;

  /// 메뉴 중 가장 싼 가격 (크레딧)
  final int minPrice;
  final int menuCount;

  /// 서버 기준 상대 경로 (예: `/files/booths/23/cover.webp`)
  final String? imageUrl;

  bool get isOpen => status == 'open';
}
