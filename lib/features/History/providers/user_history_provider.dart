import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/services/user_history_service.dart';
import 'package:flutter/material.dart';
import 'dart:developer' show log;

class UserHistoryProvider extends ChangeNotifier {
  final UserHistoryService _historyService = UserHistoryService();
  
  List<UserHistory> _historyItems = [];
  List<UserHistory> _filteredItems = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  String _currentFilter = 'all';
  String _searchQuery = '';
  Map<String, int> _stats = {};
  
  // Sync status
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  List<UserHistory> get historyItems => _filteredItems;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  Map<String, int> get stats => _stats;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  UserHistoryProvider() {
    loadHistory();
  }

  Future<void> loadHistory({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
      notifyListeners();
    }

    try {
      _isSyncing = true;
      notifyListeners();
      
      _historyItems = await _historyService.getUserHistory(limit: 100);
      _stats = await _historyService.getHistoryStats();
      _lastSyncTime = DateTime.now();
      _applyFilters();
      
      _hasError = false;
      _errorMessage = '';
    } catch (e) {
      log('Error loading history: $e');
      _hasError = true;
      _errorMessage = 'Failed to load history. Please check your connection.';
    } finally {
      _isSyncing = false;
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> addHistoryItem(UserHistory item) async {
    try {
      // Add to local list for immediate UI update
      _historyItems.insert(0, item);
      _applyFilters();
      
      // Sync to Firebase in background
      _syncInBackground(() => _historyService.addHistoryEntry(item));
      
      // Update stats
      await _loadStats();
    } catch (e) {
      log('Error adding history item: $e');
      // Remove from local list if sync fails
      _historyItems.removeWhere((h) => h.timestamp == item.timestamp);
      _applyFilters();
      rethrow;
    }
  }

  Future<void> deleteHistoryItem(String itemId) async {
    // Find and backup the item in case we need to restore it
    UserHistory? backupItem;
    final itemIndex = _historyItems.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      backupItem = _historyItems[itemIndex];
    }
    
    try {
      // Remove from local list for immediate UI update
      _historyItems.removeWhere((item) => item.id == itemId);
      _applyFilters();
      
      // Sync deletion to Firebase
      await _historyService.deleteHistoryEntry(itemId);
      
      // Update stats
      await _loadStats();
    } catch (e) {
      log('Error deleting history item: $e');
      
      // Restore the item if deletion failed
      if (backupItem != null && itemIndex != -1) {
        _historyItems.insert(itemIndex, backupItem);
        _applyFilters();
      }
      
      rethrow;
    }
  }

  Future<void> clearHistory() async {
    // Backup current items in case we need to restore
    final backupItems = List<UserHistory>.from(_historyItems);
    final backupStats = Map<String, int>.from(_stats);
    
    try {
      // Clear local data for immediate UI update
      _historyItems.clear();
      _filteredItems.clear();
      _stats.clear();
      notifyListeners();
      
      // Sync clearing to Firebase
      await _historyService.clearUserHistory();
    } catch (e) {
      log('Error clearing history: $e');
      
      // Restore data if clearing failed
      _historyItems = backupItems;
      _stats = backupStats;
      _applyFilters();
      
      rethrow;
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
      log('Error loading stats: $e');
    }
  }

  // Helper methods for quick access
  Future<List<String>> getRecentSearches({int limit = 5}) async {
    try {
      return await _historyService.getRecentSearches(limit: limit);
    } catch (e) {
      log('Error getting recent searches: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getRecentlyVisitedPlaces({int limit = 5}) async {
    try {
      return await _historyService.getRecentlyVisitedPlaces(limit: limit);
    } catch (e) {
      log('Error getting recently visited places: $e');
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
      log('Error searching history: $e');
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
  
  /// Sync operation in background without blocking UI
  void _syncInBackground(Future<void> Function() operation) {
    operation().catchError((e) {
      log('Background sync failed: $e');
      // Could implement retry logic here
    });
  }
  
  /// Force refresh from Firebase
  Future<void> refreshFromFirebase() async {
    await loadHistory(showLoading: true);
  }
  
  /// Get sync status message
  String getSyncStatusMessage() {
    if (_isSyncing) {
      return 'Syncing...';
    } else if (_hasError) {
      return 'Sync failed';
    } else if (_lastSyncTime != null) {
      final now = DateTime.now();
      final difference = now.difference(_lastSyncTime!);
      if (difference.inMinutes < 1) {
        return 'Synced just now';
      } else if (difference.inHours < 1) {
        return 'Synced ${difference.inMinutes}m ago';
      } else {
        return 'Synced ${difference.inHours}h ago';
      }
    } else {
      return 'Not synced';
    }
  }
}