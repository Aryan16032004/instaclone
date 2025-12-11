import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  User? user;

  AuthService() {
    user = _supabase.auth.currentUser;
    _supabase.auth.onAuthStateChange.listen((data) {
      user = data.session?.user;
      notifyListeners();
    });
  }

  bool get isLoggedIn => user != null;

  Future<String?> register(String email, String password, String username) async {
    try {
      // 1. Sign up auth user
      final AuthResponse res = await _supabase.auth.signUp(
        email: email, 
        password: password,
      );

      // 2. Create profile entry in database
      if (res.user != null) {
        await _supabase.from('profiles').insert({
          'id': res.user!.id,
          'username': username,
          'email': email,
          'followers': [],
          'following': [],
        });
        user = res.user;
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "An unexpected error occurred: $e";
    }
  }

  Future<String?> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}