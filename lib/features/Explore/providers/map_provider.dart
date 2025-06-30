import 'dart:developer' show log;

import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapProvider extends ChangeNotifier {
  final Set<Marker> _markers = {};
  // current user location
  LatLng? _currentUserLocation;

  LatLng? get currentUserLocation => _currentUserLocation;
  // user location marker
  Marker? _userLocationMarker;

  MapProvider() {
    // Initialize with user location marker if needed
    _userLocationMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(0, 0), // Default position, will be updated later
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      zIndex: 2, // Higher zIndex to appear above other markers
    );
  }

  Marker? get userLocationMarker => _userLocationMarker;

  /// Set current user location and update the user location marker
  set currentUserLocation(LatLng? position) {
    _currentUserLocation = position;
    if (position != null) {
      _userLocationMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: position,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        zIndex: 2, // Higher zIndex to appear above other markers
      );
    } else {
      _userLocationMarker = null; // Clear marker if position is null
    }
    notifyListeners();
  }

  /// Get custom icon based on category
  Future<BitmapDescriptor> getCustomIcon(String category) async {
    return await BitmapDescriptor.asset(
      const ImageConfiguration(size: Size(24, 24)), // Set size
      _getCategoryMarker(category), // Path to the asset
    );
  }

  /// Get custom icon color based on category
  Future<BitmapDescriptor> getCustomIconColor(String category) async {
    try {
      return BitmapDescriptor.defaultMarkerWithHue(_getCategoryHue(category));
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

  void addMarker(Location data) async {
    try {
      _markers.add(
        Marker(
          markerId: MarkerId(data.id?.toString() ?? DateTime.now().toString()),
          position: LatLng(
            data.location['latitude']!,
            data.location['longitude']!,
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
