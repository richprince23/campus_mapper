import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String? id;
  final String? name;
  final Map<String, double> location;
  final String category;
  final String? description;

  Location({
    this.id,
    this.name,
    required this.location,
    required this.category,
    this.description,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    Map<String, double> locationMap;

    if (json['location'] is Map) {
      final Map<dynamic, dynamic> rawMap = json['location'] as Map;
      locationMap = {
        'latitude': rawMap['latitude']?.toDouble() ?? 0.0,
        'longitude': rawMap['longitude']?.toDouble() ?? 0.0,
      };
    } else if (json['location'] is GeoPoint) {
      final GeoPoint geoPoint = json['location'] as GeoPoint;
      locationMap = {
        'latitude': geoPoint.latitude,
        'longitude': geoPoint.longitude,
      };
    } else {
      locationMap = {
        'latitude': 0.0,
        'longitude': 0.0,
      };
    }

    return Location(
      id: json['id'],
      name: json['name'],
      location: locationMap,
      category: json['category'] ?? '',
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'category': category,
      'description': description,
    };
  }

  factory Location.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>?;
      
      if (data == null) {
        return Location(
          id: doc.id,
          name: 'Unknown',
          location: {'latitude': 0.0, 'longitude': 0.0},
          category: 'Unknown',
          description: null,
        );
      }

      Map<String, double> locationMap;

      if (data['location'] is GeoPoint) {
        final GeoPoint geoPoint = data['location'] as GeoPoint;
        locationMap = {
          'latitude': geoPoint.latitude,
          'longitude': geoPoint.longitude,
        };
      } else if (data['location'] is Map) {
        final Map<dynamic, dynamic> rawMap = data['location'] as Map;
        locationMap = {
          'latitude': (rawMap['latitude'] ?? 0.0).toDouble(),
          'longitude': (rawMap['longitude'] ?? 0.0).toDouble(),
        };
      } else {
        locationMap = {
          'latitude': 0.0,
          'longitude': 0.0,
        };
      }

      return Location(
        id: doc.id,
        name: data['name']?.toString(),
        location: locationMap,
        category: data['category']?.toString() ?? '',
        description: data['description']?.toString(),
      );
    } catch (e) {
      print('Error parsing Firestore document ${doc.id}: $e');
      return Location(
        id: doc.id,
        name: 'Error',
        location: {'latitude': 0.0, 'longitude': 0.0},
        category: 'Error',
        description: 'Failed to parse document',
      );
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'location': GeoPoint(location['latitude']!, location['longitude']!),
      'category': category,
      'description': description,
    };
  }
}