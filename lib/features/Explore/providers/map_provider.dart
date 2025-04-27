import 'dart:developer' show log;

import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapProvider extends ChangeNotifier {
  final Set<Marker> _markers = {};

  Future<BitmapDescriptor> getCustomIcon(String category) async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(24, 24)), // Set size
      _getCategoryMarker(category), // Path to the asset
    );
  }

  Future<BitmapDescriptor> getCustomIconColor(String category) async {
    try {
      return await BitmapDescriptor.defaultMarkerWithHue(
          _getCategoryHue(category));
    } catch (e) {
      log('Error getting custom icon: $e');
      return BitmapDescriptor.defaultMarker;
    }
  }

  double _getCategoryHue(String category) {
    switch (category.toLowerCase()) {
      case 'class':
      case 'classes':
        return BitmapDescriptor.hueAzure;
      case 'food':
      case 'restaurant':
      case 'bars & pubs':
        return BitmapDescriptor.hueOrange;
      case 'pharmacy':
      case 'pharmacies':
      case 'hospital':
        return BitmapDescriptor.hueRed;
      case 'office':
      case 'offices':
        return BitmapDescriptor.hueViolet;
      case 'atm':
      case 'atms':
        return BitmapDescriptor.hueCyan;
      case 'gym':
      case 'gyms':
        return BitmapDescriptor.hueYellow;
      case 'hostels':
      case 'hostel':
        return BitmapDescriptor.hueMagenta;
      case 'store':
      case 'shop':
      case 'shopping centers':
        return BitmapDescriptor.hueGreen;
      case 'church':
      case 'churches':
        return BitmapDescriptor.hueRose;
      default:
        return BitmapDescriptor.hueRed;
    }
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

  // void addMarker(Location data) async {
  //   _markers.add(
  //     Marker(
  //       markerId: MarkerId(
  //         data.id.toString(),
  //       ),
  //       position: LatLng(
  //         data.location['latitude'],
  //         data.location['longitude'],
  //       ),
  //       infoWindow: InfoWindow(title: data.name, snippet: data.description),
  //       draggable: false,
  //       icon: await getCustomIcon(data.category),
  //     ),
  //   );
  //   notifyListeners();
  // }

  void addMarker(Location data) async {
    try {
      _markers.add(
        Marker(
          markerId: MarkerId(data.id?.toString() ?? DateTime.now().toString()),
          position: LatLng(
            data.location['latitude'],
            data.location['longitude'],
          ),
          infoWindow: InfoWindow(
            title: data.name,
            snippet: data.description ?? data.category,
            onTap: () {
              // InfoWindow tap handler could be added here
            },
          ),
          draggable: false,
          icon: await getCustomIcon(data.category),
        ),
      );
      notifyListeners();
    } catch (e) {
      log('Error adding marker: $e');
    }
  }

  void addUserLocationMarker(LatLng position) {
    try {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Your Location'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          zIndex: 2, // Higher zIndex to appear above other markers
        ),
      );
      notifyListeners();
    } catch (e) {
      print('Error adding user location marker: $e');
    }
  }

  ///Get all markers
  Set<Marker> get markers => _markers;

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }
}
