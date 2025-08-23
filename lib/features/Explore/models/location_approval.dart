import 'package:cloud_firestore/cloud_firestore.dart';

enum ApprovalStatus { pending, approved, rejected, verified }

class LocationApproval {
  final String id;
  final String locationId;
  final String locationName;
  final String category;
  final Map<String, double> coordinates; // {latitude, longitude}
  final String? description;
  final String addedBy; // User ID who added the location
  final DateTime addedAt;
  final ApprovalStatus status;
  final List<String> approvedBy; // List of user IDs who approved
  final List<String> rejectedBy; // List of user IDs who rejected
  final int requiredApprovals; // Number of approvals needed (default: 3)
  final DateTime? verifiedAt;
  final Map<String, dynamic> metadata;

  const LocationApproval({
    required this.id,
    required this.locationId,
    required this.locationName,
    required this.category,
    required this.coordinates,
    this.description,
    required this.addedBy,
    required this.addedAt,
    required this.status,
    required this.approvedBy,
    required this.rejectedBy,
    this.requiredApprovals = 3,
    this.verifiedAt,
    this.metadata = const {},
  });

  // Create from Firestore document
  factory LocationApproval.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LocationApproval(
      id: doc.id,
      locationId: data['location_id'] ?? '',
      locationName: data['location_name'] ?? '',
      category: data['category'] ?? '',
      coordinates: Map<String, double>.from(data['coordinates'] ?? {}),
      description: data['description'],
      addedBy: data['added_by'] ?? '',
      addedAt: (data['added_at'] as Timestamp).toDate(),
      status: _parseApprovalStatus(data['status']),
      approvedBy: List<String>.from(data['approved_by'] ?? []),
      rejectedBy: List<String>.from(data['rejected_by'] ?? []),
      requiredApprovals: data['required_approvals'] ?? 3,
      verifiedAt: data['verified_at'] != null 
          ? (data['verified_at'] as Timestamp).toDate() 
          : null,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'location_id': locationId,
      'location_name': locationName,
      'category': category,
      'coordinates': coordinates,
      'description': description,
      'added_by': addedBy,
      'added_at': Timestamp.fromDate(addedAt),
      'status': status.name,
      'approved_by': approvedBy,
      'rejected_by': rejectedBy,
      'required_approvals': requiredApprovals,
      'verified_at': verifiedAt != null ? Timestamp.fromDate(verifiedAt!) : null,
      'metadata': metadata,
    };
  }

  // Create from JSON (for caching)
  factory LocationApproval.fromJson(Map<String, dynamic> json) {
    return LocationApproval(
      id: json['id'] ?? '',
      locationId: json['location_id'] ?? '',
      locationName: json['location_name'] ?? '',
      category: json['category'] ?? '',
      coordinates: Map<String, double>.from(json['coordinates'] ?? {}),
      description: json['description'],
      addedBy: json['added_by'] ?? '',
      addedAt: DateTime.parse(json['added_at']),
      status: _parseApprovalStatus(json['status']),
      approvedBy: List<String>.from(json['approved_by'] ?? []),
      rejectedBy: List<String>.from(json['rejected_by'] ?? []),
      requiredApprovals: json['required_approvals'] ?? 3,
      verifiedAt: json['verified_at'] != null 
          ? DateTime.parse(json['verified_at']) 
          : null,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
    );
  }

  // Convert to JSON (for caching)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'location_id': locationId,
      'location_name': locationName,
      'category': category,
      'coordinates': coordinates,
      'description': description,
      'added_by': addedBy,
      'added_at': addedAt.toIso8601String(),
      'status': status.name,
      'approved_by': approvedBy,
      'rejected_by': rejectedBy,
      'required_approvals': requiredApprovals,
      'verified_at': verifiedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  // Create a copy with updated values
  LocationApproval copyWith({
    String? id,
    String? locationId,
    String? locationName,
    String? category,
    Map<String, double>? coordinates,
    String? description,
    String? addedBy,
    DateTime? addedAt,
    ApprovalStatus? status,
    List<String>? approvedBy,
    List<String>? rejectedBy,
    int? requiredApprovals,
    DateTime? verifiedAt,
    Map<String, dynamic>? metadata,
  }) {
    return LocationApproval(
      id: id ?? this.id,
      locationId: locationId ?? this.locationId,
      locationName: locationName ?? this.locationName,
      category: category ?? this.category,
      coordinates: coordinates ?? this.coordinates,
      description: description ?? this.description,
      addedBy: addedBy ?? this.addedBy,
      addedAt: addedAt ?? this.addedAt,
      status: status ?? this.status,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedBy: rejectedBy ?? this.rejectedBy,
      requiredApprovals: requiredApprovals ?? this.requiredApprovals,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  // Helper methods
  bool get isPending => status == ApprovalStatus.pending;
  bool get isApproved => status == ApprovalStatus.approved;
  bool get isRejected => status == ApprovalStatus.rejected;
  bool get isVerified => status == ApprovalStatus.verified;

  int get approvalCount => approvedBy.length;
  int get rejectionCount => rejectedBy.length;
  int get remainingApprovals => requiredApprovals - approvalCount;

  bool get needsMoreApprovals => isPending && approvalCount < requiredApprovals;
  bool get canBeVerified => isPending && approvalCount >= requiredApprovals;

  bool hasUserApproved(String userId) => approvedBy.contains(userId);
  bool hasUserRejected(String userId) => rejectedBy.contains(userId);
  bool canUserVote(String userId) => 
      !hasUserApproved(userId) && 
      !hasUserRejected(userId) && 
      addedBy != userId && 
      isPending;

  // Parse status string to enum
  static ApprovalStatus _parseApprovalStatus(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return ApprovalStatus.approved;
      case 'rejected':
        return ApprovalStatus.rejected;
      case 'verified':
        return ApprovalStatus.verified;
      case 'pending':
      default:
        return ApprovalStatus.pending;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationApproval &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          locationId == other.locationId;

  @override
  int get hashCode => id.hashCode ^ locationId.hashCode;

  @override
  String toString() {
    return 'LocationApproval(id: $id, name: $locationName, status: $status, approvals: ${approvalCount}/$requiredApprovals)';
  }
}

// User approval record for tracking individual votes
class UserApprovalRecord {
  final String userId;
  final String locationApprovalId;
  final bool approved; // true for approve, false for reject
  final DateTime votedAt;
  final String? comment;

  const UserApprovalRecord({
    required this.userId,
    required this.locationApprovalId,
    required this.approved,
    required this.votedAt,
    this.comment,
  });

  // Create from Firestore document
  factory UserApprovalRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserApprovalRecord(
      userId: data['user_id'] ?? '',
      locationApprovalId: data['location_approval_id'] ?? '',
      approved: data['approved'] ?? false,
      votedAt: (data['voted_at'] as Timestamp).toDate(),
      comment: data['comment'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'user_id': userId,
      'location_approval_id': locationApprovalId,
      'approved': approved,
      'voted_at': Timestamp.fromDate(votedAt),
      'comment': comment,
    };
  }
}