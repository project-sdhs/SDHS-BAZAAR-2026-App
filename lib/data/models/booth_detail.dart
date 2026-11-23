/// 부스 상세 화면 모델. 목록용 `Booth`(booth.dart)와 이름이 겹쳐서 `BoothDetail` 로 나눴어요.
class BoothDetail {
  const BoothDetail({
    required this.id,
    required this.name,
    required this.className,
    required this.isOpen,
    required this.location,
    required this.openHours,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String className;
  final bool isOpen;
  final String location;
  final String openHours;
  final String? imageUrl;

  factory BoothDetail.fromJson(Map<String, dynamic> json) {
    return BoothDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      className: json['className'] as String,
      isOpen: json['isOpen'] as bool,
      location: json['location'] as String,
      openHours: json['openHours'] as String,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'className': className,
    'isOpen': isOpen,
    'location': location,
    'openHours': openHours,
    'imageUrl': imageUrl,
  };
}
