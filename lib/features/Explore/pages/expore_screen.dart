// lib/features/Explore/screens/explore_screen.dart
// import 'dart:developer';

import 'dart:developer';

import 'package:campus_mapper/core/api/route_service.dart';
import 'package:campus_mapper/features/Explore/models/category_item.dart';
import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:campus_mapper/features/Explore/pages/active_journey.dart';
// import 'package:campus_mapper/features/Explore/pages/location_details_screen.dart';
// import 'package:campus_mapper/features/Explore/pages/location_details_screen.dart';
import 'package:campus_mapper/features/Explore/providers/map_provider.dart';
import 'package:campus_mapper/features/Explore/providers/search_provider.dart';
import 'package:campus_mapper/features/Explore/widgets/route_panel.dart';
import 'package:campus_mapper/features/History/pages/history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  // final _supabase = Supabase.instance.client;
  final _firestore = FirebaseFirestore.instance;
  Location? selectedPlace;
  late GoogleMapController _mapController;

  late SearchProvider _searchProvider;

  // Routing state
  bool _isLoadingRoute = false;
  bool _routeAvailable = false;
  Position? _userPosition;
  Set<Polyline> _polylines = {};
  double _routeDistance = 0;
  int _routeDuration = 0;
  double _calories = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MapProvider>(context, listen: false).clearMarkers();
      _getUserLocation();
    });
    // _searchProvider = SearchProvider();
    // if (widget.initialQuery != null) {
    //   _searchController.text = widget.initialQuery!;

    //   _searchProvider.search(widget.initialQuery!);
    // }
    // _searchProvider.loadPopularSearches();
    _searchProvider = Provider.of<SearchProvider>(context, listen: false);
    // _searchProvider.checkCollectionExists();
    // _searchProvider.debugFirestoreData();
    // _searchProvider.loadPopularSearches();
  }

  Future<void> _getUserLocation() async {
    try {
      final position = await RouteService.getCurrentLocation();
      setState(() {
        _userPosition = position;
      });
      // Add user marker to the map
      context.read<MapProvider>().addUserLocationMarker(
            LatLng(position.latitude, position.longitude),
          );
      // Center map on user location
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  /// get bounds
  LatLngBounds _getLatLngBounds(List<LatLng> points) {
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (var point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  /// get route
  Future<void> _getRoute() async {
    print('=== _getRoute CALLED ===');

    if (_userPosition == null) {
      print('❌ User position is null');
      return;
    }

    if (selectedPlace == null) {
      print('❌ Selected place is null');
      return;
    }

    print(
        '✅ User position: ${_userPosition!.latitude}, ${_userPosition!.longitude}');
    print('✅ Selected place: ${selectedPlace!.name}');
    print(
        '✅ Destination coords: ${selectedPlace!.location['latitude']}, ${selectedPlace!.location['longitude']}');

    setState(() {
      _isLoadingRoute = true;
      _routeAvailable = false;
      _polylines = {};
    });

    try {
      final origin = LatLng(_userPosition!.latitude, _userPosition!.longitude);
      final destination = LatLng(
        selectedPlace!.location['latitude'] ?? 0.0,
        selectedPlace!.location['longitude'] ?? 0.0,
      );

      print('🔄 Calling RouteService.getRoute...');
      final routeData = await RouteService.getRoute(origin, destination);
      print('✅ Route data received: $routeData');

      double distance = 0.0;
      int duration = 0;

      final distanceValue = routeData['distance'];
      if (distanceValue is double) {
        distance = distanceValue;
      } else if (distanceValue is int) {
        distance = distanceValue.toDouble();
      } else if (distanceValue is String) {
        try {
          distance =
              double.parse(distanceValue.replaceAll(RegExp(r'[^0-9.]'), ''));
        } catch (e) {
          distance = RouteService.calculateDistance(origin, destination) * 1000;
        }
      }

      final durationValue = routeData['duration'];
      if (durationValue is int) {
        duration = durationValue;
      } else if (durationValue is double) {
        duration = durationValue.round();
      } else if (durationValue is String) {
        try {
          duration = int.parse(durationValue.replaceAll(RegExp(r'[^0-9]'), ''));
        } catch (e) {
          duration = (distance / 1.4).round();
        }
      }

      print('📊 Parsed - Distance: ${distance}m, Duration: ${duration}s');

      final polyline = Polyline(
        polylineId: const PolylineId('route'),
        points: routeData['polylineCoordinates'] ?? [origin, destination],
        color: Theme.of(context).colorScheme.primary,
        width: 5,
        patterns: [],
      );

      setState(() {
        _polylines = {polyline};
        _routeDistance = distance;
        _routeDuration = duration;
        _calories = RouteService.calculateCalories(_routeDistance);
        _isLoadingRoute = false;
        _routeAvailable = true;
      });

      print('✅ Route available: $_routeAvailable');
      print('✅ Route distance: $_routeDistance');
      print('✅ Route duration: $_routeDuration');
      print('✅ Calories: $_calories');

      final polylineCoords =
          routeData['polylineCoordinates'] ?? [origin, destination];
      if (polylineCoords.isNotEmpty) {
        _mapController.animateCamera(
          CameraUpdate.newLatLngBounds(
            _getLatLngBounds(polylineCoords),
            100,
          ),
        );
      }
    } catch (e) {
      print('❌ Error in _getRoute: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      setState(() {
        _isLoadingRoute = false;
        _routeAvailable = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error calculating route: $e')),
      );
    }
  }

// Also add debugging to _startJourney
  // void _startJourney() {
  //   print('=== _startJourney CALLED ===');
  //   print('Selected place: $selectedPlace');
  //   print('Route available: $_routeAvailable');

  //   if (selectedPlace == null) {
  //     print('❌ selectedPlace is null');
  //     return;
  //   }

  //   if (!_routeAvailable) {
  //     print('❌ route not available');
  //     return;
  //   }

  //   print('✅ Starting journey to: ${selectedPlace!.name}');

  //   Navigator.of(context).push(
  //     MaterialPageRoute(
  //       builder: (context) => ActiveJourneyScreen(
  //         destinationName: selectedPlace!.name ?? 'Selected Location',
  //         destinationLocation: LatLng(
  //           selectedPlace!.location['latitude'] ?? 0.0,
  //           selectedPlace!.location['longitude'] ?? 0.0,
  //         ),
  //         polylines: _polylines,
  //         distance: _routeDistance,
  //         calories: _calories,
  //       ),
  //     ),
  //   );
  // }

  /// start journey - FIXED VERSION
  void _startJourney() {
    if (selectedPlace == null || !_routeAvailable) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActiveJourneyScreen(
          destinationName: selectedPlace!.name ?? 'Selected Location',
          destinationLocation: LatLng(
            selectedPlace!.location['latitude'] ?? 0.0,
            selectedPlace!.location['longitude'] ?? 0.0,
          ),
          polylines: _polylines,
          distance: _routeDistance,
          calories: _calories,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TypeAheadField<Map<String, dynamic>>(
                    suggestionsCallback: (pattern) async {
                      try {
                        final response = await Provider.of<SearchProvider>(
                          context,
                          listen: false,
                        ).searchByName(pattern);

                        return response;
                      } catch (e) {
                        print('Search error: $e');
                        return [];
                      }
                    },
                    itemBuilder: (context, Map<String, dynamic> suggestion) {
                      return ListTile(
                        title: Text(suggestion['name'] ?? 'Unknown'),
                        subtitle: Text(
                          suggestion['category'] ?? '',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        leading: Icon(
                          getCategoryIcon(suggestion['category'] ?? ''),
                        ),
                      );
                    },
                    onSelected: (Map<String, dynamic> suggestion) {
                      setState(() {
                        selectedPlace = Location.fromJson(suggestion);
                        log('Selected place: ${selectedPlace!.location['latitude']}, ${selectedPlace!.location['longitude']}');
                        // Clear previous markers and polylines
                        context.read<MapProvider>().clearMarkers();
                        _polylines = {};
                        _routeAvailable = false;

                        // Add the selected location marker
                        context.read<MapProvider>().addMarker(selectedPlace!);

                        // Add user location marker back
                        if (_userPosition != null) {
                          context.read<MapProvider>().addUserLocationMarker(
                                LatLng(_userPosition!.latitude,
                                    _userPosition!.longitude),
                              );
                        }

                        _mapController.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              selectedPlace!.location['latitude']!,
                              selectedPlace!.location['longitude']!,
                            ),
                            17,
                          ),
                        );

                        // Calculate route when a place is selected
                        _getRoute();
                      });
                    },
                    builder: (context, textController, focusNode) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Search a location',
                          prefixIcon:
                              const Icon(HugeIcons.strokeRoundedSearch01),
                          suffixIcon: const Icon(Icons.mic),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          // filled: true,
                          fillColor: Colors.grey[100],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Category Icons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildCategoryItem(
                          HugeIcons.strokeRoundedOnlineLearning01, 'Classes'),
                      _buildCategoryItem(
                          HugeIcons.strokeRoundedOffice, 'Offices'),
                      _buildCategoryItem(
                          HugeIcons.strokeRoundedRestaurant02, 'Food'),
                      _buildCategoryItem(
                          HugeIcons.strokeRoundedStore04, 'Store'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Map View
          Expanded(
            child: Stack(
              // fit: StackFit.loose,
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(5.362312610147424, -0.633134506275042),
                    zoom: 13,
                  ),
                  mapType: MapType.normal,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  markers: context.watch<MapProvider>().markers,
                  polylines: _polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  zoomControlsEnabled: false,
                  compassEnabled: false,
                ),

                // Loading indicator
                if (_isLoadingRoute)
                  const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Calculating route...'),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Route panel (when route is available)

                if (_routeAvailable &&
                    selectedPlace != null &&
                    !_isLoadingRoute)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: RoutePanel(
                      destinationName:
                          selectedPlace!.name ?? 'Selected Location',
                      distance:
                          '${(_routeDistance / 1000).toStringAsFixed(2)} km',
                      duration: _formatDuration(_routeDuration),
                      calories: _calories,
                      onStartJourney: _startJourney,
                      onClose: () {
                        setState(() {
                          _routeAvailable = false;
                          _polylines = {};
                          selectedPlace = null;
                          context.read<MapProvider>().clearMarkers();
                          // Add user location marker back
                          if (_userPosition != null) {
                            context.read<MapProvider>().addUserLocationMarker(
                                  LatLng(_userPosition!.latitude,
                                      _userPosition!.longitude),
                                );
                          }
                        });
                      },
                    ),
                  ),

                // Categories Panel (only show when no route is available and not loading)
                if (!_routeAvailable && !_isLoadingRoute)
                  DraggableScrollableSheet(
                    // expand: true,
                    snap: true,
                    snapSizes: const [0.3, 1],
                    initialChildSize: 0.3,
                    minChildSize: 0.1,
                    maxChildSize: 1,
                    builder: (context, scrollController) {
                      return Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: _buildCategoryGrid(),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    if (hours > 0) {
      return '$hours h $minutes min';
    } else {
      return '$minutes min';
    }
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      CategoryItem('Classes', HugeIcons.strokeRoundedOnlineLearning01,
          Colors.pinkAccent),
      CategoryItem('Study Spaces', HugeIcons.strokeRoundedBook02, Colors.blue),
      CategoryItem('Offices', HugeIcons.strokeRoundedOffice, Colors.deepPurple),
      CategoryItem('Hostels', HugeIcons.strokeRoundedBedBunk, Colors.indigo),
      CategoryItem(
          'Printing Services', HugeIcons.strokeRoundedPrinter, Colors.grey),
      CategoryItem(
          'Food & Dining', HugeIcons.strokeRoundedRestaurant02, Colors.orange),
      CategoryItem('Churches', HugeIcons.strokeRoundedChurch, Colors.lime),
      CategoryItem(
          'Pharmacies', HugeIcons.strokeRoundedMedicineBottle01, Colors.teal),
      CategoryItem(
          'Entertainment', HugeIcons.strokeRoundedParty, Colors.purple),
      CategoryItem(
          'Sports & Fitness', HugeIcons.strokeRoundedDumbbell01, Colors.red),
      CategoryItem('Shopping Centers', HugeIcons.strokeRoundedShoppingCart01,
          Colors.pink),
      CategoryItem('ATMs', HugeIcons.strokeRoundedAtm01, Colors.cyan),
      // CategoryItem(
      //     'Bars & Pubs', HugeIcons.strokeRoundedDrink, Colors.deepOrange),
      CategoryItem('Store', HugeIcons.strokeRoundedStore04, Colors.blueGrey),
      CategoryItem(
          'Services', HugeIcons.strokeRoundedCustomerService, Colors.green),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () async {
            // _searchController.text = category.name;
            await _searchProvider.searchByCategory(category.name);
            print(category.name);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => EnhancedSearchScreen(
                  initialQuery: category.name,
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: category.color.withAlpha(77),
              ),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: category.icon,
                  color: category.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: category.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData getCategoryIcon(String categoryName) {
    final categoryMap = {
      'Classes': HugeIcons.strokeRoundedOnlineLearning01,
      'Offices': HugeIcons.strokeRoundedOffice,
      'Hostels': HugeIcons.strokeRoundedBedBunk,
      'Printing Services': HugeIcons.strokeRoundedPrinter,
      'Churches': HugeIcons.strokeRoundedChurch,
      'Pharmacies': HugeIcons.strokeRoundedMedicineBottle01,
      'Shopping centers': HugeIcons.strokeRoundedShoppingCart01,
      'Food': HugeIcons.strokeRoundedRestaurant02,
      'Store': HugeIcons.strokeRoundedStore04,
      'ATMs': HugeIcons.strokeRoundedAtm01,
      'Groceries': HugeIcons.strokeRoundedShoppingBag02,
      'Bars & Pubs': HugeIcons.strokeRoundedDrink,
      'Gyms': HugeIcons.strokeRoundedDumbbell01,
    };

    return categoryMap[categoryName] ??
        Icons.help_outline; // Default icon if not found
  }
}
