import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'migrate_locations_to_university.dart';

/// Command line script to run the migration
/// Usage: dart run lib/core/scripts/run_migration.dart [options]
void main(List<String> args) async {
  print('🚀 Campus Mapper - University Migration Tool');
  print('=' * 50);
  
  try {
    // Initialize Firebase
    print('📱 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    final migration = LocationUniversityMigration();
    
    if (args.isEmpty) {
      print('\n📋 Available options:');
      print('  all       - Migrate both locations and user profiles');
      print('  locations - Migrate locations only');
      print('  users     - Migrate user profiles only');
      print('  verify    - Verify migration results');
      print('  rollback  - Rollback migration');
      print('\nExample: dart run lib/core/scripts/run_migration.dart all');
      exit(1);
    }
    
    final command = args[0].toLowerCase();
    
    switch (command) {
      case 'all':
        print('\n🔄 Running complete migration...');
        await migration.migrateAll();
        print('\n📊 Verifying results...');
        await migration.verifyMigration();
        break;
        
      case 'locations':
        print('\n🔄 Running location migration...');
        await migration.migrateAllLocations();
        print('\n📊 Verifying results...');
        await migration.verifyMigration();
        break;
        
      case 'users':
        print('\n🔄 Running user profile migration...');
        await migration.migrateAllUserProfiles();
        print('\n📊 Verifying results...');
        await migration.verifyMigration();
        break;
        
      case 'verify':
        print('\n📊 Verifying migration results...');
        await migration.verifyMigration();
        break;
        
      case 'rollback':
        print('\n⚠️  WARNING: This will remove university assignments from all data!');
        print('Are you sure you want to continue? (y/N)');
        final input = stdin.readLineSync();
        if (input?.toLowerCase() == 'y') {
          print('\n🔄 Running rollback...');
          await migration.rollbackMigration();
        } else {
          print('❌ Rollback cancelled');
        }
        break;
        
      default:
        print('❌ Unknown command: $command');
        print('Use one of: all, locations, users, verify, rollback');
        exit(1);
    }
    
    print('\n✅ Operation completed successfully!');
    
  } catch (e) {
    print('\n❌ Error: $e');
    exit(1);
  }
}