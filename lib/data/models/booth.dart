class Booth {
  const Booth({
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

  factory Booth.fromJson(Map<String, dynamic> json) {
    return Booth(
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
