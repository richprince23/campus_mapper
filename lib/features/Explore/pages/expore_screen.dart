// lib/features/Explore/screens/explore_screen.dart
import 'dart:developer';

import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:campus_mapper/features/Explore/providers/map_provider.dart';
import 'package:campus_mapper/core/api/supabase_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _supabase = Supabase.instance.client;
  Location? selectedPlace;
  late GoogleMapController _mapController;

  @override
  void initState() {
    super.initState();
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
                  TypeAheadField<Map<String, dynamic>>(
                    suggestionsCallback: (pattern) async {
                      if (pattern.length < 2) return [];

                      // Use Supabase to search for locations
                      final response = await _supabase
                          .from('locations')
                          .select()
                          .ilike('name', '%$pattern%');

                      log(response.toString());
                      if (response.isEmpty) {
                        log('Error: An error occured');
                        return [];
                      }

                      return (response as List)
                          .map((item) => item as Map<String, dynamic>)
                          .toList();
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
                        context.read<MapProvider>().addMarker(selectedPlace!);
                        _mapController.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              selectedPlace!.location['latitude'],
                              selectedPlace!.location['longitude'],
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
            // height: MediaQuery.sizeOf(context).height - 80,
            child: Stack(
              fit: StackFit.loose,
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(5.362312610147424, -0.633134506275042),
                    zoom: 13,
                  ),
                  mapType: MapType.normal,
                  myLocationButtonEnabled: true,
                  myLocationEnabled: true,
                  markers: context
                      .watch<MapProvider>()
                      .markers, // Use watch instead of read
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  zoomControlsEnabled: false, // Reduce initial map features
                  compassEnabled: false,
                ),
                // Categories Panel
                DraggableScrollableSheet(
                  snap: true,
                  snapSizes: [0.3, 1],
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
                        shrinkWrap: true,
                        children: [
                          // const SizedBox(height: 8),
                          Text("Explore more"),
                          Align(
                            alignment: Alignment.center,
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
      onTap: () async {
        // Load locations by category
        final response = await _supabase
            .from('locations')
            .select()
            .eq('category', title)
            .limit(20);

        if (response == null) {
          log('Error loading category: An error occured');
          return;
        }

        // Clear previous markers
        context.read<MapProvider>().clearMarkers();

        // Add markers for all locations in this category
        final locations = (response as List)
            .map((item) => Location.fromJson(item as Map<String, dynamic>))
            .toList();

        for (var location in locations) {
          context.read<MapProvider>().addMarker(location);
        }

        // Fit map to show all markers if there are any
        if (locations.isNotEmpty) {
          // Use the first location to center the map
          _mapController.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(
                locations.first.location['latitude'],
                locations.first.location['longitude'],
              ),
              14,
            ),
          );
        }
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
