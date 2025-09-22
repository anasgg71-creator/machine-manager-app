import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../models/user_profile.dart';

class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  UserProfile? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Check if user is already logged in
      final user = SupabaseService.currentUser;
      if (user != null) {
        await _loadUserProfile(user.id);
      }
    } catch (e) {
      _errorMessage = 'Failed to initialize auth: ${e.toString()}';
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Listen to auth state changes
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      if (user != null) {
        _loadUserProfile(user.id);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final profile = await SupabaseService.getCurrentUserProfile();
      _currentUser = profile;
      _errorMessage = null;
    } catch (e) {
      // If profile doesn't exist, create one
      if (e.toString().contains('not authenticated') || e.toString().contains('not found')) {
        try {
          final user = SupabaseService.currentUser;
          if (user != null) {
            // Create a basic profile for the user
            await SupabaseService.createUserProfile(
              userId: user.id,
              email: user.email ?? '',
              fullName: user.userMetadata?['full_name'] ?? 'User',
            );
            // Try loading again
            final profile = await SupabaseService.getCurrentUserProfile();
            _currentUser = profile;
            _errorMessage = null;
          }
        } catch (createError) {
          _errorMessage = 'Failed to create user profile: ${createError.toString()}';
          _currentUser = null;
        }
      } else {
        _errorMessage = 'Failed to load user profile: ${e.toString()}';
        _currentUser = null;
      }
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await SupabaseService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        return true;
      } else {
        _errorMessage = 'Login failed. Please check your credentials.';
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.message);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (response.user != null) {
        // Profile will be created automatically by trigger
        // Wait a moment for the trigger to complete
        await Future.delayed(const Duration(milliseconds: 500));
        await _loadUserProfile(response.user!.id);
        return true;
      } else {
        _errorMessage = 'Registration failed. Please try again.';
        return false;
      }
    } on AuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.message);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> signOut() async {
    try {
      _isLoading = true;
      notifyListeners();

      await SupabaseService.signOut();
      _currentUser = null;
      _errorMessage = null;
      return true;
    } catch (e) {
      _errorMessage = 'Failed to sign out: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      await SupabaseService.resetPassword(email);
      return true;
    } on AuthException catch (e) {
      _errorMessage = _getAuthErrorMessage(e.message);
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();

      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      await SupabaseService.updateProfile(updates);

      // Reload user profile
      if (_currentUser != null) {
        await _loadUserProfile(_currentUser!.id);
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: ${e.toString()}';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getAuthErrorMessage(String error) {
    // Convert Supabase auth errors to user-friendly messages
    if (error.toLowerCase().contains('invalid login credentials')) {
      return 'Invalid email or password. Please try again.';
    } else if (error.toLowerCase().contains('email not confirmed')) {
      return 'Please check your email and confirm your account.';
    } else if (error.toLowerCase().contains('too many requests')) {
      return 'Too many attempts. Please wait a moment before trying again.';
    } else if (error.toLowerCase().contains('user already registered')) {
      return 'An account with this email already exists.';
    } else if (error.toLowerCase().contains('password should be at least')) {
      return 'Password should be at least 6 characters long.';
    } else if (error.toLowerCase().contains('unable to validate email address')) {
      return 'Please enter a valid email address.';
    } else {
      return error;
    }
  }

  // Utility methods
  bool get isAdmin => _currentUser?.isAdmin ?? false;
  bool get isManager => _currentUser?.isManager ?? false;
  bool get isTechnician => _currentUser?.isTechnician ?? false;

  String get userDisplayName => _currentUser?.displayName ?? 'User';
  String get userInitials => _currentUser?.initials ?? '?';
  String get userRole => _currentUser?.role ?? 'member';
  int get userPoints => _currentUser?.points ?? 0;
  int get userTicketsSolved => _currentUser?.ticketsSolved ?? 0;
  double get userAverageRating => _currentUser?.averageRating ?? 0.0;
}