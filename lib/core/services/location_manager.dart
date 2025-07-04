import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationManager {
  static final LocationManager _instance = LocationManager._internal();
  factory LocationManager() => _instance;
  LocationManager._internal();

  static bool _isRequestingPermission = false;
  static bool _isGettingLocation = false;
  static Position? _lastKnownPosition;
  static DateTime? _lastLocationUpdate;
  static const int _locationCacheTimeoutMinutes = 5;

  static Future<Position?> getCurrentLocation({
    bool useCache = true,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Return cached location if available and recent
    if (useCache && _lastKnownPosition != null && _lastLocationUpdate != null) {
      final cacheAge = DateTime.now().difference(_lastLocationUpdate!);
      if (cacheAge.inMinutes < _locationCacheTimeoutMinutes) {
        return _lastKnownPosition;
      }
    }

    // Prevent multiple simultaneous location requests
    if (_isGettingLocation) {
      // Wait for the ongoing request to complete
      for (int i = 0; i < 60; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_isGettingLocation && _lastKnownPosition != null) {
          return _lastKnownPosition;
        }
      }
      throw Exception('Location request timeout - another request in progress');
    }

    _isGettingLocation = true;

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Handle permissions with singleton pattern
      final hasPermission = await _ensureLocationPermission();
      if (!hasPermission) {
        throw Exception('Location permission denied');
      }

      // Get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(timeout);

      // Update cache
      _lastKnownPosition = position;
      _lastLocationUpdate = DateTime.now();

      return position;
    } catch (e) {
      print('Error getting location: $e');
      rethrow;
    } finally {
      _isGettingLocation = false;
    }
  }

  static Future<bool> _ensureLocationPermission() async {
    // Prevent multiple permission requests
    if (_isRequestingPermission) {
      // Wait for ongoing permission request
      for (int i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (!_isRequestingPermission) {
          break;
        }
      }
      // Check permission again after waiting
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    }

    _isRequestingPermission = true;

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error handling location permission: $e');
      return false;
    } finally {
      _isRequestingPermission = false;
    }
  }

  static Future<bool> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always || 
             permission == LocationPermission.whileInUse;
    } catch (e) {
      print('Error checking location permission: $e');
      return false;
    }
  }

  static Future<bool> isLocationServiceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      print('Error checking location service: $e');
      return false;
    }
  }

  static Position? get lastKnownPosition => _lastKnownPosition;
  
  static LatLng? get lastKnownLatLng => _lastKnownPosition != null
      ? LatLng(_lastKnownPosition!.latitude, _lastKnownPosition!.longitude)
      : null;

  static void clearCache() {
    _lastKnownPosition = null;
    _lastLocationUpdate = null;
  }

  static bool get isRequestingPermission => _isRequestingPermission;
  static bool get isGettingLocation => _isGettingLocation;
}