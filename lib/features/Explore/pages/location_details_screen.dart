import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class LocationDetailScreen extends StatelessWidget {
  final Location location;

  const LocationDetailScreen({super.key, required this.location});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(location.name ?? 'Location'),
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
                    _getCategoryIcon(location.category),
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
                        label: Text(location.category),
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
                  if (location.description != null) ...[
                    const Text(
                      'About',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(location.description!),
                    const SizedBox(height: 24),
                  ],

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            // Navigate to location
                          },
                          icon: const Icon(HugeIcons.strokeRoundedDirections01),
                          label: const Text('Directions'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Save to favorites
                          },
                          icon: const Icon(HugeIcons.strokeRoundedFavourite),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Map preview
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text('Map Preview'),
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
}
