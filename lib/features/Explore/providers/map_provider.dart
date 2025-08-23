import 'dart:developer' show log;
import 'dart:ui' as ui;

import 'package:campus_mapper/core/components/custom_marker.dart';
import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:campus_mapper/features/Preferences/providers/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:widget_to_marker/widget_to_marker.dart';

class MapProvider extends ChangeNotifier {
  final Set<Marker> _markers = {};
  // current user location
  LatLng? _currentUserLocation;

  // Map preferences
  MapType _currentMapType = MapType.normal;
  PreferencesProvider? _preferencesProvider;

  LatLng? get currentUserLocation => _currentUserLocation;
  MapType get currentMapType => _currentMapType;

  // user location marker
  Marker? _userLocationMarker;

  MapProvider() {
    // Initialize with user location marker if needed
    _userLocationMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(0, 0), // Default position, will be updated later
      infoWindow: const InfoWindow(title: 'Your Location'),
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      zIndexInt: 2, // Higher zIndex to appear above other markers
    );
  }

  Marker? get userLocationMarker => _userLocationMarker;

  /// Set current user location and update the user location marker
  set currentUserLocation(LatLng? position) {
    _currentUserLocation = position;
    if (position != null) {
      _userLocationMarker = Marker(
        markerId: const MarkerId('user_location'),
        position: position,
        infoWindow: const InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        zIndexInt: 2, // Higher zIndex to appear above other markers
      );
    } else {
      _userLocationMarker = null; // Clear marker if position is null
    }
    notifyListeners();
  }

  /// Get custom marker icon based on category
  // Future<BitmapDescriptor> getCustomMarker(String category) async {
  //   try {
  //     final iconData = _getCategoryIcon(category);
  //     final color = _getCategoryColor(category);

  //     // Create custom marker from icon
  //     // final customMarker = await _createCustomMarker(
  //     //   iconData: iconData,
  //     //   color: color,
  //     //   size: 48.0,
  //     // );

  //     // return customMarker;
  //     return CustomMarker(
  //       icon: iconData,
  //     );
  //   } catch (e) {
  //     log('Error creating custom marker: $e');
  //     return BitmapDescriptor.defaultMarkerWithHue(_getCategoryHue(category));
  //   }
  // }

  /// Create custom marker from icon data
  // Future<BitmapDescriptor> _createCustomMarker({
  //   required IconData iconData,
  //   required Color color,
  //   double size = 48.0,
  // }) async {
  //   try {
  //     final recorder = ui.PictureRecorder();
  //     final canvas = Canvas(recorder);

  //     // Draw circle background
  //     final paint = Paint()
  //       ..color = color
  //       ..style = PaintingStyle.fill;

  //     final center = Offset(size / 2, size / 2);
  //     canvas.drawCircle(center, size / 2 - 2, paint);

  //     // Draw white border
  //     final borderPaint = Paint()
  //       ..color = Colors.white
  //       ..style = PaintingStyle.stroke
  //       ..strokeWidth = 3.0;

  //     canvas.drawCircle(center, size / 2 - 2, borderPaint);

  //     // Draw icon
  //     final textPainter = TextPainter(
  //       textDirection: TextDirection.ltr,
  //     );

  //     textPainter.text = TextSpan(
  //       text: String.fromCharCode(iconData.codePoint),
  //       style: TextStyle(
  //         fontSize: size * 0.5,
  //         fontFamily: iconData.fontFamily,
  //         color: Colors.white,
  //         fontWeight: FontWeight.bold,
  //       ),
  //     );

  //     textPainter.layout();

  //     final iconOffset = Offset(
  //       (size - textPainter.width) / 2,
  //       (size - textPainter.height) / 2,
  //     );

  //     textPainter.paint(canvas, iconOffset);

  //     final picture = recorder.endRecording();
  //     final image = await picture.toImage(size.toInt(), size.toInt());
  //     final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

  //     return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  //   } catch (e) {
  //     log('Error creating custom marker: $e');
  //     return BitmapDescriptor.defaultMarker;
  //   }
  // }

  /// Get category-specific icon
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'class':
      case 'classes':
      case 'academic':
      case 'lecture halls':
        return HugeIcons.strokeRoundedOnlineLearning01;
      case 'food':
      case 'restaurant':
      case 'dining':
      case 'cafeteria':
      case 'canteen':
      case 'food & dining':
        return HugeIcons.strokeRoundedRestaurant02;
      case 'pharmacy':
      case 'pharmacies':
      case 'medical':
      case 'health':
        return HugeIcons.strokeRoundedMedicineBottle01;
      case 'office':
      case 'offices':
      case 'administration':
        return HugeIcons.strokeRoundedOffice;
      case 'atm':
      case 'atms':
      case 'bank':
        return HugeIcons.strokeRoundedAtm01;
      case 'gym':
      case 'gyms':
      case 'sports':
      case 'fitness':
      case 'sports & fitness':
      case 'athletic':
        return HugeIcons.strokeRoundedDumbbell01;
      case 'hostels':
      case 'hostel':
      case 'accommodation':
      case 'residence':
        return HugeIcons.strokeRoundedBedBunk;
      case 'store':
      case 'shop':
      case 'shopping':
      case 'market':
      case 'shopping centers':
        return HugeIcons.strokeRoundedStore04;
      case 'church':
      case 'churches':
      case 'religious':
      case 'chapel':
        return HugeIcons.strokeRoundedChurch;
      case 'library':
      case 'study':
      case 'reading room':
      case 'study spaces':
        return HugeIcons.strokeRoundedBook02;
      case 'printing':
      case 'print':
      case 'photocopy':
      case 'printing services':
        return HugeIcons.strokeRoundedPrinter;
      case 'entertainment':
      case 'recreation':
      case 'fun':
        return HugeIcons.strokeRoundedParty;
      case 'service':
      case 'services':
      case 'utility':
        return HugeIcons.strokeRoundedCustomerService;
      default:
        return HugeIcons.strokeRoundedLocation01;
    }
  }

  /// Get category-specific color
  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'class':
      case 'classes':
      case 'academic':
      case 'lecture halls':
        return Colors.pinkAccent;
      case 'food':
      case 'restaurant':
      case 'dining':
      case 'cafeteria':
      case 'canteen':
      case 'food & dining':
        return Colors.orange;
      case 'pharmacy':
      case 'pharmacies':
      case 'medical':
      case 'health':
        return Colors.teal;
      case 'office':
      case 'offices':
      case 'administration':
        return Colors.deepPurple;
      case 'atm':
      case 'atms':
      case 'bank':
        return Colors.cyan;
      case 'gym':
      case 'gyms':
      case 'sports':
      case 'fitness':
      case 'sports & fitness':
      case 'athletic':
        return Colors.red;
      case 'hostels':
      case 'hostel':
      case 'accommodation':
      case 'residence':
        return Colors.indigo;
      case 'store':
      case 'shop':
      case 'shopping':
      case 'market':
      case 'shopping centers':
        return Colors.blueGrey;
      case 'church':
      case 'churches':
      case 'religious':
      case 'chapel':
        return Colors.lime;
      case 'library':
      case 'study':
      case 'reading room':
      case 'study spaces':
        return Colors.blue;
      case 'printing':
      case 'print':
      case 'photocopy':
      case 'printing services':
        return Colors.grey;
      case 'entertainment':
      case 'recreation':
      case 'fun':
        return Colors.purple;
      case 'service':
      case 'services':
      case 'utility':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  Color _getCategoryHue(String category) {
    switch (category.toLowerCase()) {
      case 'class':
      case 'classes':
        return Color.fromARGB(255, 0, 128, 255);
      case 'food':
      case 'restaurant':
      case 'bars & pubs':
        return Color.fromARGB(255, 255, 165, 0);
      case 'pharmacy':
      case 'pharmacies':
      case 'hospital':
        return Color.fromARGB(255, 255, 0, 0);
      case 'office':
      case 'offices':
        return Color.fromARGB(255, 148, 0, 211);
      case 'atm':
      case 'atms':
        return Color.fromARGB(255, 0, 188, 212);
      case 'gym':
      case 'gyms':
        return Color.fromARGB(255, 255, 255, 0);
      case 'hostels':
      case 'hostel':
        return Color.fromARGB(255, 255, 0, 255);
      case 'store':
      case 'shop':
      case 'shopping centers':
        return Color.fromARGB(255, 76, 175, 80);
      case 'church':
      case 'churches':
        return Color.fromARGB(255, 255, 0, 255);
      default:
        return Color.fromARGB(255, 255, 0, 0);
    }
  }

  void addMarker(Location data) async {
    try {
      _markers.add(
        Marker(
          markerId: MarkerId(data.id?.toString() ?? DateTime.now().toString()),
          position: LatLng(
            data.location['latitude']!,
            data.location['longitude']!,
          ),
          infoWindow: InfoWindow(
            title: data.name,
            snippet: data.description ?? data.category,
            onTap: () {
              // InfoWindow tap handler could be added here
            },
          ),
          draggable: false,
          icon: await CustomMarker(
            icon: _getCategoryIcon(data.category),
            color: _getCategoryColor(data.category),
            iconColor: _getCategoryHue(data.category),
          ).toBitmapDescriptor(
            logicalSize: const Size(80, 80),
            imageSize: const Size(80, 80),
          ),
          zIndexInt: 5,
        ),
      );
      notifyListeners();
    } catch (e) {
      log('Error adding marker: $e');
    }
  }

  void addUserLocationMarker(LatLng position) async {
    try {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: position,
          infoWindow: const InfoWindow(title: 'Your Location'),
          // icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          icon: await CustomMarker(icon: Icons.person).toBitmapDescriptor(
              logicalSize: const Size(80, 80), imageSize: const Size(80, 80)),
          zIndexInt: 5, // Higher zIndex to appear above other markers
        ),
      );
      notifyListeners();
    } catch (e) {
      log('Error adding user location marker: $e');
    }
  }

  ///Get all markers
  Set<Marker> get markers => _markers;

  void clearMarkers() {
    _markers.clear();
    notifyListeners();
  }

  /// Set preferences provider to get map type preference
  void setPreferencesProvider(PreferencesProvider preferencesProvider) {
    _preferencesProvider = preferencesProvider;
    _updateMapTypeFromPreferences();

    // Listen to preference changes
    preferencesProvider.addListener(_updateMapTypeFromPreferences);
  }

  /// Update map type based on user preferences
  void _updateMapTypeFromPreferences() {
    if (_preferencesProvider?.preferences != null) {
      final mapTypeString = _preferencesProvider!.preferences!.mapType;
      _currentMapType = _getMapTypeFromString(mapTypeString);
      notifyListeners();
    }
  }

  /// Convert string to MapType enum
  MapType _getMapTypeFromString(String mapTypeString) {
    switch (mapTypeString.toLowerCase()) {
      case 'satellite':
        return MapType.satellite;
      case 'hybrid':
        return MapType.hybrid;
      case 'terrain':
        return MapType.terrain;
      case 'normal':
      default:
        return MapType.normal;
    }
  }

  /// Manually set map type (will also update preferences)
  void setMapType(MapType mapType) {
    _currentMapType = mapType;
    notifyListeners();

    // Update preferences if available
    if (_preferencesProvider != null) {
      final mapTypeString = _getStringFromMapType(mapType);
      _preferencesProvider!.setMapType(mapTypeString);
    }
  }

  /// Convert MapType enum to string
  String _getStringFromMapType(MapType mapType) {
    switch (mapType) {
      case MapType.satellite:
        return 'satellite';
      case MapType.hybrid:
        return 'hybrid';
      case MapType.terrain:
        return 'terrain';
      case MapType.normal:
      default:
        return 'normal';
    }
  }

  @override
  void dispose() {
    _preferencesProvider?.removeListener(_updateMapTypeFromPreferences);
    super.dispose();
  }
}
