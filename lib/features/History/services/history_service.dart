import 'package:campus_mapper/features/History/models/history_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference get _historyCollection => 
    _firestore.collection('users').doc(_userId).collection('history');

  Future<List<HistoryItem>> getHistory({int? limit}) async {
    if (_userId == null) return [];

    try {
      Query query = _historyCollection.orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => HistoryItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching history: $e');
      rethrow;
    }
  }

  Future<void> addHistoryItem(HistoryItem item) async {
    if (_userId == null) return;

    try {
      // Check if similar item already exists (to avoid duplicates)
      final existingQuery = await _historyCollection
          .where('title', isEqualTo: item.title)
          .where('type', isEqualTo: item.type.toString().split('.').last)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      // If the same item was added within the last 5 minutes, don't add it again
      if (existingQuery.docs.isNotEmpty) {
        final lastItem = HistoryItem.fromFirestore(existingQuery.docs.first);
        final timeDifference = DateTime.now().difference(lastItem.timestamp);
        if (timeDifference.inMinutes < 5) {
          return;
        }
      }

      await _historyCollection.add(item.toFirestore());
    } catch (e) {
      print('Error adding history item: $e');
      rethrow;
    }
  }

  Future<void> deleteHistoryItem(String itemId) async {
    if (_userId == null) return;

    try {
      await _historyCollection.doc(itemId).delete();
    } catch (e) {
      print('Error deleting history item: $e');
      rethrow;
    }
  }

  Future<void> clearHistory() async {
    if (_userId == null) return;

    try {
      final snapshot = await _historyCollection.get();
      final batch = _firestore.batch();
      
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Error clearing history: $e');
      rethrow;
    }
  }

  Future<List<HistoryItem>> getHistoryByType(HistoryType type, {int? limit}) async {
    if (_userId == null) return [];

    try {
      Query query = _historyCollection
          .where('type', isEqualTo: type.toString().split('.').last)
          .orderBy('timestamp', descending: true);
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => HistoryItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching history by type: $e');
      rethrow;
    }
  }

  Future<List<String>> getFrequentSearches({int limit = 10}) async {
    if (_userId == null) return [];

    try {
      final snapshot = await _historyCollection
          .where('type', isEqualTo: 'search')
          .orderBy('timestamp', descending: true)
          .limit(100) // Get last 100 searches to analyze frequency
          .get();

      final searchCounts = <String, int>{};
      for (final doc in snapshot.docs) {
        final item = HistoryItem.fromFirestore(doc);
        searchCounts[item.title] = (searchCounts[item.title] ?? 0) + 1;
      }

      final sortedSearches = searchCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedSearches
          .take(limit)
          .map((entry) => entry.key)
          .toList();
    } catch (e) {
      print('Error getting frequent searches: $e');
      return [];
    }
  }

  Future<Map<String, int>> getHistoryStats() async {
    if (_userId == null) {
      return {
        'total': 0,
        'searches': 0,
        'navigations': 0,
        'locationViews': 0,
      };
    }

    try {
      final snapshot = await _historyCollection.get();
      final stats = <String, int>{
        'total': snapshot.docs.length,
        'searches': 0,
        'navigations': 0,
        'locationViews': 0,
      };

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final type = data['type'] as String?;
        
        switch (type) {
          case 'search':
            stats['searches'] = stats['searches']! + 1;
            break;
          case 'navigation':
            stats['navigations'] = stats['navigations']! + 1;
            break;
          case 'locationView':
            stats['locationViews'] = stats['locationViews']! + 1;
            break;
        }
      }

      return stats;
    } catch (e) {
      print('Error getting history stats: $e');
      return {
        'total': 0,
        'searches': 0,
        'navigations': 0,
        'locationViews': 0,
      };
    }
  }
}