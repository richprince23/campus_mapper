import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'dart:developer' show log;

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Add a new location to Firestore
  Future<String?> addLocation({
    required String name,
    required String category,
    required double latitude,
    required double longitude,
    String? description,
    UserHistoryProvider? historyProvider,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to add locations');
      }

      // Get user's university ID
      String? universityId;
      try {
        final userDoc = await _firestore.collection('user_profiles').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null) {
          universityId = userDoc.data()!['university_id'];
        }
      } catch (e) {
        log('Could not fetch user university: $e');
      }

      // Create location data
      final locationData = {
        'name': name,
        'name_lower': name.toLowerCase(), // For case-insensitive search
        'category': category,
        'description': description ?? '',
        'latitude': latitude,
        'longitude': longitude,
        'location': {
          'latitude': latitude,
          'longitude': longitude,
        },
        'university_id': universityId, // Auto-scope to user's university
        'added_by': user.uid,
        'added_by_email': user.email ?? '',
        'created_at': FieldValue.serverTimestamp(),
        'status': 'pending', // Can be 'pending', 'approved', 'rejected'
      };

      // Add to Firestore
      final docRef = await _firestore
          .collection('locations')
          .add(locationData);

      log('Location added successfully with ID: ${docRef.id}');

      // Add to user history if provider is available
      if (historyProvider != null) {
        final historyItem = UserHistory.placeAdded(
          userId: user.uid,
          placeId: docRef.id,
          placeName: name,
          category: category,
          latitude: latitude,
          longitude: longitude,
        );
        
        await historyProvider.addHistoryItem(historyItem);
        log('Added location to user history');
      }

      return docRef.id;
    } catch (e) {
      log('Error adding location: $e');
      rethrow;
    }
  }

  /// Get user's added locations
  Future<List<Map<String, dynamic>>> getUserAddedLocations() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final snapshot = await _firestore
          .collection('locations')
          .where('added_by', isEqualTo: user.uid)
          .orderBy('created_at', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      log('Error getting user locations: $e');
      return [];
    }
  }

  /// Update location status (for admin use)
  Future<void> updateLocationStatus(String locationId, String status) async {
    try {
      await _firestore
          .collection('locations')
          .doc(locationId)
          .update({
        'status': status,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      log('Location status updated to: $status');
    } catch (e) {
      log('Error updating location status: $e');
      rethrow;
    }
  }
}