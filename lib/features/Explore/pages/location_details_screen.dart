import 'package:campus_mapper/core/api/route_service.dart';
import 'package:campus_mapper/core/services/location_manager.dart';
import 'package:campus_mapper/features/Auth/providers/auth_provider.dart';
import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:campus_mapper/features/Explore/pages/active_journey.dart';
import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'package:campus_mapper/features/Preferences/providers/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class LocationDetailScreen extends StatefulWidget {
  final Location location;

  const LocationDetailScreen({super.key, required this.location});

  @override
  State<LocationDetailScreen> createState() => _LocationDetailScreenState();
}

class _LocationDetailScreenState extends State<LocationDetailScreen> {
  bool _isLoadingRoute = false;
  bool _isLoadingFavorite = false;
  Map<String, dynamic>? _routeData;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _trackLocationVisit();
  }

  void _trackLocationVisit() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.isLoggedIn) {
      final historyProvider =
          Provider.of<UserHistoryProvider>(context, listen: false);
      final historyItem = UserHistory.placeVisited(
        userId: authProvider.currentUser!.uid,
        placeId: widget.location.id ?? 'unknown',
        placeName: widget.location.name ?? 'Unknown',
        category: widget.location.category,
        latitude: widget.location.location['latitude'],
        longitude: widget.location.location['longitude'],
      );
      await historyProvider.addHistoryItem(historyItem);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.location.name ?? 'Location'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withAlpha(180),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(widget.location.category),
                    size: 64,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic info
                  Row(
                    children: [
                      Chip(
                        label: Text(widget.location.category),
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .primary
                            .withAlpha(180),
                      ),
                      const Spacer(),
                      // if (location.rating != null) ...[
                      //   const Icon(Icons.star, color: Colors.amber),
                      //   const SizedBox(width: 4),
                      //   Text(
                      //     location.rating!.toStringAsFixed(1),
                      //     style: const TextStyle(fontWeight: FontWeight.bold),
                      //   ),
                      //   if (location.reviewCount != null) ...[
                      //     const SizedBox(width: 4),
                      //     Text('(${location.reviewCount} reviews)'),
                      //   ],
                      // ],
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  if (widget.location.description != null) ...[
                    const Text(
                      'About',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.location.description!),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isLoadingRoute ? null : _getDirections,
                          icon: _isLoadingRoute
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(HugeIcons.strokeRoundedDirections01),
                          label: const Text('Directions'),
                        ),
                      ),
                      // const SizedBox(width: 12),
                      // Expanded(
                      //   child: Consumer<PreferencesProvider>(
                      //     builder: (context, preferencesProvider, child) {
                      //       final isFavorite = _isLocationFavorite(preferencesProvider);
                      //       return OutlinedButton.icon(
                      //         onPressed: _isLoadingFavorite ? null : () => _toggleFavorite(isFavorite),
                      //         icon: _isLoadingFavorite
                      //             ? const SizedBox(
                      //                 width: 16,
                      //                 height: 16,
                      //                 child: CircularProgressIndicator(strokeWidth: 2),
                      //               )
                      //             : Icon(
                      //                 HugeIcons.strokeRoundedFavourite,
                      //                 color: isFavorite ? Colors.red : null,
                      //               ),
                      //         label: Text(isFavorite ? 'Saved' : 'Save'),
                      //       );
                      //     },
                      //   ),
                      // ),
                    ],
                  ),

                  // Route information card
                  if (_routeData != null) ...[
                    const SizedBox(height: 16),
                    _buildRouteInfoCard(),
                  ],

                  const SizedBox(height: 24),

                  // Map preview
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                        },
                        initialCameraPosition: CameraPosition(
                          target: LatLng(
                            widget.location.location['latitude']?.toDouble() ??
                                0.0,
                            widget.location.location['longitude']?.toDouble() ??
                                0.0,
                          ),
                          zoom: 16,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(widget.location.id ?? 'unknown'),
                            position: LatLng(
                              widget.location.location['latitude']
                                      ?.toDouble() ??
                                  0.0,
                              widget.location.location['longitude']
                                      ?.toDouble() ??
                                  0.0,
                            ),
                            infoWindow: InfoWindow(
                              title: widget.location.name,
                              snippet: widget.location.category,
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              _getMarkerColor(widget.location.category),
                            ),
                          ),
                        },
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        myLocationButtonEnabled: false,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final categoryMap = {
      // 'Food': HugeIcons.strokeRoundedRestaurant02,
      // 'Study': HugeIcons.strokeRoundedBook02,
      // 'Entertainment': HugeIcons.strokeRoundedParty,
      // 'Services': HugeIcons.strokeRoundedCustomerService,
      // 'Sports': HugeIcons.strokeRoundedDumbbell01,
      // 'Shopping': HugeIcons.strokeRoundedShoppingBag02,
      'ATMs': HugeIcons.strokeRoundedAtm01,
      'Pharmacies': HugeIcons.strokeRoundedMedicineBottle01,
      'Groceries': HugeIcons.strokeRoundedShoppingBag02,
      'Bars & Pubs': HugeIcons.strokeRoundedDrink,
      'Shopping centers': HugeIcons.strokeRoundedShoppingCart01,
      'Hostels': HugeIcons.strokeRoundedBedBunk,
      'Gyms': HugeIcons.strokeRoundedDumbbell01,
      'Churches': HugeIcons.strokeRoundedChurch,
      'Printing Services': HugeIcons.strokeRoundedPrinter,
      'Classes': HugeIcons.strokeRoundedOnlineLearning01,
      'Offices': HugeIcons.strokeRoundedOffice,
      'Food': HugeIcons.strokeRoundedRestaurant02,
      'Store': HugeIcons.strokeRoundedStore04,
    };

    return categoryMap[category] ?? HugeIcons.strokeRoundedLocation01;
  }

  double _getMarkerColor(String category) {
    final colorMap = {
      'ATMs': BitmapDescriptor.hueGreen,
      'Pharmacies': BitmapDescriptor.hueRed,
      'Groceries': BitmapDescriptor.hueOrange,
      'Bars & Pubs': BitmapDescriptor.hueViolet,
      'Shopping centers': BitmapDescriptor.hueBlue,
      'Hostels': BitmapDescriptor.hueCyan,
      'Gyms': BitmapDescriptor.hueYellow,
      'Churches': BitmapDescriptor.hueRose,
      'Printing Services': BitmapDescriptor.hueAzure,
      'Classes': BitmapDescriptor.hueMagenta,
      'Offices': BitmapDescriptor.hueBlue,
      'Food': BitmapDescriptor.hueOrange,
      'Store': BitmapDescriptor.hueBlue,
    };
    return colorMap[category] ?? BitmapDescriptor.hueRed;
  }

  Future<void> _getDirections() async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final userLocation = await LocationManager.getCurrentLocation();
      if (userLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to get your current location'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final destination = LatLng(
        widget.location.location['latitude']?.toDouble() ?? 0.0,
        widget.location.location['longitude']?.toDouble() ?? 0.0,
      );

      final origin = LatLng(userLocation.latitude, userLocation.longitude);

      final routeData = await RouteService.getRoute(origin, destination);

      if (mounted) {
        setState(() {
          _routeData = routeData;
        });

        // Track route calculation in history
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.isLoggedIn) {
          final historyProvider =
              Provider.of<UserHistoryProvider>(context, listen: false);
          final distance = routeData['distance'] as double? ?? 0.0;
          final duration = routeData['duration'] as int? ?? 0;

          final historyItem = UserHistory.routeCalculated(
            userId: authProvider.currentUser!.uid,
            fromPlace: 'Current Location',
            toPlace: widget.location.name ?? 'Unknown',
            distance: distance,
            duration: duration,
            latitude: widget.location.location['latitude'],
            longitude: widget.location.location['longitude'],
          );
          await historyProvider.addHistoryItem(historyItem);
        }

        // Create polylines for route visualization
        final polylineCoordinates =
            routeData['polylineCoordinates'] as List<LatLng>? ?? [];
        final polylines = <Polyline>{};
        if (polylineCoordinates.isNotEmpty && mounted) {
          polylines.add(
            Polyline(
              polylineId: const PolylineId('route'),
              points: polylineCoordinates,
              color: Theme.of(context).colorScheme.primary,
              width: 5,
            ),
          );
        }

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Route calculated! Tap "Start Journey" to begin navigation.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error calculating route: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  bool _isLocationFavorite(PreferencesProvider preferencesProvider) {
    // For now, always return false since favorites aren't implemented in UserPreferences yet
    // This will be enhanced when favorites are added to the preferences model
    return false;
  }

  Future<void> _toggleFavorite(bool isCurrentlyFavorite) async {
    setState(() {
      _isLoadingFavorite = true;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (!authProvider.isLoggedIn) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to save favorites'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Track in history
      if (mounted) {
        final historyProvider =
            Provider.of<UserHistoryProvider>(context, listen: false);
        final historyItem = UserHistory.placeFavorited(
          userId: authProvider.currentUser!.uid,
          placeId: widget.location.id ?? 'unknown',
          placeName: widget.location.name ?? 'Unknown',
          category: widget.location.category,
          latitude: widget.location.location['latitude'],
          longitude: widget.location.location['longitude'],
        );
        await historyProvider.addHistoryItem(historyItem);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Location marked as favorite! (Full favorites functionality coming soon)'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving favorite: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Widget _buildRouteInfoCard() {
    if (_routeData == null) return const SizedBox.shrink();

    final distance = _routeData!['distance'] as double? ?? 0.0;
    final duration = _routeData!['duration'] as int? ?? 0;
    final calories = RouteService.calculateCalories(distance);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Route Information',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildRouteStatItem(
                  context,
                  'Distance',
                  '${(distance / 1000).toStringAsFixed(1)} km',
                  HugeIcons.strokeRoundedRoute01,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRouteStatItem(
                  context,
                  'Walking Time',
                  '${(duration / 60).round()} min',
                  HugeIcons.strokeRoundedTime04,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRouteStatItem(
                  context,
                  'Calories',
                  '${calories.round()} cal',
                  HugeIcons.strokeRoundedFire,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startJourney(),
              icon: const Icon(HugeIcons.strokeRoundedPlay),
              label: const Text('Start Journey'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteStatItem(
      BuildContext context, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onPrimaryContainer
                    .withAlpha(153),
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _startJourney() {
    if (_routeData == null) return;

    final distance = _routeData!['distance'] as double? ?? 0.0;
    final calories = RouteService.calculateCalories(distance);

    // Create polylines for route visualization
    final polylineCoordinates =
        _routeData!['polylineCoordinates'] as List<LatLng>? ?? [];
    final polylines = <Polyline>{};
    if (polylineCoordinates.isNotEmpty) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: polylineCoordinates,
          color: Theme.of(context).colorScheme.primary,
          width: 5,
        ),
      );
    }

    // Navigate to ActiveJourneyScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ActiveJourneyScreen(
          destinationName: widget.location.name ?? 'Unknown',
          destinationLocation: LatLng(
            widget.location.location['latitude']?.toDouble() ?? 0.0,
            widget.location.location['longitude']?.toDouble() ?? 0.0,
          ),
          polylines: polylines,
          distance: distance,
          calories: calories,
        ),
      ),
    );
  }
}
