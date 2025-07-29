import 'package:cloud_firestore/cloud_firestore.dart';

enum HistoryType {
  search,
  navigation,
  locationView,
}

class HistoryItem {
  final String? id;
  final String title;
  final String? subtitle;
  final HistoryType type;
  final DateTime timestamp;
  final String? locationId;
  final double? latitude;
  final double? longitude;
  final String? category;
  final Map<String, dynamic>? metadata;

  HistoryItem({
    this.id,
    required this.title,
    this.subtitle,
    required this.type,
    required this.timestamp,
    this.locationId,
    this.latitude,
    this.longitude,
    this.category,
    this.metadata,
  });

  factory HistoryItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HistoryItem(
      id: doc.id,
      title: data['title'] ?? '',
      subtitle: data['subtitle'],
      type: HistoryType.values.firstWhere(
        (e) => e.toString() == 'HistoryType.${data['type']}',
        orElse: () => HistoryType.search,
      ),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      locationId: data['locationId'],
      latitude: data['latitude']?.toDouble(),
      longitude: data['longitude']?.toDouble(),
      category: data['category'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'subtitle': subtitle,
      'type': type.toString().split('.').last,
      'timestamp': Timestamp.fromDate(timestamp),
      'locationId': locationId,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'metadata': metadata,
    };
  }

  factory HistoryItem.search({
    required String query,
    String? category,
    int? resultsCount,
  }) {
    return HistoryItem(
      title: query,
      subtitle: category != null ? 'Category: $category' : 
                resultsCount != null ? '$resultsCount results' : null,
      type: HistoryType.search,
      timestamp: DateTime.now(),
      category: category,
      metadata: {
        'resultsCount': resultsCount,
      },
    );
  }

  factory HistoryItem.navigation({
    required String fromLocation,
    required String toLocation,
    String? toLocationId,
    double? toLat,
    double? toLng,
    String? duration,
    String? distance,
  }) {
    return HistoryItem(
      title: toLocation,
      subtitle: 'From $fromLocation',
      type: HistoryType.navigation,
      timestamp: DateTime.now(),
      locationId: toLocationId,
      latitude: toLat,
      longitude: toLng,
      metadata: {
        'fromLocation': fromLocation,
        'duration': duration,
        'distance': distance,
      },
    );
  }

  factory HistoryItem.locationView({
    required String locationName,
    String? locationId,
    double? latitude,
    double? longitude,
    String? category,
  }) {
    return HistoryItem(
      title: locationName,
      subtitle: category,
      type: HistoryType.locationView,
      timestamp: DateTime.now(),
      locationId: locationId,
      latitude: latitude,
      longitude: longitude,
      category: category,
    );
  }
}