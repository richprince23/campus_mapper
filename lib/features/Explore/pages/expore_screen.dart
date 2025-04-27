// lib/widgets/custom_navbar.dart
import 'dart:developer';

import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:campus_mapper/features/Explore/providers/map_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

// lib/screens/directions_screen.dart
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Location? selectedPlace;

  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
    // Provider.of<MapProvider>(context, listen: false).markers;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MapProvider>(context, listen: false).clearMarkers();
    });
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
          // Search Bar and Categories
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search Bar
                  TypeAheadField(
                    suggestionsCallback: (pattern) async {
                      QuerySnapshot snapshot = await _firestore
                          .collection("locations")
                          .where('name', isGreaterThanOrEqualTo: pattern)
                          .where('name',
                              isLessThanOrEqualTo:
                                  '${pattern}z') // Case-insensitive search
                          .get();

                      return snapshot.docs
                          .map((doc) => doc)
                          .toList(); // Return list of docs
                    },
                    itemBuilder: (context, DocumentSnapshot doc) {
                      Map<String, dynamic> data =
                          doc.data() as Map<String, dynamic>;
                      return ListTile(
                        title: Text(
                          data['name'],
                        ), // Display location name
                        subtitle: Text(
                          data['category'],
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                        leading: Icon(
                          getCategoryIcon(data['category']),
                        ),
                      );
                    },
                    onSelected: (DocumentSnapshot doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      var loc = data['location'] as GeoPoint;
                      log(loc.latitude.toString());
                      setState(() {
                        selectedPlace = Location.fromJson(doc.data()
                            as Map<String, dynamic>); // Save selected place
                        context.read<MapProvider>().addMarker(selectedPlace!);
                        _mapController.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              selectedPlace!.location.latitude,
                              selectedPlace!.location.longitude,
                            ),
                            17,
                          ),
                        );
                      });
                    },
                    builder: (context, textController, focusNode) {
                      return TextField(
                        controller: textController,
                        focusNode: focusNode,
                        decoration: InputDecoration(
                          hintText: 'Where to?',
                          prefixIcon:
                              const Icon(HugeIcons.strokeRoundedSearch01),
                          suffixIcon: const Icon(Icons.mic),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
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
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(5.362312610147424,
                        -0.633134506275042), // San Francisco coordinates
                    zoom: 13,
                  ),
                  mapType: MapType.normal,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  markers: context.read<MapProvider>().markers,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                // Categories Panel
                DraggableScrollableSheet(
                  initialChildSize: 0.3,
                  minChildSize: 0.1,
                  maxChildSize: 1,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: ListView(
                        controller: scrollController,
                        children: [
                          const SizedBox(height: 8),
                          Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          _buildCategoryList(),
                        ],
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

  Widget _buildCategoryList() {
    final categories = [
      ('ATMs', HugeIcons.strokeRoundedAtm01),
      ('Pharmacies', HugeIcons.strokeRoundedMedicineBottle01),
      ('Groceries', HugeIcons.strokeRoundedShoppingBag02),
      ('Bars & Pubs', HugeIcons.strokeRoundedDrink),
      ('Shopping centers', HugeIcons.strokeRoundedShoppingCart01),
      ('Hostels', HugeIcons.strokeRoundedBedBunk),
      ('Gyms', HugeIcons.strokeRoundedDumbbell01),
      ('Churches', HugeIcons.strokeRoundedChurch),
      ('Printing Services', HugeIcons.strokeRoundedPrinter),
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTab('CATEGORIES', true),
              _buildTab('FAVORITES', false),
            ],
          ),
        ),
        ...categories
            .map((category) => _buildCategoryTile(category.$1, category.$2)),
      ],
    );
  }

  Widget _buildTab(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryTile(String title, IconData icon) {
    return ListTile(
      leading: HugeIcon(
        icon: icon,
        color: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.inverseSurface,
        ),
      ),
      onTap: () {
        // Navigate to the category pages
      },
    );
  }

  IconData getCategoryIcon(String categoryName) {
    final categoryMap = {
      'ATMs': HugeIcons.strokeRoundedAtm01,
      'Pharmacies': HugeIcons.strokeRoundedMedicineBottle01,
      'Groceries': HugeIcons.strokeRoundedShoppingBag02,
      'Bars & Pubs': HugeIcons.strokeRoundedDrink,
      'Shopping centers': HugeIcons.strokeRoundedShoppingCart01,
      'Hostels': HugeIcons.strokeRoundedBedBunk,
      'Gyms': HugeIcons.strokeRoundedDumbbell01,
      'Churches': HugeIcons.strokeRoundedChurch,
      'Printing Services': HugeIcons.strokeRoundedPrinter,
    };

    return categoryMap[categoryName] ??
        Icons.help_outline; // Default icon if not found
  }
}
