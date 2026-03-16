import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';
import '../models/user_profile_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _isLoadingProfile = false;

  User? get user => _user;
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isLoadingProfile => _isLoadingProfile;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _user = SupabaseConfig.client.auth.currentUser;
    if (_user != null) {
      _loadUserProfile();
    }
    SupabaseConfig.client.auth.onAuthStateChange.listen((data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadUserProfile();
      } else {
        _userProfile = null;
        notifyListeners();
      }
    });
  }

  Future<void> _loadUserProfile() async {
    if (_user == null) return;
    _isLoadingProfile = true;
    notifyListeners();
    try {
      final response = await SupabaseConfig.client
          .from('profiles')
          .select()
          .eq('id', _user!.id)
          .maybeSingle();
      
      if (response != null) {
        _userProfile = UserProfile.fromJson(response);
      } else {
        // Create profile if it doesn't exist
        await SupabaseConfig.client.from('profiles').insert({
          'id': _user!.id,
          'email': _user!.email ?? '',
        });
        _userProfile = UserProfile(
          id: _user!.id,
          email: _user!.email ?? '',
        );
      }
    } catch (e) {
      debugPrint('Load user profile error: $e');
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
  }) async {
    if (_user == null) throw Exception('Kullanıcı giriş yapmamış');
    
    _isLoadingProfile = true;
    notifyListeners();
    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (username != null) updates['username'] = username;
      updates['updated_at'] = DateTime.now().toIso8601String();

      await SupabaseConfig.client
          .from('profiles')
          .update(updates)
          .eq('id', _user!.id);

      await _loadUserProfile();
    } catch (e) {
      debugPrint('Update profile error: $e');
      rethrow;
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await SupabaseConfig.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      _user = SupabaseConfig.client.auth.currentUser;
      if (_user != null) {
        await _loadUserProfile();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await SupabaseConfig.client.auth.signUp(
        email: email,
        password: password,
      );
      _user = SupabaseConfig.client.auth.currentUser;
      if (_user != null) {
        await _loadUserProfile();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await SupabaseConfig.client.auth.signOut();
    } finally {
      // Web'de onAuthStateChange bazen gecikmeli tetiklenebilir;
      // state'i hemen güncelle ki UI çıkışı yansıtsın.
      _user = null;
      _userProfile = null;
      notifyListeners();
    }
  }
}
