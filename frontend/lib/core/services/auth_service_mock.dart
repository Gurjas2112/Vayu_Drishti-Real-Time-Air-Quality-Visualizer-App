import 'dart:async';
import '../models/user.dart';

class AuthService {
  // Mock current user for testing
  User? _currentUser;
  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  // Mock user data for testing
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'test@example.com': {
      'password': 'password123',
      'user': {
        'id': 'mock-user-1',
        'name': 'Test User',
        'email': 'test@example.com',
        'createdAt': DateTime.now().toIso8601String(),
      },
    },
    'admin@vayudrishti.com': {
      'password': 'admin123',
      'user': {
        'id': 'mock-admin-1',
        'name': 'Admin User',
        'email': 'admin@vayudrishti.com',
        'createdAt': DateTime.now().toIso8601String(),
      },
    },
  };

  // Get current user
  User? get currentUser => _currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _authStateController.stream;

  // Sign in with email and password (Mock implementation)
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    final mockUserData = _mockUsers[email];
    if (mockUserData != null && mockUserData['password'] == password) {
      _currentUser = User.fromJson(mockUserData['user']);
      _authStateController.add(_currentUser);
      return _currentUser;
    } else {
      throw Exception('Invalid email or password');
    }
  }

  // Create account with email and password (Mock implementation)
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (_mockUsers.containsKey(email)) {
      throw Exception('An account already exists with this email address');
    }

    // Create new mock user
    final newUser = User(
      id: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );

    // Store in mock database
    _mockUsers[email] = {'password': password, 'user': newUser.toJson()};

    _currentUser = newUser;
    _authStateController.add(_currentUser);
    return _currentUser;
  }

  // Sign out
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  // Reset password (Mock implementation)
  Future<void> resetPassword(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    if (!_mockUsers.containsKey(email)) {
      throw Exception('No user found with this email address');
    }

    // In a real app, this would send an email
    // For mock, we just simulate success
  }

  // Update user profile (Mock implementation)
  Future<void> updateUserProfile(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_currentUser?.id == user.id) {
      _currentUser = user;
      _authStateController.add(_currentUser);

      // Update mock database
      final email = user.email;
      if (_mockUsers.containsKey(email)) {
        _mockUsers[email]!['user'] = user.toJson();
      }
    }
  }

  // Delete user account (Mock implementation)
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      // Remove from mock database
      _mockUsers.remove(_currentUser!.email);
      _currentUser = null;
      _authStateController.add(null);
    }
  }

  // Dispose resources
  void dispose() {
    _authStateController.close();
  }
}
