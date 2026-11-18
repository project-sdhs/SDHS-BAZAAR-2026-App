class Booth {
  const Booth({
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

  factory Booth.fromJson(Map<String, dynamic> json) {
    return Booth(
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
