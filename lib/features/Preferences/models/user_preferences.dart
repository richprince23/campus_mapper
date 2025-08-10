import 'dart:convert';

class UserPreferences {
  final String userId;
  final bool showNameOnLeaderboard;
  final String theme; // 'light', 'dark', 'system'
  final bool notificationsEnabled;
  final bool locationSharingEnabled;
  final bool offlineMapsEnabled;
  final String mapType; // 'normal', 'satellite', 'hybrid', 'terrain'
  final bool autoNightMode;
  final int historyRetentionDays;
  final bool analyticsEnabled;
  final DateTime updatedAt;

  const UserPreferences({
    required this.userId,
    this.showNameOnLeaderboard = true,
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.locationSharingEnabled = true,
    this.offlineMapsEnabled = false,
    this.mapType = 'normal',
    this.autoNightMode = true,
    this.historyRetentionDays = 365,
    this.analyticsEnabled = true,
    required this.updatedAt,
  });

  // Create default preferences for a user
  factory UserPreferences.defaultFor(String userId) {
    return UserPreferences(
      userId: userId,
      updatedAt: DateTime.now(),
    );
  }

  // Create from JSON (from Firestore or SharedPreferences)
  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      userId: json['user_id'] ?? '',
      showNameOnLeaderboard: json['show_name_on_leaderboard'] ?? true,
      theme: json['theme'] ?? 'system',
      notificationsEnabled: json['notifications_enabled'] ?? true,
      locationSharingEnabled: json['location_sharing_enabled'] ?? true,
      offlineMapsEnabled: json['offline_maps_enabled'] ?? false,
      mapType: json['map_type'] ?? 'normal',
      autoNightMode: json['auto_night_mode'] ?? true,
      historyRetentionDays: json['history_retention_days'] ?? 365,
      analyticsEnabled: json['analytics_enabled'] ?? true,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  // Convert to JSON (for Firestore or SharedPreferences)
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'show_name_on_leaderboard': showNameOnLeaderboard,
      'theme': theme,
      'notifications_enabled': notificationsEnabled,
      'location_sharing_enabled': locationSharingEnabled,
      'offline_maps_enabled': offlineMapsEnabled,
      'map_type': mapType,
      'auto_night_mode': autoNightMode,
      'history_retention_days': historyRetentionDays,
      'analytics_enabled': analyticsEnabled,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a copy with updated values
  UserPreferences copyWith({
    String? userId,
    bool? showNameOnLeaderboard,
    String? theme,
    bool? notificationsEnabled,
    bool? locationSharingEnabled,
    bool? offlineMapsEnabled,
    String? mapType,
    bool? autoNightMode,
    int? historyRetentionDays,
    bool? analyticsEnabled,
    DateTime? updatedAt,
  }) {
    return UserPreferences(
      userId: userId ?? this.userId,
      showNameOnLeaderboard: showNameOnLeaderboard ?? this.showNameOnLeaderboard,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      locationSharingEnabled: locationSharingEnabled ?? this.locationSharingEnabled,
      offlineMapsEnabled: offlineMapsEnabled ?? this.offlineMapsEnabled,
      mapType: mapType ?? this.mapType,
      autoNightMode: autoNightMode ?? this.autoNightMode,
      historyRetentionDays: historyRetentionDays ?? this.historyRetentionDays,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to string for caching
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // Create from string (from cache)
  factory UserPreferences.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return UserPreferences.fromJson(json);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreferences &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          showNameOnLeaderboard == other.showNameOnLeaderboard &&
          theme == other.theme &&
          notificationsEnabled == other.notificationsEnabled &&
          locationSharingEnabled == other.locationSharingEnabled &&
          offlineMapsEnabled == other.offlineMapsEnabled &&
          mapType == other.mapType &&
          autoNightMode == other.autoNightMode &&
          historyRetentionDays == other.historyRetentionDays &&
          analyticsEnabled == other.analyticsEnabled;

  @override
  int get hashCode => Object.hash(
        userId,
        showNameOnLeaderboard,
        theme,
        notificationsEnabled,
        locationSharingEnabled,
        offlineMapsEnabled,
        mapType,
        autoNightMode,
        historyRetentionDays,
        analyticsEnabled,
      );

  @override
  String toString() {
    return 'UserPreferences(userId: $userId, theme: $theme, showNameOnLeaderboard: $showNameOnLeaderboard)';
  }
}