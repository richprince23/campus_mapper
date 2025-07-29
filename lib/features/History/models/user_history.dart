import 'package:cloud_firestore/cloud_firestore.dart';

enum HistoryActionType {
  placeAdded,
  journeyCompleted,
  placeVisited,
  placeFavorited,
  searchPerformed,
  routeCalculated,
}

class UserHistory {
  final String? id;
  final String userId;
  final HistoryActionType actionType;
  final Map<String, dynamic> details;
  final DateTime timestamp;
  final Map<String, dynamic>? location;

  UserHistory({
    this.id,
    required this.userId,
    required this.actionType,
    required this.details,
    required this.timestamp,
    this.location,
  });

  factory UserHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserHistory(
      id: doc.id,
      userId: data['user_id'] ?? '',
      actionType: _parseActionType(data['action_type']),
      details: data['details'] ?? {},
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      location: data['location'],
    );
  }

  static HistoryActionType _parseActionType(String? actionTypeString) {
    switch (actionTypeString) {
      case 'place_added':
        return HistoryActionType.placeAdded;
      case 'journey_completed':
        return HistoryActionType.journeyCompleted;
      case 'place_visited':
        return HistoryActionType.placeVisited;
      case 'place_favorited':
        return HistoryActionType.placeFavorited;
      case 'search_performed':
        return HistoryActionType.searchPerformed;
      case 'route_calculated':
        return HistoryActionType.routeCalculated;
      default:
        return HistoryActionType.placeVisited;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'action_type': _actionTypeToString(actionType),
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'location': location,
    };
  }

  static String _actionTypeToString(HistoryActionType actionType) {
    switch (actionType) {
      case HistoryActionType.placeAdded:
        return 'place_added';
      case HistoryActionType.journeyCompleted:
        return 'journey_completed';
      case HistoryActionType.placeVisited:
        return 'place_visited';
      case HistoryActionType.placeFavorited:
        return 'place_favorited';
      case HistoryActionType.searchPerformed:
        return 'search_performed';
      case HistoryActionType.routeCalculated:
        return 'route_calculated';
    }
  }

  // Factory constructors for different action types
  factory UserHistory.placeAdded({
    required String userId,
    required String placeId,
    required String placeName,
    required String category,
    double? latitude,
    double? longitude,
  }) {
    return UserHistory(
      userId: userId,
      actionType: HistoryActionType.placeAdded,
      details: {
        'place_id': placeId,
        'place_name': placeName,
        'metadata': {
          'category': category,
        }
      },
      timestamp: DateTime.now(),
      location: latitude != null && longitude != null
          ? {
              'latitude': latitude,
              'longitude': longitude,
            }
          : null,
    );
  }

  factory UserHistory.journeyCompleted({
    required String userId,
    required String activityId,
    required String fromPlace,
    required String toPlace,
    required double distance,
    required int duration,
    double? latitude,
    double? longitude,
  }) {
    return UserHistory(
      userId: userId,
      actionType: HistoryActionType.journeyCompleted,
      details: {
        'activity_id': activityId,
        'place_name': toPlace,
        'metadata': {
          'from_place': fromPlace,
          'distance': distance,
          'duration': duration,
        }
      },
      timestamp: DateTime.now(),
      location: latitude != null && longitude != null
          ? {
              'latitude': latitude,
              'longitude': longitude,
            }
          : null,
    );
  }

  factory UserHistory.placeVisited({
    required String userId,
    required String placeId,
    required String placeName,
    String? category,
    double? latitude,
    double? longitude,
  }) {
    return UserHistory(
      userId: userId,
      actionType: HistoryActionType.placeVisited,
      details: {
        'place_id': placeId,
        'place_name': placeName,
        'metadata': {
          'category': category,
        }
      },
      timestamp: DateTime.now(),
      location: latitude != null && longitude != null
          ? {
              'latitude': latitude,
              'longitude': longitude,
            }
          : null,
    );
  }

  factory UserHistory.placeFavorited({
    required String userId,
    required String placeId,
    required String placeName,
    String? category,
    double? latitude,
    double? longitude,
  }) {
    return UserHistory(
      userId: userId,
      actionType: HistoryActionType.placeFavorited,
      details: {
        'place_id': placeId,
        'place_name': placeName,
        'metadata': {
          'category': category,
        }
      },
      timestamp: DateTime.now(),
      location: latitude != null && longitude != null
          ? {
              'latitude': latitude,
              'longitude': longitude,
            }
          : null,
    );
  }

  factory UserHistory.searchPerformed({
    required String userId,
    required String searchQuery,
    String? category,
    int? resultsCount,
    double? latitude,
    double? longitude,
  }) {
    return UserHistory(
      userId: userId,
      actionType: HistoryActionType.searchPerformed,
      details: {
        'place_name': searchQuery,
        'metadata': {
          'query': searchQuery,
          'category': category,
          'results_count': resultsCount,
        }
      },
      timestamp: DateTime.now(),
      location: latitude != null && longitude != null
          ? {
              'latitude': latitude,
              'longitude': longitude,
            }
          : null,
    );
  }

  factory UserHistory.routeCalculated({
    required String userId,
    required String fromPlace,
    required String toPlace,
    required double distance,
    required int duration,
    double? latitude,
    double? longitude,
  }) {
    return UserHistory(
      userId: userId,
      actionType: HistoryActionType.routeCalculated,
      details: {
        'place_name': toPlace,
        'metadata': {
          'from_place': fromPlace,
          'distance': distance,
          'duration': duration,
        }
      },
      timestamp: DateTime.now(),
      location: latitude != null && longitude != null
          ? {
              'latitude': latitude,
              'longitude': longitude,
            }
          : null,
    );
  }

  // Helper methods for UI display
  String get displayTitle {
    final placeName = details['place_name'] ?? 'Unknown';
    switch (actionType) {
      case HistoryActionType.placeAdded:
        return 'Added $placeName';
      case HistoryActionType.journeyCompleted:
        return 'Journey to $placeName';
      case HistoryActionType.placeVisited:
        return placeName;
      case HistoryActionType.placeFavorited:
        return 'Favorited $placeName';
      case HistoryActionType.searchPerformed:
        return 'Searched for $placeName';
      case HistoryActionType.routeCalculated:
        return 'Route to $placeName';
    }
  }

  String? get displaySubtitle {
    final metadata = details['metadata'] as Map<String, dynamic>? ?? {};
    switch (actionType) {
      case HistoryActionType.placeAdded:
        return 'Category: ${metadata['category'] ?? 'Unknown'}';
      case HistoryActionType.journeyCompleted:
        final distance = metadata['distance'];
        final duration = metadata['duration'];
        return 'Distance: ${distance?.toStringAsFixed(1)}km, Duration: ${duration}min';
      case HistoryActionType.placeVisited:
        return metadata['category'];
      case HistoryActionType.placeFavorited:
        return metadata['category'];
      case HistoryActionType.searchPerformed:
        final category = metadata['category'];
        final resultsCount = metadata['results_count'];
        if (category != null) return 'Category: $category';
        if (resultsCount != null) return '$resultsCount results';
        return null;
      case HistoryActionType.routeCalculated:
        final fromPlace = metadata['from_place'];
        return fromPlace != null ? 'From $fromPlace' : null;
    }
  }

  // Helper method to get icon for different action types
  String get iconName {
    switch (actionType) {
      case HistoryActionType.placeAdded:
        return 'add_location';
      case HistoryActionType.journeyCompleted:
        return 'route';
      case HistoryActionType.placeVisited:
        return 'location_on';
      case HistoryActionType.placeFavorited:
        return 'favorite';
      case HistoryActionType.searchPerformed:
        return 'search';
      case HistoryActionType.routeCalculated:
        return 'directions';
    }
  }
}