# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Campus Mapper is a Flutter application that helps students navigate campus effectively. It uses Google Maps integration, Firebase services, and provides real-time location tracking and route planning.

## Development Commands

### Flutter Commands
- `flutter run` - Run the app in debug mode
- `flutter build apk` - Build Android APK
- `flutter build ios` - Build iOS app
- `flutter clean` - Clean build artifacts
- `flutter pub get` - Install dependencies
- `flutter test` - Run tests
- `flutter analyze` - Run static analysis

## Architecture

### Core Structure
- **lib/main.dart** - App entry point with Firebase initialization and provider setup
- **lib/features/** - Feature-based architecture with separate modules:
  - **Home/** - Main screen with navigation
  - **Explore/** - Map functionality, location search, and route planning
  - **History/** - User journey history
  - **Activity/** - Activity tracking services

### Key Components
- **core/api/route_service.dart** - Google Maps API integration for route calculation
- **core/components/navbar.dart** - Bottom navigation component
- **core/custom_theme.dart** - App theming configuration

### State Management
- Uses Provider pattern for state management
- **MapProvider** - Manages map markers and user location
- **SearchProvider** - Handles location search functionality

### Firebase Integration
- Firebase Core for initialization
- Cloud Firestore for data storage
- Firebase Auth for authentication
- Firebase Storage for file storage

### Location Services
- Google Maps Flutter for map display
- Geolocator for device location
- Google Maps Routes for route planning
- Foreground task for location tracking

## Key Features

### Map Functionality
- Real-time location tracking
- Custom markers for different location categories
- Route calculation with Google Directions API
- Walking directions with estimated time and calories

### Location Categories
- Classes/Academic buildings
- Food/Restaurants
- Pharmacies/Hospitals
- Offices
- ATMs
- Gyms
- Hostels
- Stores/Shopping

### Environment Configuration
- API keys stored in `lib/env.dart`
- Firebase configuration in `lib/firebase_options.dart`

## Development Notes

### Testing
- Widget tests located in `test/widget_test.dart`
- Run tests with `flutter test`

### Platform Support
- Android and iOS supported
- Web support configured but may need additional setup

### Dependencies
- Google Maps integration requires API key setup
- Firebase services need configuration files
- Location permissions required for core functionality

### Location Services
- **LocationManager** (`lib/core/services/location_manager.dart`) - Centralized location service
- Prevents multiple simultaneous permission requests
- Implements singleton pattern for location access
- Handles location caching and error recovery
- Use `LocationManager.getCurrentLocation()` instead of direct Geolocator calls

### Known Issues & Solutions
- **Permission Request Conflicts**: Use LocationManager to prevent "PERMISSION_REQUEST_IN_PROGRESS" errors
- **Multiple Location Requests**: LocationManager includes request queuing and caching

## Firebase Database Schema

### User History Collection
**Collection:** `user_history`

The app tracks user activities using the following schema:

```json
{
  "id": "auto_generated_id",
  "user_id": "string",
  "action_type": "string", // "place_added", "journey_completed", "place_visited", "place_favorited", "search_performed", "route_calculated"
  "details": {
    "place_id": "string",
    "place_name": "string",
    "activity_id": "string", // Reference to user_activities if applicable
    "metadata": {
      "category": "string",
      "distance": "number",
      "duration": "number",
      "query": "string",
      "results_count": "number"
    }
  },
  "timestamp": "timestamp",
  "location": {
    "latitude": "number",
    "longitude": "longitude"
  }
}
```

### Action Types:
- **search_performed**: User searched for locations
- **place_visited**: User viewed location details
- **route_calculated**: User calculated route to destination
- **journey_completed**: User completed navigation journey
- **place_favorited**: User added location to favorites
- **place_added**: User contributed new location

### History Integration:
- **UserHistoryService** handles all database operations
- **UserHistoryProvider** manages state and UI updates
- History is automatically tracked for:
  - Location searches (text and category)
  - Place visits and selections
  - Route calculations and navigation starts
  - Location favorites and additions

### Usage in Code:
```dart
// Add search history
final historyItem = UserHistory.searchPerformed(
  userId: userId,
  searchQuery: query,
  category: category,
  resultsCount: results.length,
);
await userHistoryProvider.addHistoryItem(historyItem);

// Add place visit history
final historyItem = UserHistory.placeVisited(
  userId: userId,
  placeId: placeId,
  placeName: placeName,
  category: category,
  latitude: lat,
  longitude: lng,
);
await userHistoryProvider.addHistoryItem(historyItem);
```