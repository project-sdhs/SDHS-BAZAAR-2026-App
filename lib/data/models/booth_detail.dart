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
    this.operators = const [],
  });

  final String id;
  final String name;
  final String className;
  final bool isOpen;
  final String location;
  final String openHours;
  final String? imageUrl;
  final List<BoothOperator> operators;

  factory BoothDetail.fromJson(Map<String, dynamic> json) {
    return BoothDetail(
      id: json['id'] as String,
      name: json['name'] as String,
      className: json['className'] as String,
      isOpen: json['isOpen'] as bool,
      location: json['location'] as String,
      openHours: json['openHours'] as String,
      imageUrl: json['imageUrl'] as String?,
      operators: [
        for (final item in json['operators'] as List<dynamic>? ?? const [])
          BoothOperator.fromJson(item as Map<String, dynamic>),
      ],
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
    'operators': [for (final operator in operators) operator.toJson()],
  };
}

class BoothOperator {
  const BoothOperator({required this.name, required this.role});

  final String name;
  final String role;

  factory BoothOperator.fromJson(Map<String, dynamic> json) {
    return BoothOperator(
      name: json['name'] as String,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'name': name, 'role': role};
}
