import 'dart:async';
import 'package:campus_mapper/features/Explore/models/location.dart';
import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'package:campus_mapper/features/Auth/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

class SearchProvider extends ChangeNotifier {
  // final _supabase = Supabase.instance.client;
  final _firestore = FirebaseFirestore.instance;
  List<Location> _searchResults = [];
  List<String> _recentSearches = [];
  List<String> _popularSearches = [];
  bool _isSearching = false;
  String _currentQuery = '';
  BuildContext? _context;
  Timer? _debounceTimer;
  
  // Search configuration
  static const int _minSearchLength = 3; // Minimum non-space characters required
  static const Duration _debounceDelay = Duration(milliseconds: 500); // Delay before search execution

  List<Location> get searchResults => _searchResults;
  List<String> get recentSearches => _recentSearches;
  List<String> get popularSearches => _popularSearches;
  bool get isSearching => _isSearching;
  String get currentQuery => _currentQuery;

  SearchProvider() {
    loadPopularSearches();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void setContext(BuildContext context) {
    _context = context;
  }

  Future<String?> _getUserUniversityId() async {
    if (_context == null) return null;
    
    try {
      final authProvider = Provider.of<AuthProvider>(_context!, listen: false);
      if (!authProvider.isLoggedIn) return null;
      
      final userProfile = await authProvider.getUserProfile();
      return userProfile?['university_id'];
    } catch (e) {
      print('Error getting user university: $e');
      return null;
    }
  }

  Future<void> _addToHistory(String query, {String? category, int? resultsCount}) async {
    if (_context != null) {
      final historyProvider = Provider.of<UserHistoryProvider>(_context!, listen: false);
      
      // Get the actual user ID from the history service
      final userId = await historyProvider.getCurrentUserId();
      if (userId != null) {
        final historyItem = UserHistory.searchPerformed(
          userId: userId,
          searchQuery: query,
          category: category,
          resultsCount: resultsCount,
        );
        historyProvider.addHistoryItem(historyItem);
      }
    }
  }

  final Map<String, List<String>> _categoryMappings = {
    'Classes': ['Classes', 'Class', 'Lecture Halls', 'Academic'],
    'Study Spaces': ['Library', 'Study', 'Reading Room', 'Study Spaces'],
    'Offices': ['Office', 'Offices', 'Administration'],
    'Hostels': ['Hostel', 'Hostels', 'Accommodation', 'Residence'],
    'Printing Services': [
      'Printing',
      'Print',
      'Photocopy',
      'Printing Services'
    ],
    'Food & Dining': [
      'Food',
      'Restaurant',
      'Dining',
      'Cafeteria',
      'Canteen',
      'Food & Dining'
    ],
    'Churches': ['Church', 'Churches', 'Religious', 'Chapel'],
    'Pharmacies': ['Pharmacy', 'Pharmacies', 'Medical', 'Health'],
    'Entertainment': ['Entertainment', 'Recreation', 'Fun'],
    'Sports & Fitness': [
      'Sports',
      'Fitness',
      'Recreation',
      'Athletic',
      'Sports & Fitness',
      'Gym',
      'Gyms'
    ],
    'Shopping Centers': [
      'Shopping',
      'Store',
      'Shop',
      'Market',
      'Shopping Centers'
    ],
    'ATMs': ['ATM', 'ATMs', 'Bank'],
    'Store': ['Store', 'Shop', 'Shopping'],
    'Services': ['Service', 'Services', 'Utility'],
  };

  /// Search locations by name with debouncing
  Future<List<Map<String, dynamic>>> searchByName(String query) async {
    // Cancel previous timer if it exists
    _debounceTimer?.cancel();
    
    // Update current query immediately for UI
    _currentQuery = query;
    
    // Clear results if query is empty or too short
    if (query.isEmpty || _getNonSpaceCharCount(query) < _minSearchLength) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return [];
    }

    // Set loading state
    _isSearching = true;
    notifyListeners();

    // Create a completer to handle the async debouncing
    final completer = Completer<List<Map<String, dynamic>>>();
    
    // Start debounce timer
    _debounceTimer = Timer(_debounceDelay, () async {
      try {
        final results = await _performSearch(query);
        completer.complete(results);
      } catch (e) {
        completer.completeError(e);
      }
    });
    
    return completer.future;
  }

