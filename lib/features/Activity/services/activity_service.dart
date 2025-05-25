// lib/features/Explore/services/activity_service.dart
import 'dart:async';

import 'package:flutter_activity_recognition/flutter_activity_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

enum UserActivity { walking, running, cycling, driving, still, unknown }

class ActivityService {
  static final FlutterActivityRecognition _activityRecognition =
      FlutterActivityRecognition.instance;
  static StreamSubscription<Activity>? _activitySubscription;
  static UserActivity _currentActivity = UserActivity.unknown;

  // Callbacks for activity changes
  static Function(UserActivity)? onActivityChanged;

  // Initialize activity recognition
  static Future<bool> initialize() async {
    try {
      // Request activity recognition permission
      // final permission = await Permission.activityRecognition.request();
      var permission = await _activityRecognition.checkPermission();
      if (permission == ActivityPermission.PERMANENTLY_DENIED) {
        // throw Exception('Activity recognition permission denied');
        return false;
      } else if (permission == ActivityPermission.DENIED) {
        permission = await _activityRecognition.requestPermission();
        if (permission != ActivityPermission.GRANTED) {
          // permission is denied.
          return false;
        }
      }
      return true;
    } catch (e) {
      print('Error initializing activity recognition: $e');
      return false;
    }
  }

  // Start monitoring user activity
  static Future<void> startMonitoring() async {
    try {
      // await _activityRecognition.startStream(runForegroundService: true);

      _activitySubscription = _activityRecognition.activityStream.listen(
        (Activity activity) {
          final newActivity = _mapActivityType(activity.type);

          if (newActivity != _currentActivity) {
            _currentActivity = newActivity;
            onActivityChanged?.call(_currentActivity);
            print('Activity changed to: ${_currentActivity.name}');
          }
        },
        onError: (error) {
          print('Activity recognition error: $error');
        },
      );
    } catch (e) {
      print('Error starting activity monitoring: $e');
    }
  }

  // Stop monitoring
  static Future<void> stopMonitoring() async {
    try {
      await _activitySubscription?.cancel();
      // await _activityRecognition.stopStream();
      _activitySubscription = null;
    } catch (e) {
      print('Error stopping activity monitoring: $e');
    }
  }

  // Get current activity
  static UserActivity getCurrentActivity() {
    return _currentActivity;
  }

  // Check if current activity burns calories (walking/running)
  static bool isCalorieBurningActivity() {
    return _currentActivity == UserActivity.walking ||
        _currentActivity == UserActivity.running;
  }

  // Calculate calories based on activity and distance
  static double calculateCaloriesForActivity(
      double distanceInMeters, UserActivity activity) {
    if (!isCalorieBurningActivity()) {
      return 0.0; // No calories for vehicle travel
    }

    final distanceInKm = distanceInMeters / 1000;

    switch (activity) {
      case UserActivity.walking:
        return distanceInKm * 65; // 65 calories per km walking
      case UserActivity.running:
        return distanceInKm * 120; // 120 calories per km running
      default:
        return 0.0;
    }
  }

  // Map activity recognition types to our enum
  static UserActivity _mapActivityType(ActivityType type) {
    switch (type) {
      case ActivityType.WALKING:
        return UserActivity.walking;
      case ActivityType.RUNNING:
        return UserActivity.running;
      case ActivityType.ON_BICYCLE:
        return UserActivity.cycling;
      case ActivityType.IN_VEHICLE:
        return UserActivity.driving;
      case ActivityType.STILL:
        return UserActivity.still;
      default:
        return UserActivity.unknown;
    }
  }

  // Get activity display name
  static String getActivityDisplayName(UserActivity activity) {
    switch (activity) {
      case UserActivity.walking:
        return 'Walking';
      case UserActivity.running:
        return 'Running';
      case UserActivity.cycling:
        return 'Cycling';
      case UserActivity.driving:
        return 'Driving';
      case UserActivity.still:
        return 'Still';
      case UserActivity.unknown:
        return 'Unknown';
    }
  }

  // Get activity icon
  static String getActivityIcon(UserActivity activity) {
    switch (activity) {
      case UserActivity.walking:
        return '🚶';
      case UserActivity.running:
        return '🏃';
      case UserActivity.cycling:
        return '🚴';
      case UserActivity.driving:
        return '🚗';
      case UserActivity.still:
        return '🧍';
      case UserActivity.unknown:
        return '❓';
    }
  }
}
