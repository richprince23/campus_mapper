import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' show log;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Current user
  User? get currentUser => _auth.currentUser;
  
  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;
  
  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Create user account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name
      await userCredential.user?.updateDisplayName(fullName);
      
      // Create user document in Firestore
      await _createUserDocument(userCredential.user!, fullName);
      
      log('User signed up successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      log('Sign up error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Unexpected sign up error: $e');
      throw Exception('Failed to create account. Please try again.');
    }
  }
  
  /// Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Migrate device-based history if exists
      await _migrateDeviceHistory(userCredential.user!);
      
      log('User signed in successfully: ${userCredential.user?.uid}');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      log('Sign in error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Unexpected sign in error: $e');
      throw Exception('Failed to sign in. Please try again.');
    }
  }
  
  /// Sign in with Google (placeholder for future implementation)
  Future<UserCredential?> signInWithGoogle() async {
    // TODO: Implement Google Sign-In
    throw UnimplementedError('Google Sign-In not implemented yet');
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      log('User signed out successfully');
    } catch (e) {
      log('Sign out error: $e');
      throw Exception('Failed to sign out. Please try again.');
    }
  }
  
  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      log('Password reset email sent to: $email');
    } on FirebaseAuthException catch (e) {
      log('Password reset error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      log('Unexpected password reset error: $e');
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }
  
  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, String fullName) async {
    try {
      final userDoc = _firestore.collection('user_profiles').doc(user.uid);
      
      await userDoc.set({
        'user_id': user.uid,
        'email': user.email,
        'full_name': fullName,
        'display_name': fullName,
        'profile_picture_path': null,
        'phone_number': user.phoneNumber,
        'date_of_birth': null,
        'preferences': {
          'notification_enabled': true,
          'location_sharing': true,
          'theme': 'system',
        },
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'last_login': FieldValue.serverTimestamp(),
        'is_active': true,
      }, SetOptions(merge: true));
      
      log('User document created for: ${user.uid}');
    } catch (e) {
      log('Error creating user document: $e');
      // Don't throw here, as the account was already created
    }
  }
  
  /// Migrate device-based history to authenticated user
  Future<void> _migrateDeviceHistory(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceUserId = prefs.getString('device_user_id');
      
      if (deviceUserId == null) return;
      
      // Query device-based history
      final deviceHistoryQuery = await _firestore
          .collection('user_history')
          .where('user_id', isEqualTo: deviceUserId)
          .get();
      
      if (deviceHistoryQuery.docs.isEmpty) return;
      
      log('Migrating ${deviceHistoryQuery.docs.length} history items from device to user account');
      
      // Batch update to change user_id
      final batch = _firestore.batch();
      for (final doc in deviceHistoryQuery.docs) {
        batch.update(doc.reference, {
          'user_id': user.uid,
          'migrated_at': FieldValue.serverTimestamp(),
          'original_device_id': deviceUserId,
        });
      }
      
      await batch.commit();
      
      // Clear device user ID as it's no longer needed
      await prefs.remove('device_user_id');
      
      log('History migration completed successfully');
    } catch (e) {
      log('Error migrating device history: $e');
      // Don't throw here, as sign-in was successful
    }
  }
  
  /// Handle Firebase Auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Please use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return e.message ?? 'An unexpected error occurred. Please try again.';
    }
  }
  
  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');
      
      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      
      // Update Firestore document
      await _firestore.collection('user_profiles').doc(user.uid).update({
        'display_name': displayName ?? user.displayName,
        'profile_picture_path': photoURL ?? user.photoURL,
        'updated_at': FieldValue.serverTimestamp(),
      });
      
      log('User profile updated successfully');
    } catch (e) {
      log('Error updating user profile: $e');
      throw Exception('Failed to update profile. Please try again.');
    }
  }
  
  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;
      
      final doc = await _firestore
          .collection('user_profiles')
          .doc(user.uid)
          .get();
      
      return doc.data();
    } catch (e) {
      log('Error getting user profile: $e');
      return null;
    }
  }
  
  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('No user logged in');
      
      // Delete user data from Firestore (optional - you might want to keep for audit)
      // await _firestore.collection('user_profiles').doc(user.uid).delete();
      
      // Delete Firebase Auth account
      await user.delete();
      
      log('User account deleted successfully');
    } catch (e) {
      log('Error deleting user account: $e');
      throw Exception('Failed to delete account. Please try again.');
    }
  }
}