import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' show log;
import 'dart:math' hide log;

class UserHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _cachedUserId;
  
  Future<String?> get _userId async {
    if (_cachedUserId != null) return _cachedUserId;
    
    // Try to get current authenticated user first
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      _cachedUserId = currentUser.uid;
      log('Using authenticated user ID: $_cachedUserId');
      return _cachedUserId;
    }
    
    // Fall back to device-based ID for guest users
    log('No authenticated user, using device-based user ID');
    
    final prefs = await SharedPreferences.getInstance();
    String? deviceUserId = prefs.getString('device_user_id');
    
    if (deviceUserId == null) {
      // Create a unique device-based user ID
      deviceUserId = 'guest_${DateTime.now().millisecondsSinceEpoch}_${_generateRandomString(8)}';
      await prefs.setString('device_user_id', deviceUserId);
      log('Created new guest user ID: $deviceUserId');
    } else {
      log('Using existing guest user ID: $deviceUserId');
    }
    
    _cachedUserId = deviceUserId;
    return _cachedUserId;
  }
  
  /// Generate a random string for user ID uniqueness
  String _generateRandomString(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    var result = '';
    
    for (int i = 0; i < length; i++) {
      result += chars[random.nextInt(chars.length)];
    }
    
    return result;
  }
  
  /// Reset cached user ID (useful for testing or when switching users)
  void resetUserId() {
    _cachedUserId = null;
  }
  
  /// Get current user ID without caching (for debugging)
  Future<String?> getCurrentUserId() async {
    return await _userId;
  }

  CollectionReference get _historyCollection => 
    _firestore.collection('user_history');

  /// Get user's history with pagination support
  Future<List<UserHistory>> getUserHistory({
    int? limit,
    DocumentSnapshot? lastDocument,
    List<HistoryActionType>? actionTypes,
  }) async {
    final userId = await _userId;
    if (userId == null) return [];

    try {
      Query query = _historyCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true);

      // Filter by action types if provided
      if (actionTypes != null && actionTypes.isNotEmpty) {
        final actionTypeStrings = actionTypes
            .map((type) => UserHistory.actionTypeToString(type))
            .toList();
        query = query.where('action_type', whereIn: actionTypeStrings);
      }

      // Add pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserHistory.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching user history: $e');
      rethrow;
    }
  }

  /// Add new history entry
  Future<void> addHistoryEntry(UserHistory historyEntry) async {
    final userId = await _userId;
    if (userId == null) return;

    try {
      // Check for recent duplicates to avoid spam
      final recentQuery = await _historyCollection
          .where('user_id', isEqualTo: userId)
          .where('action_type', isEqualTo: UserHistory.actionTypeToString(historyEntry.actionType))
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // If similar action within last 2 minutes, skip
      if (recentQuery.docs.isNotEmpty) {
        final lastEntry = UserHistory.fromFirestore(recentQuery.docs.first);
        final timeDifference = DateTime.now().difference(lastEntry.timestamp);
        
        if (timeDifference.inMinutes < 2 && 
            lastEntry.details['place_name'] == historyEntry.details['place_name']) {
          return;
        }
      }

      await _historyCollection.add(historyEntry.toFirestore());
    } catch (e) {
      print('Error adding history entry: $e');
      rethrow;
    }
  }

  /// Delete specific history entry
  Future<void> deleteHistoryEntry(String entryId) async {
    final userId = await _userId;
    if (userId == null) return;

    try {
      // Verify the entry belongs to the current user before deleting
      final doc = await _historyCollection.doc(entryId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['user_id'] == userId) {
          await _historyCollection.doc(entryId).delete();
        } else {
          throw Exception('Unauthorized: Cannot delete another user\'s history');
        }
      }
    } catch (e) {
      print('Error deleting history entry: $e');
      rethrow;
    }
  }

  /// Clear all user history
  Future<void> clearUserHistory() async {
    final userId = await _userId;
    if (userId == null) return;

    try {
      final snapshot = await _historyCollection
          .where('user_id', isEqualTo: userId)
          .get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error clearing user history: $e');
      rethrow;
    }
  }

  /// Get history by specific action type
  Future<List<UserHistory>> getHistoryByActionType(
    HistoryActionType actionType, {
    int? limit,
  }) async {
    final userId = await _userId;
    if (userId == null) return [];

    try {
      Query query = _historyCollection
          .where('user_id', isEqualTo: userId)
          .where('action_type', isEqualTo: UserHistory.actionTypeToString(actionType))
          .orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UserHistory.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching history by action type: $e');
      rethrow;
    }
  }

  /// Get recent searches for quick access
  Future<List<String>> getRecentSearches({int limit = 10}) async {
    final userId = await _userId;
    if (userId == null) return [];

    try {
      final snapshot = await _historyCollection
          .where('user_id', isEqualTo: userId)
          .where('action_type', isEqualTo: 'search_performed')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final searches = <String>{};
      for (final doc in snapshot.docs) {
        final history = UserHistory.fromFirestore(doc);
        final query = history.details['metadata']?['query'] as String?;
        if (query != null && query.isNotEmpty) {
          searches.add(query);
        }
      }

      return searches.toList();
    } catch (e) {
      print('Error getting recent searches: $e');
      return [];
    }
  }

  /// Get recently visited places
  Future<List<Map<String, dynamic>>> getRecentlyVisitedPlaces({int limit = 10}) async {
    final userId = await _userId;
    if (userId == null) return [];

    try {
      final snapshot = await _historyCollection
          .where('user_id', isEqualTo: userId)
          .where('action_type', isEqualTo: 'place_visited')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final history = UserHistory.fromFirestore(doc);
        return {
          'place_id': history.details['place_id'],
          'place_name': history.details['place_name'],
          'category': history.details['metadata']?['category'],
          'last_visited': history.timestamp,
          'location': history.location,
        };
      }).toList();
    } catch (e) {
      print('Error getting recently visited places: $e');
      return [];
    }
  }

  /// Get history statistics
  Future<Map<String, int>> getHistoryStats() async {
    final userId = await _userId;
    if (userId == null) {
      return {
        'total_entries': 0,
        'places_visited': 0,
        'searches_performed': 0,
        'journeys_completed': 0,
        'places_favorited': 0,
        'places_added': 0,
        'routes_calculated': 0,
      };
    }

    try {
      final snapshot = await _historyCollection
          .where('user_id', isEqualTo: userId)
          .get();

      final stats = <String, int>{
        'total_entries': snapshot.docs.length,
        'places_visited': 0,
        'searches_performed': 0,
        'journeys_completed': 0,
        'places_favorited': 0,
        'places_added': 0,
        'routes_calculated': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final actionType = data['action_type'] as String?;
        
        switch (actionType) {
          case 'place_visited':
            stats['places_visited'] = stats['places_visited']! + 1;
            break;
          case 'search_performed':
            stats['searches_performed'] = stats['searches_performed']! + 1;
            break;
          case 'journey_completed':
            stats['journeys_completed'] = stats['journeys_completed']! + 1;
            break;
          case 'place_favorited':
            stats['places_favorited'] = stats['places_favorited']! + 1;
            break;
          case 'place_added':
            stats['places_added'] = stats['places_added']! + 1;
            break;
          case 'route_calculated':
            stats['routes_calculated'] = stats['routes_calculated']! + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting history stats: $e');
      return {
        'total_entries': 0,
        'places_visited': 0,
        'searches_performed': 0,
        'journeys_completed': 0,
        'places_favorited': 0,
        'places_added': 0,
        'routes_calculated': 0,
      };
    }
  }

  /// Search history entries
  Future<List<UserHistory>> searchHistory(String searchTerm) async {
    final userId = await _userId;
    if (userId == null || searchTerm.isEmpty) return [];

    try {
      final snapshot = await _historyCollection
          .where('user_id', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      final results = <UserHistory>[];
      final lowerSearchTerm = searchTerm.toLowerCase();

      for (final doc in snapshot.docs) {
        final history = UserHistory.fromFirestore(doc);
        
        if (_historyItemMatchesSearch(history, lowerSearchTerm)) {
          results.add(history);
        }
      }

      return results;
    } catch (e) {
      log('Error searching history: $e');
      return [];
    }
  }
  
  /// Comprehensive search function for history items
  bool _historyItemMatchesSearch(UserHistory item, String lowerSearchTerm) {
    // Search in place name
    final placeName = item.details['place_name']?.toString().toLowerCase() ?? '';
    if (placeName.contains(lowerSearchTerm)) {
      return true;
    }
    
    // Search in category
    final category = item.details['metadata']?['category']?.toString().toLowerCase() ?? '';
    if (category.contains(lowerSearchTerm)) {
      return true;
    }
    
    // Search in display title
    if (item.displayTitle.toLowerCase().contains(lowerSearchTerm)) {
      return true;
    }
    
    // Search in display subtitle
    if (item.displaySubtitle != null && 
        item.displaySubtitle!.toLowerCase().contains(lowerSearchTerm)) {
      return true;
    }
    
    // Search in search query (for search-type items)
    if (item.actionType == HistoryActionType.searchPerformed) {
      final searchedQuery = item.details['metadata']?['query']?.toString().toLowerCase() ?? '';
      if (searchedQuery.contains(lowerSearchTerm)) {
        return true;
      }
    }
    
    // Search in route details (for journey/route items)
    if (item.actionType == HistoryActionType.journeyCompleted || 
        item.actionType == HistoryActionType.routeCalculated) {
      final fromPlace = item.details['metadata']?['from_place']?.toString().toLowerCase() ?? '';
      if (fromPlace.contains(lowerSearchTerm)) {
        return true;
      }
    }
    
    return false;
  }
}