// lib/features/Explore/services/route_service.dart
import 'dart:math' show cos, sqrt, asin;
import 'package:campus_mapper/env.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_routes/google_maps_routes.dart';
import 'package:geolocator/geolocator.dart';

class RouteService {
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
      MapsRoutes route = MapsRoutes();
      DistanceCalculator distanceCalculator = DistanceCalculator();

      List<LatLng> points = [origin, destination];

      // Get the route
      await route.drawRoute(
        points,
        'Route to Destination',
        Colors.blue,
        EnvKeys.mapsKey, // Replace with your API key
        travelMode: TravelModes.walking,
      );

      // Calculate distance in meters
      String distanceInMeters =
          distanceCalculator.calculateRouteDistance(points, decimals: 2) * 1000;

      // Estimate duration (assuming 1.4 m/s average walking speed)
      double distance = double.parse(distanceInMeters.split(' km')[0]);
      int durationInSeconds = (distance / 1.4).round();

      return {
        'polylineCoordinates':
            route.routes.isNotEmpty ? route.routes.first.points : points,
        'distance': distanceInMeters,
        'duration': durationInSeconds,
        'routeObject': route,
      };
    } catch (e) {
      // Fallback to direct distance if API fails
      double distanceInKm = calculateDistance(origin, destination);
      int estimatedTimeInSeconds = (distanceInKm * 1000 / 1.4).round();

      return {
        'polylineCoordinates': [origin, destination],
        'distance': distanceInKm * 1000,
        'duration': estimatedTimeInSeconds,
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