  /// Count non-space characters in query
  int _getNonSpaceCharCount(String query) {
    return query.replaceAll(' ', '').length;
  }

  /// Perform the actual search
  Future<List<Map<String, dynamic>>> _performSearch(String query) async {
    try {
      // Convert query to lowercase for case-insensitive search
      final lowerQuery = query.toLowerCase();
      
      // Get user's university
      final universityId = await _getUserUniversityId();

      Query firestoreQuery = _firestore.collection('locations');
      
      // Filter by university if user is logged in and has a university
      if (universityId != null) {
        firestoreQuery = firestoreQuery.where('university_id', isEqualTo: universityId);
      }
      
      final response = await firestoreQuery
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
      final results = <Map<String, dynamic>>[];
      for (final doc in response.docs) {
        final data = doc.data();
        final result = <String, dynamic>{
          'id': doc.id,
        };
        if (data is Map<String, dynamic>) {
          result.addAll(data);
        }
        results.add(result);
      }

      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      }

      // Add to history
      _addToHistory(query, resultsCount: results.length).catchError((e) {
        print('Failed to add search to history: $e');
      });

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

      // Get user's university
      final universityId = await _getUserUniversityId();

      // Get possible category names to search for
      List<String> searchTerms = _categoryMappings[category] ?? [category];

      print('Search terms: $searchTerms');

      List<Location> allResults = [];

      // Search for each possible category name
      for (String term in searchTerms) {
        try {
          Query firestoreQuery = _firestore.collection('locations');
          
          // Filter by university if user is logged in and has a university
          if (universityId != null) {
            firestoreQuery = firestoreQuery.where('university_id', isEqualTo: universityId);
          }
          
          final response = await firestoreQuery
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

      // Add to history
      _addToHistory(category, category: category, resultsCount: _searchResults.length).catchError((e) {
        print('Failed to add category search to history: $e');
      });
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

      // Get user's university
      final universityId = await _getUserUniversityId();

      Query firestoreQuery = _firestore.collection('locations');
      
      // Filter by university if user is logged in and has a university
      if (universityId != null) {
        firestoreQuery = firestoreQuery.where('university_id', isEqualTo: universityId);
      }

      // Get all documents and filter client-side for case-insensitive search
      final response = await firestoreQuery.get();

      final results = response.docs
          .where((doc) {
            final data = doc.data();
            final docCategory = data is Map<String, dynamic>
                ? (data['category']?.toString().toLowerCase() ?? '')
                : '';
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

      // Add to history
      _addToHistory(category, category: category, resultsCount: _searchResults.length).catchError((e) {
        print('Failed to add flexible category search to history: $e');
      });
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

  /// Get search suggestions with debouncing (for TypeAheadField)
  Future<List<Map<String, dynamic>>> getSuggestions(String pattern) async {
    // Return empty list immediately if pattern is empty or too short
    if (pattern.isEmpty || _getNonSpaceCharCount(pattern) < _minSearchLength) {
      return [];
    }

    // Update current query for UI consistency
    _currentQuery = pattern;

    // If the same query is already being processed, return existing future
    if (_debounceTimer != null && _debounceTimer!.isActive) {
      _debounceTimer!.cancel();
    }
    
    // Create completer for debounced response
    final completer = Completer<List<Map<String, dynamic>>>();
    
    // Start debounce timer
    _debounceTimer = Timer(_debounceDelay, () async {
      try {
        final results = await _performSearch(pattern);
        completer.complete(results);
      } catch (e) {
        print('Suggestion search error: $e');
        completer.complete([]);
      }
    });
    
    return completer.future;
  }

  void clearSearch() {
    _debounceTimer?.cancel();
    _searchResults = [];
    _currentQuery = '';
    _isSearching = false;
    notifyListeners();
  }
}
