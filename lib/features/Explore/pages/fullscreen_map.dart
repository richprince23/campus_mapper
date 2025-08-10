import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:campus_mapper/features/Explore/providers/map_provider.dart';

class FullscreenMapScreen extends StatefulWidget {
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final LatLng? initialCameraPosition;
  final double initialZoom;

  const FullscreenMapScreen({
    super.key,
    required this.markers,
    required this.polylines,
    this.initialCameraPosition,
    this.initialZoom = 13.0,
  });

  @override
  State<FullscreenMapScreen> createState() => _FullscreenMapScreenState();
}

class _FullscreenMapScreenState extends State<FullscreenMapScreen> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fullscreen Google Map
          Consumer<MapProvider>(
            builder: (context, mapProvider, child) {
              return GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: widget.initialCameraPosition ?? 
                      const LatLng(5.362312610147424, -0.633134506275042),
                  zoom: widget.initialZoom,
                ),
                mapType: mapProvider.currentMapType,
                myLocationButtonEnabled: false, // We'll add our own
                myLocationEnabled: true,
                markers: widget.markers,
                polylines: widget.polylines,
                onMapCreated: (controller) {
                  _mapController = controller;
                },
                zoomControlsEnabled: false,
                compassEnabled: true,
                rotateGesturesEnabled: true,
                scrollGesturesEnabled: true,
                tiltGesturesEnabled: true,
                zoomGesturesEnabled: true,
              );
            },
          ),

          // Top controls bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Back button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black87,
                    ),
                    tooltip: 'Exit fullscreen',
                  ),
                ),

                // Map type selector
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: PopupMenuButton<MapType>(
                    icon: const Icon(
                      HugeIcons.strokeRoundedLayers01,
                      color: Colors.black87,
                    ),
                    tooltip: 'Map type',
                    onSelected: (MapType type) {
                      // Update map type through MapProvider
                      final mapProvider = Provider.of<MapProvider>(context, listen: false);
                      mapProvider.setMapType(type);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: MapType.normal,
                        child: Row(
                          children: [
                            Icon(Icons.map),
                            SizedBox(width: 8),
                            Text('Normal'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: MapType.satellite,
                        child: Row(
                          children: [
                            Icon(Icons.satellite),
                            SizedBox(width: 8),
                            Text('Satellite'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: MapType.hybrid,
                        child: Row(
                          children: [
                            Icon(Icons.layers),
                            SizedBox(width: 8),
                            Text('Hybrid'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: MapType.terrain,
                        child: Row(
                          children: [
                            Icon(Icons.terrain),
                            SizedBox(width: 8),
                            Text('Terrain'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 24,
            right: 16,
            child: Column(
              children: [
                // My location button
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _goToCurrentLocation,
                    icon: const Icon(
                      HugeIcons.strokeRoundedGps01,
                      color: Colors.blue,
                    ),
                    tooltip: 'My location',
                  ),
                ),

                // Zoom controls
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(51),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        onPressed: _zoomIn,
                        icon: const Icon(
                          Icons.add,
                          color: Colors.black87,
                        ),
                        tooltip: 'Zoom in',
                      ),
                      Container(
                        height: 1,
                        width: 32,
                        color: Colors.grey.shade300,
                      ),
                      IconButton(
                        onPressed: _zoomOut,
                        icon: const Icon(
                          Icons.remove,
                          color: Colors.black87,
                        ),
                        tooltip: 'Zoom out',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goToCurrentLocation() async {
    if (_mapController != null) {
      final mapProvider = Provider.of<MapProvider>(context, listen: false);
      final currentLocation = mapProvider.currentUserLocation;
      
      if (currentLocation != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(currentLocation, 16.0),
        );
      }
    }
  }

  void _zoomIn() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.zoomIn(),
      );
    }
  }

  void _zoomOut() async {
    if (_mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.zoomOut(),
      );
    }
  }
}