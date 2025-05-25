// lib/features/Explore/services/route_service.dart
import 'dart:math' show cos, sqrt, asin;
import 'package:campus_mapper/env.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/google_maps_routes.dart';
import 'package:geolocator/geolocator.dart';

class RouteService {
  static const String _apiKey = EnvKeys.mapsKey; // Replace with your API key

  // Get the user's current location
  static Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Fetch route between two points using google_maps_routes
  static Future<Map<String, dynamic>> getRoute(
      LatLng origin, LatLng destination) async {
    try {
      // Use direct distance calculation as primary method
      double distanceInKm = calculateDistance(origin, destination);
      double distanceInMeters = distanceInKm * 1000;

      // Estimate duration based on average walking speed (1.4 m/s = 5 km/h)
      int durationInSeconds = (distanceInMeters / 1.4).round();

      // Create a simple route with origin and destination
      List<LatLng> routePoints = [origin, destination];

      print('Direct distance calculation: ${distanceInKm} km');
      print('Distance in meters: ${distanceInMeters}');

      // Try to use google_maps_routes for better path if API key is available
      if (_apiKey != "YOUR_GOOGLE_MAPS_API_KEY") {
        try {
          MapsRoutes route = MapsRoutes();
          await route.drawRoute(
            [origin, destination],
            'Route to Destination',
            Colors.blue,
            _apiKey,
            travelMode: TravelModes.walking,
          );

          if (route.routes.isNotEmpty && route.routes.isNotEmpty) {
            routePoints = route.routes.first.points;

            // Recalculate distance based on actual route points
            double totalDistance = 0.0;
            for (int i = 0; i < routePoints.length - 1; i++) {
              totalDistance +=
                  calculateDistance(routePoints[i], routePoints[i + 1]);
            }

            distanceInMeters = totalDistance * 1000;
            durationInSeconds = (distanceInMeters / 1.4).round();

            print('Google Maps route distance: ${totalDistance} km');
          }
        } catch (e) {
          print('Google Maps Routes API failed, using direct route: $e');
        }
      }

      // Ensure we return clean numeric values
      return {
        'polylineCoordinates': routePoints,
        'distance': distanceInMeters, // Always return as double (meters)
        'duration': durationInSeconds, // Always return as int (seconds)
      };
    } catch (e) {
      print('Route calculation error: $e');
      // Final fallback
      double distanceInKm = calculateDistance(origin, destination);
      double distanceInMeters = distanceInKm * 1000;
      int estimatedTimeInSeconds = (distanceInMeters / 1.4).round();

      return {
        'polylineCoordinates': [origin, destination],
        'distance': distanceInMeters, // Ensure it's a double
        'duration': estimatedTimeInSeconds, // Ensure it's an int
        'isEstimate': true,
      };
    }
  }

  // Calculate burnt calories based on walking distance
  static double calculateCalories(double distanceInMeters) {
    // Convert meters to kilometers
    final distanceInKm = distanceInMeters / 1000;

    // Calculate calories (65 calories per km)
    return distanceInKm * 65;
  }

  // Calculate distance using Haversine formula
  static double calculateDistance(LatLng start, LatLng end) {
    const p = 0.017453292519943295; // Math.PI / 180
    const c = cos;
    final a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;

    // Return distance in kilometers
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
