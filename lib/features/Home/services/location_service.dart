import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class LocationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String schools = 'schools';
  final String history = 'history';

  Future<void> addLocation(
      String name, String address, String latitude, String longitude) async {
    await _db.collection(schools).add({
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  // get all locations
  Future<List<DocumentSnapshot>> getSchools() async {
    QuerySnapshot querySnapshot = await _db.collection(schools).get();
    return querySnapshot.docs;
  }
}
