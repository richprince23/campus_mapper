import 'package:cloud_firestore/cloud_firestore.dart';

class Location {
  final String? id;
  final String? name;
  final GeoPoint location;
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
    return Location(
      id: json['id'],
      name: json['name'],
      location: json['location'] is GeoPoint
          ? json['location'] as GeoPoint // If it's already a GeoPoint
          : GeoPoint(
              json['location']['latitude']?.toDouble() ?? 0.0,
              json['location']['longitude']?.toDouble() ?? 0.0,
            ),
      category: json['category'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'category': category,
      'description': description,
    };
  }
}
