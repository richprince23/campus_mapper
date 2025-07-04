import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class SearchProvider extends ChangeNotifier {
  // final _supabase = Supabase.instance.client;
  final _firestore = FirebaseFirestore.instance;
  List<Location> _searchResults = [];
  List<String> _recentSearches = [];
  List<String> _popularSearches = [];
  bool _isSearching = false;
  String _currentQuery = '';

  List<Location> get searchResults => _searchResults;
  List<String> get recentSearches => _recentSearches;
  List<String> get popularSearches => _popularSearches;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;

  SearchProvider() {
    loadPopularSearches();
  }

  final Map<String, List<String>> _categoryMappings = {
    'Classes': ['Classes', 'Class', 'Lecture Halls', 'Academic'],
    'Study Spaces': ['Library', 'Study', 'Reading Room', 'Study Spaces'],
    'Offices': ['Office', 'Offices', 'Administration'],
    'Hostels': ['Hostel', 'Hostels', 'Accommodation', 'Residence'],
    'Printing Services': ['Printing', 'Print', 'Photocopy', 'Printing Services'],
    'Food & Dining': ['Food', 'Restaurant', 'Dining', 'Cafeteria', 'Canteen', 'Food & Dining'],
    'Churches': ['Church', 'Churches', 'Religious', 'Chapel'],
    'Pharmacies': ['Pharmacy', 'Pharmacies', 'Medical', 'Health'],
    'Entertainment': ['Entertainment', 'Recreation', 'Fun'],
    'Sports & Fitness': ['Sports', 'Fitness', 'Recreation', 'Athletic', 'Sports & Fitness', 'Gym', 'Gyms'],
    'Shopping Centers': ['Shopping', 'Store', 'Shop', 'Market', 'Shopping Centers'],
    'ATMs': ['ATM', 'ATMs', 'Bank'],
    'Store': ['Store', 'Shop', 'Shopping'],
    'Services': ['Service', 'Services', 'Utility'],
  };

  /// Search ocations by name
  Future<List<Map<String, dynamic>>> searchByName(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _currentQuery = '';
      notifyListeners();
      return [];
    }

    _isSearching = true;
    _currentQuery = query;
    notifyListeners();

    try {
      // Convert query to lowercase for case-insensitive search
      final lowerQuery = query.toLowerCase();

      final response = await _firestore
          .collection('locations')
          .where('name_lower', isGreaterThanOrEqualTo: lowerQuery)
          // .where('name_lower', isLessThanOrEqualTo: '$lowerQuery\uf8ff')
          .limit(10)
          .get();

      print('Search query: $query, Results found: ${response.docs.length}');

      if (response.docs.isEmpty) {
        print('No documents found for query: $query');
        _searchResults = [];
        return [];
      }

      _searchResults =
          response.docs.map((doc) => Location.fromFirestore(doc)).toList();

      // Return formatted data for TypeAheadField
      final results = response.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      }

      return results;
    } catch (e) {
      print('Search error: $e');
      _searchResults = [];
      return [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Filter locations by category
  Future<void> searchByCategory(String category) async {
    if (category.isEmpty) {
      _searchResults = [];
      _currentQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _currentQuery = category;
    notifyListeners();

    try {
      print('Searching for category: "$category"');

      // Get possible category names to search for
      List<String> searchTerms = _categoryMappings[category] ?? [category];

      print('Search terms: $searchTerms');

      List<Location> allResults = [];

      // Search for each possible category name
      for (String term in searchTerms) {
        try {
          final response = await _firestore
              .collection('locations')
              .where('category', isEqualTo: term)
              .get();

          print('Results for "$term": ${response.docs.length} documents');

          final termResults =
              response.docs.map((doc) => Location.fromFirestore(doc)).toList();

          allResults.addAll(termResults);
        } catch (e) {
          print('Error searching for term "$term": $e');
        }
      }

      // Remove duplicates based on ID
      final uniqueResults = <String, Location>{};
      for (var result in allResults) {
        if (result.id != null) {
          uniqueResults[result.id!] = result;
        }
      }

      _searchResults = uniqueResults.values.toList();

      print('Total unique results: ${_searchResults.length}');
      if (_searchResults.isNotEmpty) {
        print('Sample results:');
        for (int i = 0; i < _searchResults.length && i < 3; i++) {
          print(
              '  - ${_searchResults[i].name} (${_searchResults[i].category})');
        }
      }

      // Add to recent searches
      if (!_recentSearches.contains(category)) {
        _recentSearches.insert(0, category);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      }
    } catch (e) {
      print('Category search error: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> searchByCategoryFlexible(String category) async {
    if (category.isEmpty) {
      _searchResults = [];
      _currentQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _currentQuery = category;
    notifyListeners();

    try {
      print('Flexible search for category: "$category"');

      // Get all documents and filter client-side for case-insensitive search
      final response = await _firestore.collection('locations').get();

      final results = response.docs
          .where((doc) {
            final data = doc.data();
            final docCategory =
                data['category']?.toString().toLowerCase() ?? '';
            final searchCategory = category.toLowerCase();

            // Check if category contains the search term or vice versa
            return docCategory.contains(searchCategory) ||
                searchCategory.contains(docCategory);
          })
          .map((doc) => Location.fromFirestore(doc))
          .toList();

      _searchResults = results;

      print('Flexible search results: ${_searchResults.length}');
      if (_searchResults.isNotEmpty) {
        print('Categories found:');
        final foundCategories =
            _searchResults.map((r) => r.category).toSet().toList();
        for (var cat in foundCategories) {
          print('  - "$cat"');
        }
      }

      // Add to recent searches
      if (!_recentSearches.contains(category)) {
        _recentSearches.insert(0, category);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      }
    } catch (e) {
      print('Flexible category search error: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<void> debugFirestoreData() async {
    try {
      // Get all documents to see the structure
      final allDocs = await _firestore.collection('locations').limit(5).get();

      print('=== FIRESTORE DEBUG ===');
      print('Total documents in collection: ${allDocs.docs.length}');

      for (var doc in allDocs.docs) {
        print('Document ID: ${doc.id}');
        print('Document data: ${doc.data()}');
        print('---');
      }

      // Check specific category
      final categoryDocs = await _firestore
          .collection('locations')
          .where('category', isEqualTo: 'ATMs')
          .limit(3)
          .get();

      print('Documents with category "ATMs": ${categoryDocs.docs.length}');
      for (var doc in categoryDocs.docs) {
        print('Class document: ${doc.data()}');
      }

      print('=== END DEBUG ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  Future<void> loadPopularSearches() async {
    // This would typically come from analytics or user behavior data
    _popularSearches = [
      'Coffee',
      'Study spots',
      'Food',
      'ATM',
      'Library',
      'Gym',
      'Parking',
      'Restaurants',
    ];
    notifyListeners();
  }

  Future<void> checkCollectionExists() async {
    try {
      print('=== CHECKING COLLECTION NAME ===');

      // Try different possible collection names
      final possibleNames = [
        'locations',
        'Locations',
        'location',
        'Location',
        'places',
        'Places'
      ];

      for (String name in possibleNames) {
        try {
          final snapshot = await _firestore.collection(name).limit(1).get();
          print('📂 Collection "$name": ${snapshot.docs.length} documents');

          if (snapshot.docs.isNotEmpty) {
            print('✅ Found data in collection: "$name"');
            print('📄 Sample document: ${snapshot.docs.first.data()}');
          }
        } catch (e) {
          print('❌ Error accessing collection "$name": $e');
        }
      }

      // List all collections (if you have admin access)
      print('\n=== ATTEMPTING TO LIST ALL COLLECTIONS ===');
      // Note: This usually requires admin SDK, not available in Flutter
      print('💡 Manually check Firebase Console for collection names');
    } catch (e) {
      print('❌ Collection check error: $e');
    }
  }

  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    notifyListeners();
  }
}
