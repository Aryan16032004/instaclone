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

  // 1. REGISTER with ALL details
  Future<String?> registerAllDetails({
    required String email, 
    required String phone, 
    required String username, 
    required String password
  }) async {
    try {
      // Create Auth User (Email is the unique identifier for Supabase Auth)
      final AuthResponse res = await _supabase.auth.signUp(
        email: email, 
        password: password,
      );

      if (res.user != null) {
        // Save ALL details to Profiles
        await _supabase.from('profiles').insert({
          'id': res.user!.id,
          'username': username,
          'email': email,
          'phone': phone,
          'followers': [],
          'following': [],
        });
        user = res.user;
      }
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Error: $e";
    }
  }

  // 2. Smart Login
  Future<String?> smartLogin(String input, String password) async {
    try {
      String emailToUse = input;

      // If input is NOT an email, look it up!
      if (!input.contains('@')) {
        final response = await _supabase
            .from('profiles')
            .select('email')
            .or('username.eq.$input, phone.eq.$input')
            .maybeSingle();

        if (response == null) {
          return "User not found with that Phone or Username.";
        }
        emailToUse = response['email'];
      }

      await _supabase.auth.signInWithPassword(email: emailToUse, password: password);
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return "Login failed: $e";
    }
  }
  
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }
}