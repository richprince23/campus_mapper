import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {


  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  final _startController = TextEditingController();
  final _endController = TextEditingController();

  // Initial camera position - should be set to campus center
  final CameraPosition _initialPosition = CameraPosition(
    target: LatLng(
      5.362333973912482,
      -0.6331988792927239,
    ), // Example: UEW North campus coordinates
    zoom: 14.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Layer
          GoogleMap(
            initialCameraPosition: _initialPosition,
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            compassEnabled: true,
            zoomControlsEnabled: false,
            buildingsEnabled: true,
            zoomGesturesEnabled: true,
            mapType: MapType.normal,
          ),
        ],
      ),
    );
  }

  Widget _buildTransportOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 28),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // void _getDirections(TravelModes mode) {
  //   // Implement directions logic
  // }

  void _getCurrentLocation() async {
    // Implement location logic
  }

  void _toggleMapLayers() {
    // Implement layer toggle
  }

  void _openExploreView() {
    // Navigate to explore view
  }

  void _openChallengesView() {
    // Navigate to challenges view
  }

  void _openRecentRoutes() {
    // Navigate to recent routes view
  }

  @override
  void dispose() {
    _startController.dispose();
    _endController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
}
