import 'package:flutter/material.dart';
import 'package:campus_mapper/features/Preferences/models/user_preferences.dart';
import 'package:campus_mapper/features/Preferences/services/preferences_service.dart';
import 'dart:developer' show log;

class PreferencesProvider extends ChangeNotifier {
  final PreferencesService _preferencesService = PreferencesService();
  
  UserPreferences? _preferences;
  bool _isLoading = false;
  String? _errorMessage;
  
  // Getters
  UserPreferences? get preferences => _preferences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  // Theme-specific getters
  ThemeMode get themeMode {
    if (_preferences == null) return ThemeMode.system;
    
    switch (_preferences!.theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }
  
  bool get isDarkMode {
    return themeMode == ThemeMode.dark;
  }
  
  bool get isLightMode {
    return themeMode == ThemeMode.light;
  }
  
  bool get isSystemMode {
    return themeMode == ThemeMode.system;
  }

  /// Initialize preferences for a user
  Future<void> initializePreferences(String userId) async {
    _setLoading(true);
    _clearError();
    
    try {
      _preferences = await _preferencesService.loadPreferences(userId);
      log('Preferences initialized for user: $userId');
    } catch (e) {
      _setError('Failed to load preferences: ${e.toString()}');
      log('Error initializing preferences: $e');
      // Set default preferences as fallback
      _preferences = UserPreferences.defaultFor(userId);
    } finally {
      _setLoading(false);
    }
  }

  /// Update theme preference
  Future<void> setTheme(String theme) async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      
      // Update locally first for immediate UI response
      _preferences = _preferences!.copyWith(theme: theme);
      notifyListeners();
      
      // Save to backend
      await _preferencesService.updatePreference(
        _preferences!.userId,
        'theme',
        theme,
      );
      
      log('Theme updated to: $theme');
    } catch (e) {
      _setError('Failed to update theme: ${e.toString()}');
      log('Error updating theme: $e');
    }
  }

  /// Toggle leaderboard name display
  Future<void> setShowNameOnLeaderboard(bool show) async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      
      // Update locally first
      _preferences = _preferences!.copyWith(showNameOnLeaderboard: show);
      notifyListeners();
      
      // Save to backend
      await _preferencesService.updatePreference(
        _preferences!.userId,
        'show_name_on_leaderboard',
        show,
      );
      
      log('Leaderboard name display updated to: $show');
    } catch (e) {
      _setError('Failed to update leaderboard setting: ${e.toString()}');
      log('Error updating leaderboard setting: $e');
    }
  }

  /// Update notifications preference
  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      
      _preferences = _preferences!.copyWith(notificationsEnabled: enabled);
      notifyListeners();
      
      await _preferencesService.updatePreference(
        _preferences!.userId,
        'notifications_enabled',
        enabled,
      );
      
      log('Notifications updated to: $enabled');
    } catch (e) {
      _setError('Failed to update notifications: ${e.toString()}');
      log('Error updating notifications: $e');
    }
  }

  /// Update location sharing preference
  Future<void> setLocationSharingEnabled(bool enabled) async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      
      _preferences = _preferences!.copyWith(locationSharingEnabled: enabled);
      notifyListeners();
      
      await _preferencesService.updatePreference(
        _preferences!.userId,
        'location_sharing_enabled',
        enabled,
      );
      
      log('Location sharing updated to: $enabled');
    } catch (e) {
      _setError('Failed to update location sharing: ${e.toString()}');
      log('Error updating location sharing: $e');
    }
  }

  /// Update offline maps preference
  Future<void> setOfflineMapsEnabled(bool enabled) async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      
      _preferences = _preferences!.copyWith(offlineMapsEnabled: enabled);
      notifyListeners();
      
      await _preferencesService.updatePreference(
        _preferences!.userId,
        'offline_maps_enabled',
        enabled,
      );
      
      log('Offline maps updated to: $enabled');
    } catch (e) {
      _setError('Failed to update offline maps: ${e.toString()}');
      log('Error updating offline maps: $e');
    }
  }

  /// Update map type preference
  Future<void> setMapType(String mapType) async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      
      _preferences = _preferences!.copyWith(mapType: mapType);
      notifyListeners();
      
      await _preferencesService.updatePreference(
        _preferences!.userId,
        'map_type',
        mapType,
      );
      
      log('Map type updated to: $mapType');
    } catch (e) {
      _setError('Failed to update map type: ${e.toString()}');
      log('Error updating map type: $e');
    }
  }

  /// Update auto night mode preference
  Future<void> setAutoNightMode(bool enabled) async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      
      _preferences = _preferences!.copyWith(autoNightMode: enabled);
      notifyListeners();
      
      await _preferencesService.updatePreference(
        _preferences!.userId,
        'auto_night_mode',
        enabled,
      );
      
      log('Auto night mode updated to: $enabled');
    } catch (e) {
      _setError('Failed to update auto night mode: ${e.toString()}');
      log('Error updating auto night mode: $e');
    }
  }

  /// Update analytics preference
  Future<void> setAnalyticsEnabled(bool enabled) async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      
      _preferences = _preferences!.copyWith(analyticsEnabled: enabled);
      notifyListeners();
      
      await _preferencesService.updatePreference(
        _preferences!.userId,
        'analytics_enabled',
        enabled,
      );
      
      log('Analytics updated to: $enabled');
    } catch (e) {
      _setError('Failed to update analytics: ${e.toString()}');
      log('Error updating analytics: $e');
    }
  }

  /// Reset all preferences to default
  Future<void> resetToDefaults() async {
    if (_preferences == null) return;
    
    try {
      _clearError();
      _setLoading(true);
      
      final defaultPrefs = UserPreferences.defaultFor(_preferences!.userId);
      await _preferencesService.savePreferences(defaultPrefs);
      
      _preferences = defaultPrefs;
      
      log('Preferences reset to defaults');
    } catch (e) {
      _setError('Failed to reset preferences: ${e.toString()}');
      log('Error resetting preferences: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all preferences (used when user logs out)
  void clearPreferences() {
    _preferences = null;
    _clearError();
    notifyListeners();
    log('Preferences cleared');
  }

  /// Delete user preferences (used when account is deleted)
  Future<void> deleteUserPreferences() async {
    if (_preferences == null) return;
    
    try {
      await _preferencesService.deleteUserPreferences(_preferences!.userId);
      _preferences = null;
      notifyListeners();
      log('User preferences deleted');
    } catch (e) {
      _setError('Failed to delete preferences: ${e.toString()}');
      log('Error deleting preferences: $e');
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}