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

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _currentQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _currentQuery = query;
    notifyListeners();

    try {
      final response = await _firestore
          .collection('locations')
          .where('name', isGreaterThanOrEqualTo: query)
          .where('name', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      _searchResults =
          response.docs.map((doc) => Location.fromFirestore(doc)).toList();

      print(_searchResults);
      // Add to recent searches
      if (!_recentSearches.contains(query)) {
        _recentSearches.insert(0, query);
        if (_recentSearches.length > 10) {
          _recentSearches = _recentSearches.take(10).toList();
        }
      }
    } catch (e) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
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

  void clearSearch() {
    _searchResults = [];
    _currentQuery = '';
    notifyListeners();
  }
}
