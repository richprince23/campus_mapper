import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/university.dart';

class UniversityService {
  static const String _collection = 'universities';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final List<University> _ghanaianUniversities = [
    University(id: 'ug', name: 'University of Ghana', shortName: 'UG'),
    University(id: 'knust', name: 'Kwame Nkrumah University of Science and Technology', shortName: 'KNUST'),
    University(id: 'ucc', name: 'University of Cape Coast', shortName: 'UCC'),
    University(id: 'uew', name: 'University of Education, Winneba', shortName: 'UEW'),
    University(id: 'uds', name: 'University for Development Studies', shortName: 'UDS'),
    University(id: 'upsa', name: 'University of Professional Studies, Accra', shortName: 'UPSA'),
    University(id: 'ashesi', name: 'Ashesi University', shortName: 'Ashesi'),
    University(id: 'central', name: 'Central University', shortName: 'Central'),
    University(id: 'regent', name: 'Regent University College of Science and Technology', shortName: 'Regent'),
    University(id: 'vvu', name: 'Valley View University', shortName: 'VVU'),
    University(id: 'gimpa', name: 'Ghana Institute of Management and Public Administration', shortName: 'GIMPA'),
    University(id: 'ttu', name: 'Takoradi Technical University', shortName: 'TTU'),
    University(id: 'umat', name: 'University of Mines and Technology', shortName: 'UMaT'),
    University(id: 'uhas', name: 'University of Health and Allied Sciences', shortName: 'UHAS'),
    University(id: 'ktu', name: 'Koforidua Technical University', shortName: 'KTU'),
    University(id: 'uam', name: 'University of Applied Management', shortName: 'UAM'),
    University(id: 'mucg', name: 'Methodist University College Ghana', shortName: 'MUCG'),
    University(id: 'aucc', name: 'African University College of Communications', shortName: 'AUCC'),
    University(id: 'anuc', name: 'All Nations University College', shortName: 'ANUC'),
    University(id: 'ics', name: 'International Community School', shortName: 'ICS'),
    University(id: 'puc', name: 'Pentecost University College', shortName: 'PUC'),
    University(id: 'dluc', name: 'Data Link University College', shortName: 'DLUC'),
    University(id: 'gcuc', name: 'Garden City University College', shortName: 'GCUC'),
    University(id: 'uenr', name: 'The University of Energy and Natural Resources', shortName: 'UENR'),
    University(id: 'bluecrest', name: 'BlueCrest College', shortName: 'BlueCrest'),
  ];

  Future<void> initializeUniversities() async {
    try {
      final batch = _firestore.batch();
      
      for (final university in _ghanaianUniversities) {
        final docRef = _firestore.collection(_collection).doc(university.id);
        batch.set(docRef, university.toJson());
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to initialize universities: $e');
    }
  }

  Future<List<University>> getAllUniversities() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('is_active', isEqualTo: true)
          .orderBy('name')
          .get();

      // If collection exists and has data, use it
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs
            .map((doc) => University.fromJson(doc.data()))
            .toList();
      }
      
      // If collection is empty or doesn't exist, initialize it and return static list
      await initializeUniversities();
      return _ghanaianUniversities.where((u) => u.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
        
    } catch (e) {
      // If Firestore fails, return static list as fallback
      return _ghanaianUniversities.where((u) => u.isActive).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    }
  }

  Future<University?> getUniversityById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      
      if (doc.exists && doc.data() != null) {
        return University.fromJson(doc.data()!);
      }
      
      // If not found in Firestore, try the static list
      final matches = _ghanaianUniversities.where((u) => u.id == id).toList();
      return matches.isNotEmpty ? matches.first : null;
    } catch (e) {
      // If Firestore fails, search in static list
      final matches = _ghanaianUniversities.where((u) => u.id == id).toList();
      return matches.isNotEmpty ? matches.first : null;
    }
  }

  Stream<List<University>> watchUniversities() {
    return _firestore
        .collection(_collection)
        .where('is_active', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => University.fromJson(doc.data()))
            .toList());
  }
}