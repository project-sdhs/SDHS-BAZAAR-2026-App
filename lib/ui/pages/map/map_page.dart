import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/dummy/map_markers_dummy.dart';
import '../../../data/models/map_marker.dart';
import 'widgets/campus_map_layer.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.markers = mapMarkersDummy,
    this.initialSelectedBoothId = 'booth-2-3',
  });

  final List<MapMarker> markers;
  final String? initialSelectedBoothId;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late String? _selectedBoothId = widget.initialSelectedBoothId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CampusMapLayer(
        markers: widget.markers,
        selectedBoothId: _selectedBoothId,
        onBoothTap: (booth) => setState(() => _selectedBoothId = booth.id),
      ),
    );
  }
}
