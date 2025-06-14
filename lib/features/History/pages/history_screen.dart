import 'package:campus_mapper/features/Explore/models/category_item.dart';
import 'package:campus_mapper/features/Explore/models/location.dart';
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
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late SearchProvider _searchProvider;

  @override
  void initState() {
    super.initState();
    _searchProvider = SearchProvider();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _searchProvider.search(widget.initialQuery!);
    }
    _searchProvider.loadPopularSearches();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _searchProvider,
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search locations...',
              border: InputBorder.none,
            ),
            onChanged: (value) {
              _searchProvider.search(value);
            },
            onSubmitted: (value) {
              _searchProvider.search(value);
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(HugeIcons.strokeRoundedMic01),
              onPressed: () {
                // Voice search implementation
              },
            ),
          ],
        ),
        body: Consumer<SearchProvider>(
          builder: (context, provider, child) {
            if (provider.currentQuery.isEmpty) {
              return _buildSearchSuggestions(provider);
            }

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

  Widget _buildSearchSuggestions(SearchProvider provider) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (provider.recentSearches.isNotEmpty) ...[
          const Text(
            'Recent Searches',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: provider.recentSearches.map((search) {
              return ActionChip(
                label: Text(search),
                onPressed: () {
                  _searchController.text = search;
                  provider.search(search);
                },
                avatar: const Icon(HugeIcons.strokeRoundedClock01, size: 16),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Popular Searches',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.popularSearches.map((search) {
            return ActionChip(
              label: Text(search),
              onPressed: () {
                _searchController.text = search;
                provider.search(search);
              },
              avatar:
                  const Icon(HugeIcons.strokeRoundedArrowDiagonal, size: 16),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const Text(
          'Browse Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        _buildCategoryGrid(),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      CategoryItem(
          'Food & Dining', HugeIcons.strokeRoundedRestaurant02, Colors.orange),
      CategoryItem('Study Spaces', HugeIcons.strokeRoundedBook02, Colors.blue),
      CategoryItem(
          'Entertainment', HugeIcons.strokeRoundedParty, Colors.purple),
      CategoryItem(
          'Services', HugeIcons.strokeRoundedCustomerService, Colors.green),
      CategoryItem(
          'Sports & Fitness', HugeIcons.strokeRoundedDumbbell01, Colors.red),
      CategoryItem(
          'Shopping', HugeIcons.strokeRoundedShoppingBag02, Colors.pink),
      CategoryItem('ATMs', HugeIcons.strokeRoundedAtm01, Colors.cyan),
      CategoryItem(
          'Pharmacies', HugeIcons.strokeRoundedMedicineBottle01, Colors.teal),
      CategoryItem(
          'Groceries', HugeIcons.strokeRoundedShoppingBag02, Colors.brown),
      CategoryItem(
          'Bars & Pubs', HugeIcons.strokeRoundedDrink, Colors.deepOrange),
      CategoryItem('Shopping Centers', HugeIcons.strokeRoundedShoppingCart01,
          Colors.amber),
      CategoryItem('Hostels', HugeIcons.strokeRoundedBedBunk, Colors.indigo),
      CategoryItem(
          'Gyms', HugeIcons.strokeRoundedDumbbell01, Colors.lightGreen),
      CategoryItem('Churches', HugeIcons.strokeRoundedChurch, Colors.lime),
      CategoryItem(
          'Printing Services', HugeIcons.strokeRoundedPrinter, Colors.grey),
      CategoryItem('Classes', HugeIcons.strokeRoundedOnlineLearning01,
          Colors.pinkAccent),
      CategoryItem('Offices', HugeIcons.strokeRoundedOffice, Colors.deepPurple),
      CategoryItem('Store', HugeIcons.strokeRoundedStore04, Colors.blueGrey),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 3,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return GestureDetector(
          onTap: () {
            _searchController.text = category.name;
            _searchProvider.search(category.name);
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: category.color.withAlpha(26),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: category.color.withAlpha(77),
              ),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: category.icon,
                  color: category.color,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: category.color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
            'Try searching for something else or browse categories above',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              _searchProvider.clearSearch();
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
                _getCategoryIcon(location.category),
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

  IconData _getCategoryIcon(String category) {
    final categoryMap = {
      'Food': HugeIcons.strokeRoundedRestaurant02,
      'Study': HugeIcons.strokeRoundedBook02,
      'Entertainment': HugeIcons.strokeRoundedParty,
      'Services': HugeIcons.strokeRoundedCustomerService,
      'Sports': HugeIcons.strokeRoundedDumbbell01,
      'Shopping': HugeIcons.strokeRoundedShoppingBag02,
    };

    return categoryMap[category] ?? HugeIcons.strokeRoundedLocation01;
  }
}

// Category item model

// Enhanced location detail screen with more context
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
