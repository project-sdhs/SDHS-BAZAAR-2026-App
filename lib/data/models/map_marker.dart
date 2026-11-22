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
  });

  final String name;
  final BoothCategory category;
}

class ClusterMapMarker extends MapMarker {
  const ClusterMapMarker({
    required super.id,
    required super.position,
    required this.count,
  }) : assert(count > 1);

  final int count;
}
