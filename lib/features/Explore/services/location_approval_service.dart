import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:campus_mapper/features/Explore/models/location_approval.dart';
import 'package:campus_mapper/features/History/models/user_history.dart';
import 'package:campus_mapper/features/History/providers/user_history_provider.dart';
import 'dart:developer' show log;

class LocationApprovalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _approvalsCollection = 'location_approvals';
  static const String _userApprovalsCollection = 'user_approval_records';
  static const String _locationsCollection = 'locations';

  /// Submit a location for approval
  Future<String> submitLocationForApproval({
    required String locationId,
    required String locationName,
    required String category,
    required double latitude,
    required double longitude,
    String? description,
    required String userId,
    UserHistoryProvider? historyProvider,
  }) async {
    try {
      final approval = LocationApproval(
        id: '', // Will be set by Firestore
        locationId: locationId,
        locationName: locationName,
        category: category,
        coordinates: {
          'latitude': latitude,
          'longitude': longitude,
        },
        description: description,
        addedBy: userId,
        addedAt: DateTime.now(),
        status: ApprovalStatus.pending,
        approvedBy: [],
        rejectedBy: [],
      );

      final docRef = await _firestore
          .collection(_approvalsCollection)
          .add(approval.toFirestore());

      // Add to user history
      if (historyProvider != null) {
        final historyItem = UserHistory.placeAdded(
          userId: userId,
          placeId: locationId,
          placeName: locationName,
          category: category,
          latitude: latitude,
          longitude: longitude,
        );
        await historyProvider.addHistoryItem(historyItem);
      }

      log('Location submitted for approval: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      log('Error submitting location for approval: $e');
      rethrow;
    }
  }

  /// Get pending locations for approval (excluding user's own submissions)
  Future<List<LocationApproval>> getPendingApprovals({
    required String currentUserId,
    int limit = 20,
  }) async {
    try {
      final query = await _firestore
          .collection(_approvalsCollection)
          .where('status', isEqualTo: 'pending')
          .where('added_by', isNotEqualTo: currentUserId)
          .orderBy('added_at', descending: true)
          .limit(limit)
          .get();

      final approvals = query.docs
          .map((doc) => LocationApproval.fromFirestore(doc))
          .where((approval) => approval.canUserVote(currentUserId))
          .toList();

      log('Retrieved ${approvals.length} pending approvals for user: $currentUserId');
      return approvals;
    } catch (e) {
      log('Error getting pending approvals: $e');
      rethrow;
    }
  }

  /// Get locations added by a specific user
  Future<List<LocationApproval>> getUserAddedLocations(String userId) async {
    try {
      final query = await _firestore
          .collection(_approvalsCollection)
          .where('added_by', isEqualTo: userId)
          .orderBy('added_at', descending: true)
          .get();

      final approvals = query.docs
          .map((doc) => LocationApproval.fromFirestore(doc))
          .toList();

      log('Retrieved ${approvals.length} locations added by user: $userId');
      return approvals;
    } catch (e) {
      log('Error getting user added locations: $e');
      rethrow;
    }
  }

  /// Get locations approved by a specific user
  Future<List<LocationApproval>> getUserApprovedLocations(String userId) async {
    try {
      final query = await _firestore
          .collection(_approvalsCollection)
          .where('approved_by', arrayContains: userId)
          .orderBy('added_at', descending: true)
          .get();

      final approvals = query.docs
          .map((doc) => LocationApproval.fromFirestore(doc))
          .toList();

      log('Retrieved ${approvals.length} locations approved by user: $userId');
      return approvals;
    } catch (e) {
      log('Error getting user approved locations: $e');
      rethrow;
    }
  }

  /// Approve a location
  Future<void> approveLocation({
    required String approvalId,
    required String userId,
    String? comment,
    UserHistoryProvider? historyProvider,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final approvalRef = _firestore.collection(_approvalsCollection).doc(approvalId);
        final approvalDoc = await transaction.get(approvalRef);
        
        if (!approvalDoc.exists) {
          throw Exception('Location approval not found');
        }

        final approval = LocationApproval.fromFirestore(approvalDoc);
        
        if (!approval.canUserVote(userId)) {
          throw Exception('User cannot vote on this location');
        }

        // Add user to approved list
        final updatedApprovedBy = List<String>.from(approval.approvedBy)..add(userId);
        
        // Check if location should be verified
        final shouldVerify = updatedApprovedBy.length >= approval.requiredApprovals;
        final newStatus = shouldVerify ? ApprovalStatus.verified : ApprovalStatus.pending;
        final verifiedAt = shouldVerify ? DateTime.now() : null;

        // Update approval document
        transaction.update(approvalRef, {
          'approved_by': updatedApprovedBy,
          'status': newStatus.name,
          'verified_at': verifiedAt != null ? Timestamp.fromDate(verifiedAt) : null,
        });

        // If verified, add to main locations collection
        if (shouldVerify) {
          final locationData = {
            'id': approval.locationId,
            'name': approval.locationName,
            'category': approval.category,
            'location': approval.coordinates,
            'description': approval.description,
            'added_by': approval.addedBy,
            'verified_at': Timestamp.fromDate(verifiedAt!),
            'approval_count': updatedApprovedBy.length,
            'created_at': Timestamp.fromDate(approval.addedAt),
          };

          transaction.set(
            _firestore.collection(_locationsCollection).doc(approval.locationId),
            locationData,
          );
        }

        // Record individual vote
        final voteRecord = UserApprovalRecord(
          userId: userId,
          locationApprovalId: approvalId,
          approved: true,
          votedAt: DateTime.now(),
          comment: comment,
        );

        transaction.set(
          _firestore.collection(_userApprovalsCollection).doc('${approvalId}_$userId'),
          voteRecord.toFirestore(),
        );
      });

      // Add to user history
      if (historyProvider != null) {
        final approval = await getLocationApproval(approvalId);
        if (approval != null) {
          final historyItem = UserHistory.locationApproved(
            userId: userId,
            placeId: approval.locationId,
            placeName: approval.locationName,
            category: approval.category,
            latitude: approval.coordinates['latitude'],
            longitude: approval.coordinates['longitude'],
          );
          await historyProvider.addHistoryItem(historyItem);
        }
      }

      log('Location approved by user: $userId');
    } catch (e) {
      log('Error approving location: $e');
      rethrow;
    }
  }

  /// Reject a location
  Future<void> rejectLocation({
    required String approvalId,
    required String userId,
    String? comment,
    UserHistoryProvider? historyProvider,
  }) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final approvalRef = _firestore.collection(_approvalsCollection).doc(approvalId);
        final approvalDoc = await transaction.get(approvalRef);
        
        if (!approvalDoc.exists) {
          throw Exception('Location approval not found');
        }

        final approval = LocationApproval.fromFirestore(approvalDoc);
        
        if (!approval.canUserVote(userId)) {
          throw Exception('User cannot vote on this location');
        }

        // Add user to rejected list
        final updatedRejectedBy = List<String>.from(approval.rejectedBy)..add(userId);
        
        // Update approval document
        transaction.update(approvalRef, {
          'rejected_by': updatedRejectedBy,
        });

        // Record individual vote
        final voteRecord = UserApprovalRecord(
          userId: userId,
          locationApprovalId: approvalId,
          approved: false,
          votedAt: DateTime.now(),
          comment: comment,
        );

        transaction.set(
          _firestore.collection(_userApprovalsCollection).doc('${approvalId}_$userId'),
          voteRecord.toFirestore(),
        );
      });

      log('Location rejected by user: $userId');
    } catch (e) {
      log('Error rejecting location: $e');
      rethrow;
    }
  }

  /// Get a specific location approval
  Future<LocationApproval?> getLocationApproval(String approvalId) async {
    try {
      final doc = await _firestore
          .collection(_approvalsCollection)
          .doc(approvalId)
          .get();

      if (doc.exists) {
        return LocationApproval.fromFirestore(doc);
      }
      
      return null;
    } catch (e) {
      log('Error getting location approval: $e');
      return null;
    }
  }

  /// Get approval statistics for a user
  Future<Map<String, int>> getUserApprovalStats(String userId) async {
    try {
      // Get locations added by user
      final addedQuery = await _firestore
          .collection(_approvalsCollection)
          .where('added_by', isEqualTo: userId)
          .get();

      // Get locations approved by user
      final approvedQuery = await _firestore
          .collection(_userApprovalsCollection)
          .where('user_id', isEqualTo: userId)
          .where('approved', isEqualTo: true)
          .get();

      // Get locations rejected by user
      final rejectedQuery = await _firestore
          .collection(_userApprovalsCollection)
          .where('user_id', isEqualTo: userId)
          .where('approved', isEqualTo: false)
          .get();

      // Count verified locations by user
      final verifiedCount = addedQuery.docs
          .map((doc) => LocationApproval.fromFirestore(doc))
          .where((approval) => approval.isVerified)
          .length;

      return {
        'added': addedQuery.docs.length,
        'approved': approvedQuery.docs.length,
        'rejected': rejectedQuery.docs.length,
        'verified': verifiedCount,
      };
    } catch (e) {
      log('Error getting user approval stats: $e');
      return {
        'added': 0,
        'approved': 0,
        'rejected': 0,
        'verified': 0,
      };
    }
  }

  /// Delete a location approval (admin only or user's own pending submissions)
  Future<void> deleteLocationApproval({
    required String approvalId,
    required String userId,
    bool isAdmin = false,
  }) async {
    try {
      final approval = await getLocationApproval(approvalId);
      
      if (approval == null) {
        throw Exception('Location approval not found');
      }

      // Check permissions
      if (!isAdmin && approval.addedBy != userId) {
        throw Exception('Insufficient permissions');
      }

      if (!isAdmin && !approval.isPending) {
        throw Exception('Cannot delete non-pending approvals');
      }

      await _firestore.collection(_approvalsCollection).doc(approvalId).delete();
      
      log('Location approval deleted: $approvalId');
    } catch (e) {
      log('Error deleting location approval: $e');
      rethrow;
    }
  }

  /// Stream pending approvals for real-time updates
  Stream<List<LocationApproval>> streamPendingApprovals({
    required String currentUserId,
    int limit = 20,
  }) {
    return _firestore
        .collection(_approvalsCollection)
        .where('status', isEqualTo: 'pending')
        .where('added_by', isNotEqualTo: currentUserId)
        .orderBy('added_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => LocationApproval.fromFirestore(doc))
              .where((approval) => approval.canUserVote(currentUserId))
              .toList();
        });
  }
}