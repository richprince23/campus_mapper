import 'package:flutter/material.dart';
import 'package:campus_mapper/features/Explore/models/location_approval.dart';
import 'package:campus_mapper/features/Explore/services/location_approval_service.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'dart:developer' show log;

class LocationApprovalProvider extends ChangeNotifier {
  final LocationApprovalService _approvalService = LocationApprovalService();
  
  // State management
  List<LocationApproval> _pendingApprovals = [];
  List<LocationApproval> _userAddedLocations = [];
  List<LocationApproval> _userApprovedLocations = [];
  Map<String, int> _approvalStats = {};
  
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  
  String? _currentUserId;
  
  // Getters
  List<LocationApproval> get pendingApprovals => _pendingApprovals;
  List<LocationApproval> get userAddedLocations => _userAddedLocations;
  List<LocationApproval> get userApprovedLocations => _userApprovedLocations;
  Map<String, int> get approvalStats => _approvalStats;
  
  bool get isLoading => _isLoading;
  bool get hasError => _hasError;
  String get errorMessage => _errorMessage;
  String? get currentUserId => _currentUserId;
  
  // Computed getters
  int get pendingCount => _pendingApprovals.length;
  int get addedCount => _userAddedLocations.length;
  int get approvedCount => _userApprovedLocations.length;
  int get verifiedCount => _userAddedLocations.where((loc) => loc.isVerified).length;

  /// Initialize provider with user ID
  Future<void> initialize(String userId) async {
    if (_currentUserId == userId) return; // Already initialized
    
    _currentUserId = userId;
    await loadAllData();
  }

