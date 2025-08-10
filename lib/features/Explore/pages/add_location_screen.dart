import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';
import 'package:campus_mapper/features/Explore/services/location_service.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'package:campus_mapper/core/services/location_manager.dart';

class AddLocationScreen extends StatefulWidget {
  final LatLng? initialLocation;

  const AddLocationScreen({super.key, this.initialLocation});

  @override
  State<AddLocationScreen> createState() => _AddLocationScreenState();
}

class _AddLocationScreenState extends State<AddLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedCategory = 'Others';
  bool _isLoading = false;
  LatLng? _selectedLocation;

  final List<String> _categories = [
    'Classes',
    'Food & Dining',
    'Study Spaces',
    'Sports & Fitness',
    'Hostels',
    'Offices',
    'ATMs',
    'Pharmacies',
    'Churches',
    'Entertainment',
    'Shopping Centers',
    'Services',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation == null) {
      _getCurrentLocation();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await LocationManager.getCurrentLocation();
      if (position != null) {
        setState(() {
          _selectedLocation = LatLng(position.latitude, position.longitude);
        });
      } else {
        setState(() {
          _selectedLocation = const LatLng(0.0, 0.0);
        });
      }
    } catch (e) {
      // Use default location if current location fails
      setState(() {
        _selectedLocation = const LatLng(0.0, 0.0);
      });
    }
  }

  Future<void> _submitLocation() async {
    if (!_formKey.currentState!.validate() || _selectedLocation == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final locationService = LocationService();
      final historyProvider = Provider.of<UserHistoryProvider>(context, listen: false);
      
      final locationId = await locationService.addLocation(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        description: _descriptionController.text.trim(),
        historyProvider: historyProvider,
      );

      if (locationId != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location added successfully! It will be reviewed and published soon.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Location'),
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submitLocation,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Location Name *',
                  hintText: 'e.g., Central Library, Main Cafeteria',
                  prefixIcon: const Icon(HugeIcons.strokeRoundedLocation01),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a location name';
                  }
                  if (value.trim().length < 3) {
                    return 'Location name must be at least 3 characters';
                  }
                  return null;
                },
                maxLength: 50,
              ),
              const SizedBox(height: 16),

              // Category Selection
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: const Icon(HugeIcons.strokeRoundedTag01),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Additional details about this location',
                  prefixIcon: const Icon(HugeIcons.strokeRoundedNote),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
                maxLength: 200,
              ),
              const SizedBox(height: 16),

              // Location Map
              const Text(
                'Location on Map',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _selectedLocation == null
                      ? const Center(child: CircularProgressIndicator())
                      : GoogleMap(
                          initialCameraPosition: CameraPosition(
                            target: _selectedLocation!,
                            zoom: 16,
                          ),
                          onMapCreated: (controller) {
                            // Map controller can be used for future enhancements
                          },
                          onTap: (LatLng location) {
                            setState(() {
                              _selectedLocation = location;
                            });
                          },
                          markers: _selectedLocation != null
                              ? {
                                  Marker(
                                    markerId: const MarkerId('selected_location'),
                                    position: _selectedLocation!,
                                    icon: BitmapDescriptor.defaultMarkerWithHue(
                                      BitmapDescriptor.hueBlue,
                                    ),
                                  ),
                                }
                              : {},
                        ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap on the map to select the exact location',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 16),

              // Current coordinates display
              if (_selectedLocation != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(HugeIcons.strokeRoundedGps01, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                          'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}