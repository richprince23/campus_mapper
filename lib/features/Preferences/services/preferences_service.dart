import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:campus_mapper/features/Preferences/models/user_preferences.dart';
import 'dart:developer' show log;

class PreferencesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _prefsKey = 'user_preferences';

  /// Load user preferences from Firestore with fallback to local cache
  Future<UserPreferences> loadPreferences(String userId) async {
    try {
      // Try to load from Firestore first
      final doc = await _firestore
          .collection('user_preferences')
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        final preferences = UserPreferences.fromJson(doc.data()!);
        
        // Cache the preferences locally
        await _cachePreferences(preferences);
        
        log('Preferences loaded from Firestore for user: $userId');
        return preferences;
      }
    } catch (e) {
      log('Error loading preferences from Firestore: $e');
    }

    // Fallback to cached preferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('${_prefsKey}_$userId');
      
      if (cachedData != null) {
        log('Using cached preferences for user: $userId');
        return UserPreferences.fromJsonString(cachedData);
      }
    } catch (e) {
      log('Error loading cached preferences: $e');
    }

    // Return default preferences if nothing found
    log('Creating default preferences for user: $userId');
    return UserPreferences.defaultFor(userId);
  }

  /// Save preferences to Firestore and local cache
  Future<void> savePreferences(UserPreferences preferences) async {
    try {
      // Save to Firestore
      await _firestore
          .collection('user_preferences')
          .doc(preferences.userId)
          .set(preferences.toJson(), SetOptions(merge: true));

      // Cache locally
      await _cachePreferences(preferences);
      
      log('Preferences saved for user: ${preferences.userId}');
    } catch (e) {
      log('Error saving preferences: $e');
      
      // If Firestore fails, at least save locally
      try {
        await _cachePreferences(preferences);
        log('Preferences cached locally as fallback');
      } catch (cacheError) {
        log('Error caching preferences: $cacheError');
        rethrow;
      }
    }
  }

  /// Update specific preference field
  Future<void> updatePreference(String userId, String field, dynamic value) async {
    try {
      final currentPrefs = await loadPreferences(userId);
      UserPreferences updatedPrefs;

      switch (field) {
        case 'show_name_on_leaderboard':
          updatedPrefs = currentPrefs.copyWith(showNameOnLeaderboard: value as bool);
          break;
        case 'theme':
          updatedPrefs = currentPrefs.copyWith(theme: value as String);
          break;
        case 'notifications_enabled':
          updatedPrefs = currentPrefs.copyWith(notificationsEnabled: value as bool);
          break;
        case 'location_sharing_enabled':
          updatedPrefs = currentPrefs.copyWith(locationSharingEnabled: value as bool);
          break;
        case 'offline_maps_enabled':
          updatedPrefs = currentPrefs.copyWith(offlineMapsEnabled: value as bool);
          break;
        case 'map_type':
          updatedPrefs = currentPrefs.copyWith(mapType: value as String);
          break;
        case 'auto_night_mode':
          updatedPrefs = currentPrefs.copyWith(autoNightMode: value as bool);
          break;
        case 'history_retention_days':
          updatedPrefs = currentPrefs.copyWith(historyRetentionDays: value as int);
          break;
        case 'analytics_enabled':
          updatedPrefs = currentPrefs.copyWith(analyticsEnabled: value as bool);
          break;
        default:
          throw ArgumentError('Unknown preference field: $field');
      }

      await savePreferences(updatedPrefs);
    } catch (e) {
      log('Error updating preference $field: $e');
      rethrow;
    }
  }

  /// Cache preferences locally
  Future<void> _cachePreferences(UserPreferences preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '${_prefsKey}_${preferences.userId}',
        preferences.toJsonString(),
      );
    } catch (e) {
      log('Error caching preferences: $e');
      rethrow;
    }
  }

  /// Clear cached preferences
  Future<void> clearCachedPreferences(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${_prefsKey}_$userId');
      log('Cleared cached preferences for user: $userId');
    } catch (e) {
      log('Error clearing cached preferences: $e');
    }
  }

  /// Delete all preferences for a user (used when deleting account)
  Future<void> deleteUserPreferences(String userId) async {
    try {
      // Delete from Firestore
      await _firestore
          .collection('user_preferences')
          .doc(userId)
          .delete();

      // Clear local cache
      await clearCachedPreferences(userId);
      
      log('Deleted all preferences for user: $userId');
    } catch (e) {
      log('Error deleting user preferences: $e');
      rethrow;
    }
  }

  /// Migrate preferences from device ID to user ID (when user logs in)
  Future<void> migratePreferences(String deviceId, String userId) async {
    try {
      final devicePrefs = await loadPreferences(deviceId);
      final migratedPrefs = devicePrefs.copyWith(
        userId: userId,
        updatedAt: DateTime.now(),
      );
      
      await savePreferences(migratedPrefs);
      await clearCachedPreferences(deviceId);
      
      log('Migrated preferences from device $deviceId to user $userId');
    } catch (e) {
      log('Error migrating preferences: $e');
      // Don't rethrow - this is not critical
    }
  }
}