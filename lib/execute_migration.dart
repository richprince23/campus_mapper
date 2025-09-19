import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/utils/simple_migration.dart';

/// Temporary app to execute migration
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🚀 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print('✅ Firebase initialized');
  
  print('\n🔄 Starting migration...');
  try {
    final results = await SimpleMigration.runCompleteMigration();
    
    if (results['success'] == true) {
      print('✅ Migration completed successfully!');
      print('📊 Results:');
      if (results['locations'] != null) {
        final locationResults = results['locations'] as Map<String, dynamic>;
        print('  Locations: ${locationResults['updated']} updated out of ${locationResults['total']} total');
      }
      if (results['users'] != null) {
        final userResults = results['users'] as Map<String, dynamic>;
        print('  Users: ${userResults['updated']} updated out of ${userResults['total']} total');
      }
      
      print('\n📊 Verifying results...');
      final verification = await SimpleMigration.verifyMigration();
      print('  Locations with UEW: ${verification['locations']['with_uew']}/${verification['locations']['total']} (${verification['locations']['percentage']}%)');
      print('  User profiles with UEW: ${verification['user_profiles']['with_uew']}/${verification['user_profiles']['total']} (${verification['user_profiles']['percentage']}%)');
      
    } else {
      print('❌ Migration failed: ${results['error']}');
    }
  } catch (e) {
    print('❌ Error: $e');
  }
  
  print('\n🎉 Migration process completed!');
}