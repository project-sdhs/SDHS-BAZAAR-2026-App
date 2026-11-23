import 'dart:ui';

import 'booth_category.dart';

sealed class MapMarker {
  const MapMarker({required this.id, required this.position});

  final String id;
  final Offset position;
}

class BoothMapMarker extends MapMarker {
  const BoothMapMarker({
    required super.id,
    required super.position,
    required this.name,
    required this.category,
    required this.grade,
  }) : assert(grade >= 1 && grade <= 3);

  final String name;
  final BoothCategory category;
  final int grade;
}

class ClusterMapMarker extends MapMarker {
  const ClusterMapMarker({
    required super.id,
    required super.position,
    required this.count,
  }) : assert(count > 1);

  final int count;
}
