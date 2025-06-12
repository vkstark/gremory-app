import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../utils/logger.dart';

class AuthProvider extends ChangeNotifier {
  final UserService _userService = UserService();
  User? _currentUser;
  List<User> _availableUsers = [];
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  List<User> get availableUsers => _availableUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _currentUser != null && !_currentUser!.isGuest;
  bool get isGuest => _currentUser != null && _currentUser!.isGuest;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId != null && userId > 0) {
        // Load existing user from backend
        try {
          _currentUser = await _userService.getUserById(userId);
        } catch (e) {
          Logger.error('Failed to load user from backend', 'AuthProvider', e);
          // Create guest user if backend fails
          await _createGuestUser();
        }
      } else {
        // Create guest user
        await _createGuestUser();
      }

      // Load available users for switching
      await loadAvailableUsers();
    } catch (e) {
      _error = 'Failed to initialize user: $e';
      await _createGuestUser();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _createGuestUser() async {
    _currentUser = User(
      id: 0,
      displayName: 'Guest User',
      userType: 'guest',
      status: 'active',
      languagePreference: 'en',
      timezone: 'UTC',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await _saveUserToPrefs(_currentUser!);
  }

  Future<void> loadAvailableUsers() async {
    try {
      _availableUsers = await _userService.getAllUsers(
        status: 'active',
        perPage: 50,
      );
      notifyListeners();
    } catch (e) {
      Logger.error('Failed to load available users', 'AuthProvider', e);
    }
  }

  Future<void> registerUser({
    String? username,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? timezone = 'UTC',
    String? languagePreference = 'en',
    String? birthdate,
    List<String>? interests,
    List<String>? goals,
    String? experienceLevel,
    String? communicationStyle,
    dynamic contentPreferences,
    String? onboardingSource,
    String? industry,
    String? role,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _userService.createUser(
        username: username,
        email: email,
        displayName: displayName,
        userType: 'registered',
        phoneNumber: phoneNumber,
        timezone: timezone ?? 'UTC',
        languagePreference: languagePreference ?? 'en',
        birthdate: birthdate,
        interests: interests,
        goals: goals,
        experienceLevel: experienceLevel,
        communicationStyle: communicationStyle,
        contentPreferences: contentPreferences,
        onboardingSource: onboardingSource,
        industry: industry,
        role: role,
      );

      _currentUser = user;
      await _saveUserToPrefs(user);
      await loadAvailableUsers(); // Refresh the user list
    } catch (e) {
      _error = 'Failed to register user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> switchToUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Reload user data from backend to ensure it's current
      final freshUser = await _userService.getUserById(user.id);
      _currentUser = freshUser;
      await _saveUserToPrefs(freshUser);
    } catch (e) {
      _error = 'Failed to switch to user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createAndSwitchToNewUser({
    String? username,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? timezone,
    String? languagePreference,
    String? birthdate,
    List<String>? interests,
    List<String>? goals,
    String? experienceLevel,
    String? communicationStyle,
    dynamic contentPreferences,
    String? onboardingSource,
    String? industry,
    String? role,
  }) async {
    await registerUser(
      username: username,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
      timezone: timezone,
      languagePreference: languagePreference,
      birthdate: birthdate,
      interests: interests,
      goals: goals,
      experienceLevel: experienceLevel,
      communicationStyle: communicationStyle,
      contentPreferences: contentPreferences,
      onboardingSource: onboardingSource,
      industry: industry,
      role: role,
    );
  }

  Future<void> updateUserProfile({
    String? username,
    String? email,
    String? displayName,
    String? phoneNumber,
    String? timezone,
    String? languagePreference,
  }) async {
    if (_currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _userService.updateUserProfile(
        userId: _currentUser!.id,
        username: username,
        email: email,
        displayName: displayName,
        phoneNumber: phoneNumber,
        timezone: timezone,
        languagePreference: languagePreference,
      );

      _currentUser = updatedUser;
      await _saveUserToPrefs(updatedUser);
      await loadAvailableUsers(); // Refresh the user list
    } catch (e) {
      _error = 'Failed to update profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> upgradeToRegisteredUser({
    String? username,
    String? email,
    String? displayName,
    String? phoneNumber,
  }) async {
    await registerUser(
      username: username,
      email: email,
      displayName: displayName,
      phoneNumber: phoneNumber,
    );
  }

  Future<void> deleteUser(int userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.deleteUser(userId);

      // If we deleted the current user, switch to guest
      if (_currentUser?.id == userId) {
        await _createGuestUser();
      }

      await loadAvailableUsers(); // Refresh the user list
    } catch (e) {
      _error = 'Failed to delete user: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> seedTestUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _userService.seedTestUsers();
      await loadAvailableUsers(); // Refresh the user list
    } catch (e) {
      _error = 'Failed to seed test users: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _createGuestUser();
    notifyListeners();
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id);
    if (user.username != null) await prefs.setString('username', user.username!);
    if (user.email != null) await prefs.setString('user_email', user.email!);
    await prefs.setString('user_display_name', user.displayName);
    await prefs.setString('user_type', user.userType);
    await prefs.setString('user_status', user.status);
    await prefs.setString('language_preference', user.languagePreference);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> editUserProfile(int userId, Map<String, dynamic> details) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final updatedUser = await _userService.editUserProfile(userId, details);
      _currentUser = updatedUser;
      await _saveUserToPrefs(updatedUser);
      await loadAvailableUsers();
    } catch (e) {
      _error = 'Failed to update profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
