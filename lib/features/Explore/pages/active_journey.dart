import 'dart:async';

import 'package:campus_mapper/features/Auth/providers/auth_provider.dart';
import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class ActiveJourneyScreen extends StatefulWidget {
  final String destinationName;
  final LatLng destinationLocation;
  final Set<Polyline> polylines;
  final double distance;
  final double calories;

  const ActiveJourneyScreen({
    super.key,
    required this.destinationName,
    required this.destinationLocation,
    required this.polylines,
    required this.distance,
    required this.calories,
  });

  @override
  State<ActiveJourneyScreen> createState() => _ActiveJourneyScreenState();
}

class _ActiveJourneyScreenState extends State<ActiveJourneyScreen> {
  late GoogleMapController _mapController;
  Position? _currentPosition;
  Timer? _locationTimer;
  double _distanceCovered = 0;
  double _caloriesBurned = 0;
  DateTime? _journeyStartTime;
  Set<Marker> _markers = {};
  bool _journeyComplete = false;

  @override
  void initState() {
    super.initState();
    _setupLocationUpdates();
    _journeyStartTime = DateTime.now();
    _setupMarkers();
  }

  void _setupMarkers() {
    _markers = {
      Marker(
        markerId: const MarkerId('destination'),
        position: widget.destinationLocation,
        infoWindow: InfoWindow(title: widget.destinationName),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Future<void> _setupLocationUpdates() async {
    try {
      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});

      // Update location every 5 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
        final newPosition = await Geolocator.getCurrentPosition();

        if (_currentPosition != null) {
          // Calculate distance covered in this segment
          final segmentDistance = Geolocator.distanceBetween(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
            newPosition.latitude,
            newPosition.longitude,
          );

          // Update total distance and calories
          setState(() {
            _distanceCovered += segmentDistance;
            _caloriesBurned =
                (_distanceCovered / 1000) * 65; // 65 calories per km
            _currentPosition = newPosition;
          });

          // Check if destination reached (within 50 meters)
          final distanceToDestination = Geolocator.distanceBetween(
            newPosition.latitude,
            newPosition.longitude,
            widget.destinationLocation.latitude,
            widget.destinationLocation.longitude,
          );

          if (distanceToDestination < 50 && !_journeyComplete) {
            setState(() {
              _journeyComplete = true;
            });
            _showCompletionDialog();
          }
        } else {
          setState(() {
            _currentPosition = newPosition;
          });
        }

        // Update current location marker
        setState(() {
          _markers = {
            ..._markers,
            Marker(
              markerId: const MarkerId('current_location'),
              position: LatLng(newPosition.latitude, newPosition.longitude),
              infoWindow: const InfoWindow(title: 'Your Location'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure),
            ),
          };
        });

        // Center map on current location
        _mapController.animateCamera(
          CameraUpdate.newLatLng(
              LatLng(newPosition.latitude, newPosition.longitude)),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating location: $e')),
      );
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Destination Reached!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              HugeIcons.strokeRoundedCheckmarkCircle01,
              color: Colors.green,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text('You have arrived at ${widget.destinationName}'),
            const SizedBox(height: 8),
            Text(
                'Distance covered: ${(_distanceCovered / 1000).toStringAsFixed(2)} km'),
            Text(
                'Calories burned: ${_caloriesBurned.toStringAsFixed(0)} calories'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _saveJourneyCompletion();
              if (mounted) {
                Navigator.of(context).pop(); // Return to explore screen
              }
            },
            child: const Text('Finish'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final journeyDuration = _journeyStartTime != null
        ? DateTime.now().difference(_journeyStartTime!)
        : Duration.zero;

    return Scaffold(
      appBar: AppBar(
        title: Text('Journey to ${widget.destinationName}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final scaffoldContext = context;
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('End Journey?'),
                content:
                    const Text('Are you sure you want to end your journey?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(dialogContext).pop();
                      await _saveJourneyCancellation();
                      if (mounted) {
                        Navigator.of(scaffoldContext).pop();
                      }
                    },
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition != null
                  ? LatLng(
                      _currentPosition!.latitude, _currentPosition!.longitude)
                  : widget.destinationLocation,
              zoom: 15,
            ),
            polylines: widget.polylines,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
          ),

          // Journey info panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'On your way to ${widget.destinationName}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildJourneyInfo(
                        context,
                        HugeIcons.strokeRoundedClock01,
                        _formatDuration(journeyDuration),
                        'Time',
                      ),
                      _buildJourneyInfo(
                        context,
                        HugeIcons.strokeRoundedRoute01,
                        '${(_distanceCovered / 1000).toStringAsFixed(2)} km',
                        'Distance',
                      ),
                      _buildJourneyInfo(
                        context,
                        HugeIcons.strokeRoundedFire,
                        _caloriesBurned.toStringAsFixed(0),
                        'Calories',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value: _distanceCovered / widget.distance,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${(_distanceCovered / widget.distance * 100).toStringAsFixed(0)}% complete',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
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

  Widget _buildJourneyInfo(
    BuildContext context,
    IconData icon,
    String value,
    String label,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Future<void> _saveJourneyCompletion() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    try {
      final historyProvider =
          Provider.of<UserHistoryProvider>(context, listen: false);
      final journeyDuration = DateTime.now().difference(_journeyStartTime!);

      // Create journey completion history with actual values
      final historyItem = UserHistory.journeyCompleted(
        userId: authProvider.currentUser!.uid,
        activityId: 'journey_${DateTime.now().millisecondsSinceEpoch}',
        fromPlace: 'Current Location',
        toPlace: widget.destinationName,
        distance: _distanceCovered, // Use actual distance covered
        duration: journeyDuration.inMinutes, // Use actual duration
        latitude: widget.destinationLocation.latitude,
        longitude: widget.destinationLocation.longitude,
      );

      await historyProvider.addHistoryItem(historyItem);
    } catch (e) {
      debugPrint('Error saving journey completion: $e');
      // Don't block the user if history fails to save
    }
  }

  Future<void> _saveJourneyCancellation() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!authProvider.isLoggedIn) return;

    try {
      final historyProvider =
          Provider.of<UserHistoryProvider>(context, listen: false);
      final journeyDuration = DateTime.now().difference(_journeyStartTime!);

      // Create journey completion history with partial values (cancelled journey)
      final historyItem = UserHistory.journeyCompleted(
        userId: authProvider.currentUser!.uid,
        activityId:
            'journey_cancelled_${DateTime.now().millisecondsSinceEpoch}',
        fromPlace: 'Current Location',
        toPlace: '${widget.destinationName} (Cancelled)',
        distance:
            _distanceCovered, // Use actual distance covered before cancellation
        duration: journeyDuration
            .inMinutes, // Use actual duration before cancellation
        latitude: widget.destinationLocation.latitude,
        longitude: widget.destinationLocation.longitude,
      );

      await historyProvider.addHistoryItem(historyItem);
    } catch (e) {
      debugPrint('Error saving journey cancellation: $e');
      // Don't block the user if history fails to save
    }
  }
}
