import 'package:campus_mapper/features/Auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:developer' show log;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  String? _userPhotoURL;
  String? _userDisplayName;
  String? _userPhoneNumber;
  String? _userBio;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  // String? get userPhotoURL => _userPhotoURL;
  // String? get userDisplayName => _userDisplayName;
  String? get userPhoneNumber => _userPhoneNumber;
  String? get userBio => _userBio;

  AuthProvider() {
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      _currentUser = user;
      _errorMessage = null;
      _userPhotoURL = user?.photoURL;
      _userDisplayName = user?.displayName;
      _userPhoneNumber = user?.phoneNumber;
      notifyListeners();

      if (user != null) {
        log('User authenticated: ${user.uid}');
      } else {
        log('User signed out');
      }
    });
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signInWithGoogle();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.signOut();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? displayName,
    String? photoURL,
    String? phoneNumber,
    String? bio,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.updateUserProfile(
        displayName: displayName,
        photoURL: photoURL,
        phoneNumber: phoneNumber,
        bio: bio,
      );

      // Reload current user to get updated data
      await _currentUser?.reload();
      _currentUser = _authService.currentUser;
      _userPhotoURL = _currentUser?.photoURL;
      _userDisplayName = _currentUser?.displayName;
      _userPhoneNumber = _currentUser?.phoneNumber;

      // Notify listeners to update UI
      notifyListeners();

      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      return await _authService.getUserProfile();
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  /// Delete account
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();

      await _authService.deleteAccount();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  /// Get user display name
  String get userDisplayName {
    return _currentUser?.displayName ??
        _currentUser?.email?.split('@').first ??
        'User';
  }

  /// Get user email
  String get userEmail {
    return _currentUser?.email ?? '';
  }

  /// Get user photo URL
  String? get userPhotoURL {
    return _currentUser?.photoURL;
  }
}
