import 'package:flutter/material.dart';

abstract final class MapMarkerStyle {
  static const List<BoxShadow> shadow = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
}
