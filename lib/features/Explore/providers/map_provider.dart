import 'dart:developer';

import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapProvider extends ChangeNotifier {
  Set<Marker> _markers = {};

  Future<BitmapDescriptor> getCustomIcon(String category) async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(24, 24)), // Set size
      _getCategoryMarker(category), // Path to the asset
    );
  }

  String _getCategoryMarker(String category) {
    switch (category) {
      case 'Class':
        return 'assets/markers/school.png';
      case 'Food':
        return 'assets/markers/food.svg';
      case 'Event':
        return 'assets/markers/event.svg';
      case 'Shop':
        return 'assets/markers/shop.svg';
      case 'Other':
        return 'assets/markers/other.svg';
      default:
        return 'assets/markers/hospital.png';
    }
  }

  void addMarker(Location data) async {
    _markers.add(
      Marker(
        markerId: MarkerId(
          data.id.toString(),
        ),
        position: LatLng(
          data.location['latitude'],
          data.location['longitude'],
        ),
        infoWindow: InfoWindow(title: data.name, snippet: data.description),
        draggable: false,
        icon: await getCustomIcon(data.category),
      ),
    );
    notifyListeners();
  }

  ///Get all markers
  Set<Marker> get markers => _markers;

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }
}
