import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../data/dummy/map_markers_dummy.dart';
import '../../../data/models/map_marker.dart';
import 'widgets/campus_map_layer.dart';
import 'widgets/map_grade_chips.dart';
import 'widgets/map_search_bar.dart';

class MapPage extends StatefulWidget {
  const MapPage({
    super.key,
    this.markers = mapMarkersDummy,
    this.initialSelectedBoothId = 'booth-2-3',
  });

  final List<MapMarker> markers;
  final String? initialSelectedBoothId;

  static const double searchBarTop = AppSpacing.s8;
  static const double chipsTop = AppSpacing.s8;

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late String? _selectedBoothId = widget.initialSelectedBoothId;
  String _query = '';
  int? _grade;

  List<MapMarker> get _visibleMarkers {
    final query = _query.trim();
    if (query.isEmpty && _grade == null) return widget.markers;
    return [
      for (final marker in widget.markers)
        if (marker is BoothMapMarker &&
            marker.name.contains(query) &&
            (_grade == null || marker.grade == _grade))
          marker,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: false,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CampusMapLayer(
            markers: _visibleMarkers,
            selectedBoothId: _selectedBoothId,
            onBoothTap: (booth) => setState(() => _selectedBoothId = booth.id),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenHorizontal,
                  MapPage.searchBarTop,
                  AppSpacing.screenHorizontal,
                  0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: MapPage.chipsTop,
                  children: [
                    MapSearchBar(
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    MapGradeChips(
                      selectedGrade: _grade,
                      onChanged: (grade) => setState(() => _grade = grade),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
