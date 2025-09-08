import 'package:flutter/material.dart';

// Mock User class to simulate Firebase User
class MockUser {
  final String uid;
  final String? email;
  final String? displayName;

  MockUser({required this.uid, this.email, this.displayName});
}

class AuthProvider extends ChangeNotifier {
  MockUser? _user;
  bool _isLoading = false;
  String? _errorMessage;

  MockUser? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider();

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Mock login with email and password
  Future<bool> login(String email, String password) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation - accept any email/password combination for demo
      if (email.isNotEmpty && password.isNotEmpty) {
        _user = MockUser(
          uid: 'mock-uid-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          displayName: email.split('@')[0], // Use part before @ as display name
        );
        _setLoading(false);
        return true;
      } else {
        _setError('Please enter both email and password');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Mock signup with email and password
  Future<bool> signup(String email, String password, String fullName) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Mock validation
      if (email.isNotEmpty && password.isNotEmpty && fullName.isNotEmpty) {
        if (password.length < 6) {
          _setError('Password should be at least 6 characters');
          _setLoading(false);
          return false;
        }

        _user = MockUser(
          uid: 'mock-uid-${DateTime.now().millisecondsSinceEpoch}',
          email: email,
          displayName: fullName,
        );
        _setLoading(false);
        return true;
      } else {
        _setError('Please fill in all fields');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Signup failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Mock password reset
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      if (email.isNotEmpty && email.contains('@')) {
        _setLoading(false);
        return true; // Simulate successful password reset email sent
      } else {
        _setError('Please enter a valid email address');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError('Password reset failed: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  // Mock logout
  Future<void> logout() async {
    _setLoading(true);

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    _user = null;
    _errorMessage = null;
    _setLoading(false);
  }

  // Mock get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_user == null) return null;

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return {
      'uid': _user!.uid,
      'email': _user!.email,
      'fullName': _user!.displayName,
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  // Mock update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> data) async {
    if (_user == null) return false;

    try {
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));

      // Update the mock user's display name if provided
      if (data.containsKey('fullName')) {
        _user = MockUser(
          uid: _user!.uid,
          email: _user!.email,
          displayName: data['fullName'],
        );
        notifyListeners();
      }

      return true;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
