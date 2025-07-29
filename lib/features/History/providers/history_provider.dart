import 'package:campus_mapper/features/History/models/history_item.dart';
import 'package:campus_mapper/features/History/services/history_service.dart';
import 'package:flutter/material.dart';

class HistoryProvider extends ChangeNotifier {
  final HistoryService _historyService = HistoryService();
  
  List<HistoryItem> _historyItems = [];
  List<HistoryItem> _filteredItems = [];
  bool _isLoading = false;
  String _currentFilter = 'all';
  String _searchQuery = '';

  List<HistoryItem> get historyItems => _filteredItems;
  bool get isLoading => _isLoading;
  String get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;

  HistoryProvider() {
    loadHistory();
  }

  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _historyItems = await _historyService.getHistory();
      _applyFilters();
    } catch (e) {
      print('Error loading history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addHistoryItem(HistoryItem item) async {
    try {
      await _historyService.addHistoryItem(item);
      _historyItems.insert(0, item);
      _applyFilters();
    } catch (e) {
      print('Error adding history item: $e');
    }
  }

  Future<void> deleteHistoryItem(String itemId) async {
    try {
      await _historyService.deleteHistoryItem(itemId);
      _historyItems.removeWhere((item) => item.id == itemId);
      _applyFilters();
    } catch (e) {
      print('Error deleting history item: $e');
    }
  }

  Future<void> clearHistory() async {
    try {
      await _historyService.clearHistory();
      _historyItems.clear();
      _filteredItems.clear();
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
        case 'search':
          matchesFilter = item.type == HistoryType.search;
          break;
        case 'navigation':
          matchesFilter = item.type == HistoryType.navigation;
          break;
        case 'locations':
          matchesFilter = item.type == HistoryType.locationView;
          break;
      }

      // Apply search query filter
      bool matchesSearch = _searchQuery.isEmpty ||
          item.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item.subtitle != null &&
              item.subtitle!.toLowerCase().contains(_searchQuery.toLowerCase()));

      return matchesFilter && matchesSearch;
    }).toList();

    // Sort by timestamp (newest first)
    _filteredItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
  }

  List<HistoryItem> getRecentSearches({int limit = 5}) {
    return _historyItems
        .where((item) => item.type == HistoryType.search)
        .take(limit)
        .toList();
  }

  List<HistoryItem> getRecentNavigations({int limit = 5}) {
    return _historyItems
        .where((item) => item.type == HistoryType.navigation)
        .take(limit)
        .toList();
  }

  List<String> getFrequentCategories({int limit = 10}) {
    final categoryCount = <String, int>{};
    
    for (final item in _historyItems) {
      if (item.category != null) {
        categoryCount[item.category!] = (categoryCount[item.category!] ?? 0) + 1;
      }
    }
    
    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedCategories
        .take(limit)
        .map((entry) => entry.key)
        .toList();
  }

  Map<String, int> getHistoryStats() {
    final stats = <String, int>{
      'total': _historyItems.length,
      'searches': 0,
      'navigations': 0,
      'locationViews': 0,
    };

    for (final item in _historyItems) {
      switch (item.type) {
        case HistoryType.search:
          stats['searches'] = stats['searches']! + 1;
          break;
        case HistoryType.navigation:
          stats['navigations'] = stats['navigations']! + 1;
          break;
        case HistoryType.locationView:
          stats['locationViews'] = stats['locationViews']! + 1;
          break;
      }
    }

    return stats;
  }
}