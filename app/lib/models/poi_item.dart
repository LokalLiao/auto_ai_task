import 'package:flutter/material.dart';

class PoiItem {
  final String id;
  final String name;
  final String category;
  final IconData icon;
  final double latitude;
  final double longitude;
  final double distanceInMeters;

  PoiItem({
    required this.id,
    required this.name,
    required this.category,
    required this.icon,
    required this.latitude,
    required this.longitude,
    required this.distanceInMeters,
  });

  String get distanceText {
    if (distanceInMeters >= 1000) {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
    return '${distanceInMeters.toStringAsFixed(0)} m';
  }
}