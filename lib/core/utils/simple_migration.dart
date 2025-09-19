import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple migration function that can be called directly
class SimpleMigration {
  static const String _uewId = 'uew';
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Run complete migration (locations + user profiles)
  static Future<Map<String, dynamic>> runCompleteMigration() async {
    final results = <String, dynamic>{};
    
    try {
      // Migrate locations
      final locationResults = await migrateLocations();
      results['locations'] = locationResults;
      
      // Migrate user profiles  
      final userResults = await migrateUserProfiles();
      results['users'] = userResults;
      
      results['success'] = true;
      results['message'] = 'Complete migration successful!';
      
    } catch (e) {
      results['success'] = false;
      results['error'] = e.toString();
    }
    
    return results;
  }

  /// Migrate all locations to UEW
  static Future<Map<String, dynamic>> migrateLocations() async {
    try {
      // Get all locations without university_id
      final QuerySnapshot snapshot = await _firestore
          .collection('locations')
          .get();

      final locationsToUpdate = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return !data.containsKey('university_id') || 
               data['university_id'] == null || 
               data['university_id'] == '';
      }).toList();

      if (locationsToUpdate.isEmpty) {
        return {
          'updated': 0,
          'total': snapshot.docs.length,
          'message': 'No locations need migration'
        };
      }

      // Update locations in batches
      const batchSize = 500;
      int updated = 0;
      
      for (int i = 0; i < locationsToUpdate.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < locationsToUpdate.length) 
            ? i + batchSize 
            : locationsToUpdate.length;
        
        for (int j = i; j < end; j++) {
          batch.update(locationsToUpdate[j].reference, {
            'university_id': _uewId,
            'migration_updated_at': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        updated += (end - i);
      }

      return {
        'updated': updated,
        'total': snapshot.docs.length,
        'message': 'Updated $updated locations to UEW'
      };

    } catch (e) {
      throw Exception('Location migration failed: $e');
    }
  }

  /// Migrate all user profiles to UEW
  static Future<Map<String, dynamic>> migrateUserProfiles() async {
    try {
      // Get all user profiles
      final QuerySnapshot snapshot = await _firestore
          .collection('user_profiles')
          .get();

      final profilesToUpdate = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return !data.containsKey('university_id') || 
               data['university_id'] == null || 
               data['university_id'] == '';
      }).toList();

      if (profilesToUpdate.isEmpty) {
        return {
          'updated': 0,
          'total': snapshot.docs.length,
          'message': 'No user profiles need migration'
        };
      }

      // Update profiles in batches
      const batchSize = 500;
      int updated = 0;
      
      for (int i = 0; i < profilesToUpdate.length; i += batchSize) {
        final batch = _firestore.batch();
        final end = (i + batchSize < profilesToUpdate.length) 
            ? i + batchSize 
            : profilesToUpdate.length;
        
        for (int j = i; j < end; j++) {
          batch.update(profilesToUpdate[j].reference, {
            'university_id': _uewId,
            'migration_updated_at': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        updated += (end - i);
      }

      return {
        'updated': updated,
        'total': snapshot.docs.length,
        'message': 'Updated $updated user profiles to UEW'
      };

    } catch (e) {
      throw Exception('User profile migration failed: $e');
    }
  }

  /// Verify migration results
  static Future<Map<String, dynamic>> verifyMigration() async {
    try {
      // Check locations
      final locationsTotal = await _firestore.collection('locations').get();
      final locationsWithUEW = await _firestore
          .collection('locations')
          .where('university_id', isEqualTo: _uewId)
          .get();

      // Check user profiles
      final profilesTotal = await _firestore.collection('user_profiles').get();
      final profilesWithUEW = await _firestore
          .collection('user_profiles')
          .where('university_id', isEqualTo: _uewId)
          .get();

      return {
        'locations': {
          'total': locationsTotal.docs.length,
          'with_uew': locationsWithUEW.docs.length,
          'percentage': locationsTotal.docs.isEmpty 
              ? 0 
              : (locationsWithUEW.docs.length / locationsTotal.docs.length * 100).round()
        },
        'user_profiles': {
          'total': profilesTotal.docs.length,
          'with_uew': profilesWithUEW.docs.length,
          'percentage': profilesTotal.docs.isEmpty 
              ? 0 
              : (profilesWithUEW.docs.length / profilesTotal.docs.length * 100).round()
        }
      };

    } catch (e) {
      throw Exception('Verification failed: $e');
    }
  }
}