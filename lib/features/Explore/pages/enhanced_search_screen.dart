import 'package:campus_mapper/features/Explore/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

class EnhancedSearchScreen extends StatefulWidget {
  final String initialQuery;

  const EnhancedSearchScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen> {
  late SearchProvider _searchProvider;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _searchProvider = Provider.of<SearchProvider>(context, listen: false);
    _searchProvider.setContext(context);
    _performSearch();
  }

  Future<void> _performSearch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _searchProvider.searchByCategory(widget.initialQuery);
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
        title: Text('${widget.initialQuery} Locations'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(HugeIcons.strokeRoundedRefresh),
            onPressed: _performSearch,
          ),
        ],
      ),
      body: Consumer<SearchProvider>(
        builder: (context, searchProvider, child) {
          if (_isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Searching for locations...'),
                ],
              ),
            );
          }

          final results = searchProvider.searchResults;

          if (results.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    HugeIcons.strokeRoundedSearchRemove,
                    size: 64,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${widget.initialQuery.toLowerCase()} locations found',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try searching for a different category or location',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _performSearch,
                    child: const Text('Retry Search'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: results.length,
            itemBuilder: (context, index) {
              final location = results[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(location.category),
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    location.name ?? 'Unknown Location',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (location.category.isNotEmpty == true)
                        Text(
                          location.category,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 12,
                          ),
                        ),
                      if (location.description?.isNotEmpty == true)
                        Text(
                          location.description!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                  trailing: const Icon(HugeIcons.strokeRoundedArrowRight01),
                  onTap: () {
                    // Return the selected location to the calling screen
                    Navigator.pop(context, location);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String? categoryName) {
    final categoryMap = {
      'Classes': HugeIcons.strokeRoundedOnlineLearning01,
      'Study Spaces': HugeIcons.strokeRoundedBook02,
      'Offices': HugeIcons.strokeRoundedOffice,
      'Hostels': HugeIcons.strokeRoundedBedBunk,
      'Printing Services': HugeIcons.strokeRoundedPrinter,
      'Food & Dining': HugeIcons.strokeRoundedRestaurant02,
      'Food': HugeIcons.strokeRoundedRestaurant02,
      'Churches': HugeIcons.strokeRoundedChurch,
      'Pharmacies': HugeIcons.strokeRoundedMedicineBottle01,
      'Entertainment': HugeIcons.strokeRoundedParty,
      'Sports & Fitness': HugeIcons.strokeRoundedDumbbell01,
      'Shopping Centers': HugeIcons.strokeRoundedShoppingCart01,
      'Store': HugeIcons.strokeRoundedStore04,
      'ATMs': HugeIcons.strokeRoundedAtm01,
      'Services': HugeIcons.strokeRoundedCustomerService,
      'Gyms': HugeIcons.strokeRoundedDumbbell01,
    };

    return categoryMap[categoryName ?? ''] ?? HugeIcons.strokeRoundedLocation01;
  }
}