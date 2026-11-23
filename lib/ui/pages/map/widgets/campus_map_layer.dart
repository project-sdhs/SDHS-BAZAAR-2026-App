import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/map_marker.dart';
import '../../../components/basic/booth_category_icon.dart';
import 'booth_marker.dart';
import 'cluster_marker.dart';

class CampusMapLayer extends StatelessWidget {
  const CampusMapLayer({
    super.key,
    required this.markers,
    this.selectedBoothId,
    this.onBoothTap,
    this.onClusterTap,
  });

  final List<MapMarker> markers;
  final String? selectedBoothId;
  final ValueChanged<BoothMapMarker>? onBoothTap;
  final ValueChanged<ClusterMapMarker>? onClusterTap;

  @override
  Widget build(BuildContext context) {
    final ordered = [
      ...markers.where((marker) => marker.id != selectedBoothId),
      ...markers.where((marker) => marker.id == selectedBoothId),
    ];

    return ColoredBox(
      color: AppColors.surface,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            for (final marker in ordered)
              Positioned(
                key: ValueKey(marker.id),
                left: marker.position.dx * constraints.maxWidth,
                top: marker.position.dy * constraints.maxHeight,
                child: FractionalTranslation(
                  translation: switch (marker) {
                    BoothMapMarker() => const Offset(-0.5, -1),
                    ClusterMapMarker() => const Offset(-0.5, -0.5),
                  },
                  child: _buildMarker(marker),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarker(MapMarker marker) => switch (marker) {
    BoothMapMarker() => BoothMarker(
      name: marker.name,
      icon: marker.category.icon,
      selected: marker.id == selectedBoothId,
      onTap: onBoothTap == null ? null : () => onBoothTap!(marker),
    ),
    ClusterMapMarker() => ClusterMarker(
      count: marker.count,
      onTap: onClusterTap == null ? null : () => onClusterTap!(marker),
    ),
  };
}
