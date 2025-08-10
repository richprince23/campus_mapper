import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/services/user_history_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
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
  Map<String, dynamic> _stats = {};
  
  // Sync status
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  List<UserHistory> get historyItems => _filteredItems;
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;
  String get searchQuery => _searchQuery;
  Map<String, dynamic> get stats => _stats;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  UserHistoryProvider() {
    _loadHistoryWithCache();
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
      
      // Cache the loaded data
      _cacheHistory();
      
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
    final backupStats = Map<String, dynamic>.from(_stats);
    
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

  Future<void> clearAllHistory() async {
    try {
      // Clear all local data
      _historyItems.clear();
      _filteredItems.clear();
      _stats.clear();
      
      // Clear cached data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_history_cache');
      await prefs.remove('user_history_timestamp');
      
      // Clear from Firebase
      await _historyService.clearUserHistory();
      
      notifyListeners();
    } catch (e) {
      log('Error clearing all history: $e');
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

      // Apply search query filter - search across multiple fields
      bool matchesSearch = _searchQuery.isEmpty || _itemMatchesSearch(item, _searchQuery);

      return matchesFilter && matchesSearch;
    }).toList();

    // Sort by timestamp (newest first)
    _filteredItems.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    notifyListeners();
  }
  
  /// Comprehensive search function
  bool _itemMatchesSearch(UserHistory item, String searchQuery) {
    if (searchQuery.isEmpty) return true;
    
    final lowerQuery = searchQuery.toLowerCase();
    
    // Search in display title
    if (item.displayTitle.toLowerCase().contains(lowerQuery)) {
      return true;
    }
    
    // Search in display subtitle
    if (item.displaySubtitle != null && 
        item.displaySubtitle!.toLowerCase().contains(lowerQuery)) {
      return true;
    }
    
    // Search in place name
    final placeName = item.details['place_name']?.toString().toLowerCase() ?? '';
    if (placeName.contains(lowerQuery)) {
      return true;
    }
    
    // Search in category
    final category = item.details['metadata']?['category']?.toString().toLowerCase() ?? '';
    if (category.contains(lowerQuery)) {
      return true;
    }
    
    // Search in search query (for search-type items)
    if (item.actionType == HistoryActionType.searchPerformed) {
      final searchedQuery = item.details['metadata']?['query']?.toString().toLowerCase() ?? '';
      if (searchedQuery.contains(lowerQuery)) {
        return true;
      }
    }
    
    // Search in route details (for journey/route items)
    if (item.actionType == HistoryActionType.journeyCompleted || 
        item.actionType == HistoryActionType.routeCalculated) {
      final fromPlace = item.details['metadata']?['from_place']?.toString().toLowerCase() ?? '';
      if (fromPlace.contains(lowerQuery)) {
        return true;
      }
    }
    
    return false;
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

  // Search within loaded history (now uses local search only for consistency)
  void searchHistory(String searchTerm) {
    _searchQuery = searchTerm;
    _applyFilters();
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
  
  /// Get current user ID for debugging
  Future<String?> getCurrentUserId() async {
    return await _historyService.getCurrentUserId();
  }
  
  /// Reset user session (useful for testing)
  void resetUserSession() {
    _historyService.resetUserId();
    _historyItems.clear();
    _filteredItems.clear();
    _stats.clear();
    _hasError = false;
    _errorMessage = '';
    _lastSyncTime = null;
    _clearCache();
    notifyListeners();
  }

  /// Load history with local caching for offline support
  Future<void> _loadHistoryWithCache() async {
    _isLoading = true;
    _hasError = false;
    _errorMessage = '';
    notifyListeners();

    try {
      // First, try to load from cache for immediate display
      await _loadFromCache();
      
      // Then load from Firestore and sync
      await loadHistory(showLoading: false);
    } catch (e) {
      log('Error loading history with cache: $e');
      _hasError = true;
      _errorMessage = 'Failed to load history. Please check your connection.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cache history items locally
  Future<void> _cacheHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _historyService.getCurrentUserId();
      if (userId == null) return;

      final cacheKey = 'history_cache_$userId';
      final historyJson = _historyItems.map((item) => item.toCacheJson()).toList();
      await prefs.setString(cacheKey, jsonEncode(historyJson));
      
      // Also cache stats
      final statsKey = 'stats_cache_$userId';
      await prefs.setString(statsKey, jsonEncode(_stats));
      
      log('History cached successfully');
    } catch (e) {
      log('Failed to cache history: $e');
    }
  }

  /// Load history from local cache
  Future<void> _loadFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _historyService.getCurrentUserId();
      if (userId == null) return;

      final cacheKey = 'history_cache_$userId';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final List<dynamic> historyJson = jsonDecode(cachedData);
        _historyItems = historyJson.map((json) {
          // Convert cached JSON directly to UserHistory
          return UserHistory.fromCachedJson(json);
        }).toList();
        
        // Load cached stats
        final statsKey = 'stats_cache_$userId';
        final cachedStats = prefs.getString(statsKey);
        if (cachedStats != null) {
          _stats = Map<String, dynamic>.from(jsonDecode(cachedStats));
        }
        
        _applyFilters();
        log('Loaded ${_historyItems.length} items from cache');
      }
    } catch (e) {
      log('Failed to load from cache: $e');
      // If cache loading fails, continue with normal flow
    }
  }

  /// Clear local cache
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = await _historyService.getCurrentUserId();
      if (userId == null) return;

      final cacheKey = 'history_cache_$userId';
      final statsKey = 'stats_cache_$userId';
      
      await prefs.remove(cacheKey);
      await prefs.remove(statsKey);
      
      log('Cache cleared successfully');
    } catch (e) {
      log('Failed to clear cache: $e');
    }
  }
}