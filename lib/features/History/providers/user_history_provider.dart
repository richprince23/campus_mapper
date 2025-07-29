import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/services/user_history_service.dart';
import 'package:flutter/material.dart';

class UserHistoryProvider extends ChangeNotifier {
  final UserHistoryService _historyService = UserHistoryService();
  
  List<UserHistory> _historyItems = [];
  List<UserHistory> _filteredItems = [];
  bool _isLoading = false;
  String _currentFilter = 'all';
  String _searchQuery = '';
  Map<String, int> _stats = {};

  List<UserHistory> get historyItems => _filteredItems;
  bool get isLoading => _isLoading;
  String get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  Map<String, int> get stats => _stats;

  UserHistoryProvider() {
    loadHistory();
  }

  Future<void> loadHistory({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      _historyItems = await _historyService.getUserHistory(limit: 100);
      _stats = await _historyService.getHistoryStats();
      _applyFilters();
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      if (showLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> addHistoryItem(UserHistory item) async {
    try {
      await _historyService.addHistoryEntry(item);
      
      // Add to local list for immediate UI update
      _historyItems.insert(0, item);
      _applyFilters();
      
      // Update stats
      await _loadStats();
    } catch (e) {
      print('Error adding history item: $e');
    }
  }

  Future<void> deleteHistoryItem(String itemId) async {
    try {
      await _historyService.deleteHistoryEntry(itemId);
      _historyItems.removeWhere((item) => item.id == itemId);
      _applyFilters();
      
      // Update stats
      await _loadStats();
    } catch (e) {
      print('Error deleting history item: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _historyService.clearUserHistory();
      _historyItems.clear();
      _filteredItems.clear();
      _stats.clear();
      notifyListeners();
    } catch (e) {
      print('Error clearing history: $e');
    }
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _applyFilters();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void _applyFilters() {
    _filteredItems = _historyItems.where((item) {
      // Apply type filter
      bool matchesFilter = false;
      switch (_currentFilter) {
        case 'all':
          matchesFilter = true;
          break;
        case 'searches':
          matchesFilter = item.actionType == HistoryActionType.searchPerformed;
          break;
        case 'visits':
          matchesFilter = item.actionType == HistoryActionType.placeVisited;
          break;
        case 'journeys':
          matchesFilter = item.actionType == HistoryActionType.journeyCompleted;
          break;
        case 'favorites':
          matchesFilter = item.actionType == HistoryActionType.placeFavorited;
          break;
        case 'routes':
          matchesFilter = item.actionType == HistoryActionType.routeCalculated;
          break;
        case 'places':
          matchesFilter = item.actionType == HistoryActionType.placeAdded;
          break;
      }

      // Apply search query filter
      bool matchesSearch = _searchQuery.isEmpty ||
          item.displayTitle.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.displaySubtitle != null &&
              item.displaySubtitle!.toLowerCase().contains(_searchQuery.toLowerCase()));

      return matchesFilter && matchesSearch;
    }).toList();

    // Sort by timestamp (newest first)
    _filteredItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
  }

  Future<void> _loadStats() async {
    try {
      _stats = await _historyService.getHistoryStats();
      notifyListeners();
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  // Helper methods for quick access
  Future<List<String>> getRecentSearches({int limit = 5}) async {
    try {
      return await _historyService.getRecentSearches(limit: limit);
    } catch (e) {
      print('Error getting recent searches: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentlyVisitedPlaces({int limit = 5}) async {
    try {
      return await _historyService.getRecentlyVisitedPlaces(limit: limit);
    } catch (e) {
      print('Error getting recently visited places: $e');
      return [];
    }
  }

  List<UserHistory> getRecentByType(HistoryActionType actionType, {int limit = 5}) {
    return _historyItems
        .where((item) => item.actionType == actionType)
        .take(limit)
        .toList();
  }

  // Search within loaded history
  Future<void> searchHistory(String searchTerm) async {
    _searchQuery = searchTerm;
    
    if (searchTerm.isEmpty) {
      _applyFilters();
      return;
    }

    try {
      // For comprehensive search, query the service
      final searchResults = await _historyService.searchHistory(searchTerm);
      
      // Update the filtered items with search results
      _filteredItems = searchResults;
      notifyListeners();
    } catch (e) {
      print('Error searching history: $e');
      // Fallback to local search
      _applyFilters();
    }
  }

  // Analytics methods
  Map<HistoryActionType, int> getActionTypeBreakdown() {
    final breakdown = <HistoryActionType, int>{};
    
    for (final item in _historyItems) {
      breakdown[item.actionType] = (breakdown[item.actionType] ?? 0) + 1;
    }
    
    return breakdown;
  }

  List<String> getMostVisitedPlaces({int limit = 10}) {
    final placeVisits = <String, int>{};
    
    for (final item in _historyItems) {
      if (item.actionType == HistoryActionType.placeVisited) {
        final placeName = item.details['place_name'] as String?;
        if (placeName != null) {
          placeVisits[placeName] = (placeVisits[placeName] ?? 0) + 1;
        }
      }
    }
    
    final sortedPlaces = placeVisits.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return sortedPlaces
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  List<String> getMostSearchedTerms({int limit = 10}) {
    final searchCounts = <String, int>{};
    
    for (final item in _historyItems) {
      if (item.actionType == HistoryActionType.searchPerformed) {
        final query = item.details['metadata']?['query'] as String?;
        if (query != null && query.isNotEmpty) {
          searchCounts[query] = (searchCounts[query] ?? 0) + 1;
        }
      }
    }
    
    final sortedSearches = searchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
      
    return sortedSearches
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }
}