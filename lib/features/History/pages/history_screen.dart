import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:campus_mapper/features/Explore/pages/location_details_screen.dart';
import 'package:campus_mapper/features/Explore/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:provider/provider.dart';

// Enhanced search provider with real-time suggestions

// Enhanced search screen with suggestions and filters
class EnhancedSearchScreen extends StatefulWidget {
  final String? initialQuery;

  const EnhancedSearchScreen({super.key, this.initialQuery});

  @override
  State<EnhancedSearchScreen> createState() => _EnhancedSearchScreenState();
}

class _EnhancedSearchScreenState extends State<EnhancedSearchScreen> {
  late SearchProvider _searchProvider;

  @override
  void initState() {
    super.initState();
    _searchProvider = SearchProvider();
    if (widget.initialQuery != null) {
      _searchProvider.search(widget.initialQuery!);
    }
    _searchProvider.loadPopularSearches();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _searchProvider,
      child: Scaffold(
        appBar: AppBar(),
        body: Consumer<SearchProvider>(
          builder: (context, provider, child) {
            // if (provider.currentQuery.isEmpty) {
            //   return _buildSearchSuggestions(provider);
            // }

            if (provider.isSearching) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.searchResults.isEmpty) {
              return _buildNoResults(provider.currentQuery);
            }

            return _buildSearchResults(provider.searchResults);
          },
        ),
      ),
    );
  }

  Widget _buildNoResults(String query) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            HugeIcons.strokeRoundedSearch01,
            size: 64,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found for "$query"',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try searching for something else or browse categories in the previous page',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchProvider.clearSearch();
              Navigator.pop(context);
            },
            child: const Text('Clear Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<Location> results) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final location = results[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                getCategoryIcon(location.category),
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: Text(
              location.name ?? 'Unknown',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(location.category),
                if (location.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    location.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // if (location.rating != null) ...[
                //   Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       const Icon(Icons.star, size: 16, color: Colors.amber),
                //       const SizedBox(width: 2),
                //       Text(location.rating!.toStringAsFixed(1)),
                //     ],
                //   ),
                // ],
                const SizedBox(height: 4),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) =>
                      LocationDetailScreen(location: location),
                ),
              );
            },
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
