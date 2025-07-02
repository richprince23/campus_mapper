// // lib/features/Explore/services/route_service.dart
// import 'dart:math' show cos, sqrt, asin;
// import 'package:campus_mapper/env.dart';
// import 'package:flutter/material.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:google_maps_routes/google_maps_routes.dart';
// import 'package:geolocator/geolocator.dart';

// class RouteService {
//   static const String _apiKey = EnvKeys.mapsKey; // Replace with your API key

//   // Get the user's current location
//   static Future<Position> getCurrentLocation() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       throw Exception('Location services are disabled.');
//     }

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         throw Exception('Location permissions are denied.');
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       throw Exception('Location permissions are permanently denied.');
//     }

//     return await Geolocator.getCurrentPosition();
//   }

//   // Fetch route between two points using google_maps_routes
//   static Future<Map<String, dynamic>> getRoute(
//       LatLng origin, LatLng destination) async {
//     try {
//       // Use direct distance calculation as primary method
//       double distanceInKm = calculateDistance(origin, destination);
//       double distanceInMeters = distanceInKm * 1000;

//       // Estimate duration based on average walking speed (1.4 m/s = 5 km/h)
//       int durationInSeconds = (distanceInMeters / 1.4).round();

//       // Create a simple route with origin and destination
//       List<LatLng> routePoints = [origin, destination];

//       print('Direct distance calculation: ${distanceInKm} km');
//       print('Distance in meters: ${distanceInMeters}');

//       // Try to use google_maps_routes for better path if API key is available
//       if (_apiKey != "YOUR_GOOGLE_MAPS_API_KEY") {
//         try {
//           MapsRoutes route = MapsRoutes();
//           await route.drawRoute(
//             [origin, destination],
//             'Route to Destination',
//             Colors.blue,
//             _apiKey,
//             travelMode: TravelModes.walking,
//           );

//           if (route.routes.isNotEmpty && route.routes.isNotEmpty) {
//             routePoints = route.routes.first.points;

//             // Recalculate distance based on actual route points
//             double totalDistance = 0.0;
//             for (int i = 0; i < routePoints.length - 1; i++) {
//               totalDistance +=
//                   calculateDistance(routePoints[i], routePoints[i + 1]);
//             }

//             distanceInMeters = totalDistance * 1000;
//             durationInSeconds = (distanceInMeters / 1.4).round();

//             print('Google Maps route distance: ${totalDistance} km');
//           }
//         } catch (e) {
//           print('Google Maps Routes API failed, using direct route: $e');
//         }
//       }

//       // Ensure we return clean numeric values
//       return {
//         'polylineCoordinates': routePoints,
//         'distance': distanceInMeters, // Always return as double (meters)
//         'duration': durationInSeconds, // Always return as int (seconds)
//       };
//     } catch (e) {
//       print('Route calculation error: $e');
//       // Final fallback
//       double distanceInKm = calculateDistance(origin, destination);
//       double distanceInMeters = distanceInKm * 1000;
//       int estimatedTimeInSeconds = (distanceInMeters / 1.4).round();

//       return {
//         'polylineCoordinates': [origin, destination],
//         'distance': distanceInMeters, // Ensure it's a double
//         'duration': estimatedTimeInSeconds, // Ensure it's an int
//         'isEstimate': true,
//       };
//     }
//   }

//   // Calculate burnt calories based on walking distance
//   static double calculateCalories(double distanceInMeters) {
//     // Convert meters to kilometers
//     final distanceInKm = distanceInMeters / 1000;

//     // Calculate calories (65 calories per km)
//     return distanceInKm * 65;
//   }

//   // Calculate distance using Haversine formula
//   static double calculateDistance(LatLng start, LatLng end) {
//     const p = 0.017453292519943295; // Math.PI / 180
//     const c = cos;
//     final a = 0.5 -
//         c((end.latitude - start.latitude) * p) / 2 +
//         c(start.latitude * p) *
//             c(end.latitude * p) *
//             (1 - c((end.longitude - start.longitude) * p)) /
//             2;

//     // Return distance in kilometers
//     return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
//   }
// }

// Debug and fix route service

import 'dart:math' show cos, sqrt, asin;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:campus_mapper/env.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteService {
  static const String _apiKey = EnvKeys.mapsKey; // Replace with your API key

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

  static Future<Map<String, dynamic>> getRoute(
      LatLng origin, LatLng destination) async {
    print('=== ROUTE SERVICE DEBUG ===');
    print('Origin: ${origin.latitude}, ${origin.longitude}');
    print('Destination: ${destination.latitude}, ${destination.longitude}');

    try {
      // Always use fallback for now to test
      // print('Using fallback route calculation');
      // return _getDirectRoute(origin, destination);

      // Uncomment when API key is available

      if (_apiKey == "YOUR_GOOGLE_MAPS_API_KEY") {
        print('No API key, using direct route');
        return _getDirectRoute(origin, destination);
      }

      print('Using Google Directions API');
      final url =
          Uri.parse('https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${origin.latitude},${origin.longitude}'
              '&destination=${destination.latitude},${destination.longitude}'
              '&mode=walking'
              '&key=$_apiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          final polylinePoints =
              _decodePolyline(route['overview_polyline']['points']);
          final distanceInMeters = leg['distance']['value'].toDouble();
          final durationInSeconds = leg['duration']['value'];

          print('API route: ${distanceInMeters}m, ${durationInSeconds}s');

          return {
            'polylineCoordinates': polylinePoints,
            'distance': distanceInMeters,
            'duration': durationInSeconds,
          };
        } else {
          print('API returned: ${data['status']}');
        }
      } else {
        print('HTTP error: ${response.statusCode}');
      }

      return _getDirectRoute(origin, destination);
    } catch (e) {
      print('Route error: $e');
      return _getDirectRoute(origin, destination);
    }
  }

  static Map<String, dynamic> _getDirectRoute(
      LatLng origin, LatLng destination) {
    double distanceInKm = calculateDistance(origin, destination);
    double distanceInMeters = distanceInKm * 1000;
    int durationInSeconds = (distanceInMeters / 1.4).round();

    print('Direct route: ${distanceInMeters}m, ${durationInSeconds}s');

    return {
      'polylineCoordinates': [origin, destination],
      'distance': distanceInMeters,
      'duration': durationInSeconds,
      'isEstimate': true,
    };
  }

  static List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polylineCoordinates = [];
    int index = 0;
    int len = encoded.length;
    int lat = 0;
    int lng = 0;

    while (index < len) {
      int b;
      int shift = 0;
      int result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      polylineCoordinates.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return polylineCoordinates;
  }

  static double calculateCalories(double distanceInMeters) {
    final distanceInKm = distanceInMeters / 1000;
    return distanceInKm * 65;
  }

  static double calculateDistance(LatLng start, LatLng end) {
    const p = 0.017453292519943295;
    const c = cos;
    final a = 0.5 -
        c((end.latitude - start.latitude) * p) / 2 +
        c(start.latitude * p) *
            c(end.latitude * p) *
            (1 - c((end.longitude - start.longitude) * p)) /
            2;

    return 12742 * asin(sqrt(a));
  }
}
