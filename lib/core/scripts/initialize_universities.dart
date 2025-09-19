import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../services/university_service.dart';

/// Script to initialize universities in Firestore
/// Usage: dart run lib/core/scripts/initialize_universities.dart
void main() async {
  print('🏫 Campus Mapper - University Initialization');
  print('=' * 45);
  
  try {
    // Initialize Firebase
    print('📱 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    final universityService = UniversityService();
    
    print('\n🔄 Initializing universities in Firestore...');
    await universityService.initializeUniversities();
    print('✅ Universities initialized successfully');
    
    print('\n📊 Loading universities to verify...');
    final universities = await universityService.getAllUniversities();
    print('✅ Found ${universities.length} universities:');
    
    for (final university in universities.take(5)) {
      print('  • ${university.name} (${university.shortName})');
    }
    
    if (universities.length > 5) {
      print('  ... and ${universities.length - 5} more');
    }
    
    print('\n🎉 University initialization completed successfully!');
    
  } catch (e) {
    print('\n❌ Error: $e');
  }
}