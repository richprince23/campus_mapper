class Location {
  final int? id;
  final String? name;
  final Map<String, dynamic> location;
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
      // If location is already a Map
      final Map<dynamic, dynamic> rawMap = json['location'] as Map;
      locationMap = {
        'latitude': rawMap['latitude']?.toDouble() ?? 0.0,
        'longitude': rawMap['longitude']?.toDouble() ?? 0.0,
      };
    } else {
      // Handle case where location might be stored differently
      locationMap = {
        'latitude': 0.0,
        'longitude': 0.0,
      };
    }

    return Location(
      id: json['id'],
      name: json['name'],
      location: locationMap,
      category: json['category'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location, // Storing as a Map
      'category': category,
      'description': description,
    };
  }
}
