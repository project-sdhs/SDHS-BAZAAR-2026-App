import 'dart:ui';

import '../models/booth_category.dart';
import '../models/map_marker.dart';

const List<MapMarker> mapMarkersDummy = [
  BoothMapMarker(
    id: 'booth-3-1',
    position: Offset(0.72, 0.30),
    name: '3-1 로제떡볶이',
    category: BoothCategory.snack,
    grade: 3,
  ),
  BoothMapMarker(
    id: 'booth-2-3',
    position: Offset(0.42, 0.47),
    name: '2-3 타코야끼',
    category: BoothCategory.dessert,
    grade: 2,
  ),
  BoothMapMarker(
    id: 'booth-1-2',
    position: Offset(0.28, 0.68),
    name: '1-2 보드게임',
    category: BoothCategory.activity,
    grade: 1,
  ),
  ClusterMapMarker(id: 'cluster-a', position: Offset(0.72, 0.56), count: 5),
  ClusterMapMarker(id: 'cluster-b', position: Offset(0.20, 0.32), count: 12),
];