  /// Load all approval data
  Future<void> loadAllData() async {
    if (_currentUserId == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      // Load data in parallel
      await Future.wait([
        loadPendingApprovals(),
        loadUserAddedLocations(),
        loadUserApprovedLocations(),
        loadApprovalStats(),
      ]);
    } catch (e) {
      _setError('Failed to load approval data: ${e.toString()}');
      log('Error loading approval data: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load pending approvals for the user to vote on
  Future<void> loadPendingApprovals() async {
    if (_currentUserId == null) return;
    
    try {
      _pendingApprovals = await _approvalService.getPendingApprovals(
        currentUserId: _currentUserId!,
        limit: 50,
      );
      
      log('Loaded ${_pendingApprovals.length} pending approvals');
      notifyListeners();
    } catch (e) {
      log('Error loading pending approvals: $e');
      rethrow;
    }
  }

  /// Load locations added by the current user
  Future<void> loadUserAddedLocations() async {
    if (_currentUserId == null) return;
    
    try {
      _userAddedLocations = await _approvalService.getUserAddedLocations(_currentUserId!);
      
      log('Loaded ${_userAddedLocations.length} user added locations');
      notifyListeners();
    } catch (e) {
      log('Error loading user added locations: $e');
      rethrow;
    }
  }

  /// Load locations approved by the current user
  Future<void> loadUserApprovedLocations() async {
    if (_currentUserId == null) return;
    
    try {
      _userApprovedLocations = await _approvalService.getUserApprovedLocations(_currentUserId!);
      
      log('Loaded ${_userApprovedLocations.length} user approved locations');
      notifyListeners();
    } catch (e) {
      log('Error loading user approved locations: $e');
      rethrow;
    }
  }

  /// Load approval statistics
  Future<void> loadApprovalStats() async {
    if (_currentUserId == null) return;
    
    try {
      _approvalStats = await _approvalService.getUserApprovalStats(_currentUserId!);
      
      log('Loaded approval stats: $_approvalStats');
      notifyListeners();
    } catch (e) {
      log('Error loading approval stats: $e');
      rethrow;
    }
  }

  /// Approve a location
  Future<bool> approveLocation({
    required String approvalId,
    String? comment,
    UserHistoryProvider? historyProvider,
  }) async {
    if (_currentUserId == null) return false;
    
    try {
      _clearError();
      
      await _approvalService.approveLocation(
        approvalId: approvalId,
        userId: _currentUserId!,
        comment: comment,
        historyProvider: historyProvider,
      );

      // Remove from pending list and update stats
      _pendingApprovals.removeWhere((approval) => approval.id == approvalId);
      
      // Reload data to get updated counts
      await Future.wait([
        loadUserApprovedLocations(),
        loadApprovalStats(),
      ]);

      log('Successfully approved location: $approvalId');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to approve location: ${e.toString()}');
      log('Error approving location: $e');
      return false;
    }
  }

  /// Reject a location
  Future<bool> rejectLocation({
    required String approvalId,
    String? comment,
    UserHistoryProvider? historyProvider,
  }) async {
    if (_currentUserId == null) return false;
    
    try {
      _clearError();
      
      await _approvalService.rejectLocation(
        approvalId: approvalId,
        userId: _currentUserId!,
        comment: comment,
        historyProvider: historyProvider,
      );

      // Remove from pending list and update stats
      _pendingApprovals.removeWhere((approval) => approval.id == approvalId);
      
      // Reload stats
      await loadApprovalStats();

      log('Successfully rejected location: $approvalId');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to reject location: ${e.toString()}');
      log('Error rejecting location: $e');
      return false;
    }
  }

  /// Submit a location for approval
  Future<String?> submitLocation({
    required String locationId,
    required String locationName,
    required String category,
    required double latitude,
    required double longitude,
    String? description,
    UserHistoryProvider? historyProvider,
  }) async {
    if (_currentUserId == null) return null;
    
    try {
      _clearError();
      
      final approvalId = await _approvalService.submitLocationForApproval(
        locationId: locationId,
        locationName: locationName,
        category: category,
        latitude: latitude,
        longitude: longitude,
        description: description,
        userId: _currentUserId!,
        historyProvider: historyProvider,
      );

      // Reload user added locations and stats
      await Future.wait([
        loadUserAddedLocations(),
        loadApprovalStats(),
      ]);

      log('Successfully submitted location for approval: $approvalId');
      return approvalId;
    } catch (e) {
      _setError('Failed to submit location: ${e.toString()}');
      log('Error submitting location: $e');
      return null;
    }
  }

  /// Delete a location approval (only for pending locations added by user)
  Future<bool> deleteLocationApproval(String approvalId) async {
    if (_currentUserId == null) return false;
    
    try {
      _clearError();
      
      await _approvalService.deleteLocationApproval(
        approvalId: approvalId,
        userId: _currentUserId!,
      );

      // Remove from local lists and reload data
      _userAddedLocations.removeWhere((approval) => approval.id == approvalId);
      
      await loadApprovalStats();

      log('Successfully deleted location approval: $approvalId');
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to delete location: ${e.toString()}');
      log('Error deleting location approval: $e');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refresh() async {
    await loadAllData();
  }

  /// Get specific approval by ID
  LocationApproval? getApprovalById(String approvalId) {
    // Check all lists
    LocationApproval? approval;
    
    approval = _pendingApprovals.where((a) => a.id == approvalId).firstOrNull;
    if (approval != null) return approval;
    
    approval = _userAddedLocations.where((a) => a.id == approvalId).firstOrNull;
    if (approval != null) return approval;
    
    approval = _userApprovedLocations.where((a) => a.id == approvalId).firstOrNull;
    if (approval != null) return approval;
    
    return null;
  }

  /// Check if user can vote on a specific location
  bool canUserVote(String approvalId) {
    final approval = getApprovalById(approvalId);
    return approval?.canUserVote(_currentUserId ?? '') ?? false;
  }

  /// Filter pending approvals by category
  List<LocationApproval> getPendingApprovalsByCategory(String category) {
    return _pendingApprovals
        .where((approval) => approval.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get approval counts by status for user's added locations
  Map<ApprovalStatus, int> getUserLocationStatusCounts() {
    final counts = <ApprovalStatus, int>{};
    
    for (final approval in _userAddedLocations) {
      counts[approval.status] = (counts[approval.status] ?? 0) + 1;
    }
    
    return counts;
  }

  /// Clear all data (for logout)
  void clearData() {
    _pendingApprovals.clear();
    _userAddedLocations.clear();
    _userApprovedLocations.clear();
    _approvalStats.clear();
    _currentUserId = null;
    _clearError();
    notifyListeners();
    log('Cleared all approval data');
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _hasError = true;
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _hasError = false;
    _errorMessage = '';
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
}