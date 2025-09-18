import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' show log;

/// Migration script to update all existing locations and user profiles with University of Education, Winneba
class LocationUniversityMigration {
  static const String _uewId = 'uew'; // University of Education, Winneba
  static const String _locationsCollection = 'locations';
  static const String _userProfilesCollection = 'user_profiles';
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Run complete migration for both locations and user profiles
  Future<void> migrateAll() async {
    log('Starting complete migration...');
    
    try {
      // Migrate locations first
      await migrateAllLocations();
      
      // Then migrate user profiles
      await migrateAllUserProfiles();
      
      log('Complete migration finished successfully!');
    } catch (e) {
      log('Error during complete migration: $e');
      rethrow;
    }
  }

  /// Run the migration to update all existing locations
  Future<void> migrateAllLocations() async {
    try {
      log('Starting location university migration...');
      
      // Get all locations that don't have university_id set
      final QuerySnapshot snapshot = await _firestore
          .collection(_locationsCollection)
          .where('university_id', isEqualTo: null)
          .get();

      if (snapshot.docs.isEmpty) {
        log('No locations need migration');
        return;
      }

      log('Found ${snapshot.docs.length} locations to migrate');

      // Update in batches of 500 (Firestore batch limit)
      const int batchSize = 500;
      final List<List<QueryDocumentSnapshot>> batches = [];
      
      for (int i = 0; i < snapshot.docs.length; i += batchSize) {
        final int end = (i + batchSize < snapshot.docs.length) 
            ? i + batchSize 
            : snapshot.docs.length;
        batches.add(snapshot.docs.sublist(i, end));
      }

      int totalUpdated = 0;
      
      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = _firestore.batch();
        
        for (final doc in batches[batchIndex]) {
          batch.update(doc.reference, {
            'university_id': _uewId,
            'migration_updated_at': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        totalUpdated += batches[batchIndex].length;
        
        log('Batch ${batchIndex + 1}/${batches.length} completed. Updated ${batches[batchIndex].length} locations');
      }

      log('Migration completed successfully! Updated $totalUpdated locations to University of Education, Winneba');
      
    } catch (e) {
      log('Error during migration: $e');
      rethrow;
    }
  }

  /// Verify the migration results
  Future<void> verifyMigration() async {
    try {
      log('Verifying migration results...');
      
      // Count total locations
      final QuerySnapshot totalSnapshot = await _firestore
          .collection(_locationsCollection)
          .get();
      
      // Count locations with UEW
      final QuerySnapshot uewSnapshot = await _firestore
          .collection(_locationsCollection)
          .where('university_id', isEqualTo: _uewId)
          .get();
      
      // Count locations without university_id
      final QuerySnapshot noUniversitySnapshot = await _firestore
          .collection(_locationsCollection)
          .where('university_id', isEqualTo: null)
          .get();

      log('Migration verification results:');
      log('  Total locations: ${totalSnapshot.docs.length}');
      log('  Locations with UEW: ${uewSnapshot.docs.length}');
      log('  Locations without university: ${noUniversitySnapshot.docs.length}');
      
      if (noUniversitySnapshot.docs.isEmpty) {
        log('✅ Migration successful - all locations have university assigned');
      } else {
        log('⚠️  Migration incomplete - ${noUniversitySnapshot.docs.length} locations still need university assignment');
      }
      
    } catch (e) {
      log('Error during verification: $e');
      rethrow;
    }
  }

  /// Rollback migration (remove university_id from all locations)
  Future<void> rollbackMigration() async {
    try {
      log('Starting migration rollback...');
      
      final QuerySnapshot snapshot = await _firestore
          .collection(_locationsCollection)
          .where('university_id', isEqualTo: _uewId)
          .get();

      if (snapshot.docs.isEmpty) {
        log('No locations to rollback');
        return;
      }

      log('Found ${snapshot.docs.length} locations to rollback');

      // Update in batches
      const int batchSize = 500;
      final List<List<QueryDocumentSnapshot>> batches = [];
      
      for (int i = 0; i < snapshot.docs.length; i += batchSize) {
        final int end = (i + batchSize < snapshot.docs.length) 
            ? i + batchSize 
            : snapshot.docs.length;
        batches.add(snapshot.docs.sublist(i, end));
      }

      int totalRolledBack = 0;
      
      for (int batchIndex = 0; batchIndex < batches.length; batchIndex++) {
        final batch = _firestore.batch();
        
        for (final doc in batches[batchIndex]) {
          batch.update(doc.reference, {
            'university_id': FieldValue.delete(),
            'rollback_updated_at': FieldValue.serverTimestamp(),
          });
        }
        
        await batch.commit();
        totalRolledBack += batches[batchIndex].length;
        
        log('Rollback batch ${batchIndex + 1}/${batches.length} completed. Rolled back ${batches[batchIndex].length} locations');
      }

      log('Rollback completed successfully! Rolled back $totalRolledBack locations');
      
    } catch (e) {
      log('Error during rollback: $e');
      rethrow;
    }
  }
}