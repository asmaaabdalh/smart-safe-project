// supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../main.dart';

class SupabaseService {
 
 /// Function to sign in a user using email and password
 Future<String?> signInWithPassword({
  required String email,
  required String password,
 }) async {
  try {
   final AuthResponse res = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
   );
   if (res.session != null) {
    return null;
   }
   return 'Sign-in failed: No session available';
  } on AuthException catch (e) {
   return e.message;
  } catch (e) {
   return 'An unexpected error occurred: ${e.toString()}';
  }
 }

 /// Function to create a new user account using email and password
 Future<String?> signUp({
  required String email,
  required String password,
 }) async {
  try {
   final AuthResponse res = await supabase.auth.signUp(
    email: email,
    password: password,
   );
   if (kIsWeb) {
    if (res.session != null) {
     return null;
    }
   } else {
    if (res.user != null) {
     return 'A confirmation link has been sent to your email';
    }
   }
   return 'Account creation failed: No user available';
  } on AuthException catch (e) {
   return e.message;
  } catch (e) {
   return 'An unexpected error occurred: ${e.toString()}';
  }
 }

 /// Function to sign out a user
 Future<String?> signOut() async {
  try {
   await supabase.auth.signOut();
   return null; // No error, the operation was successful
  } on AuthException catch (e) {
   return e.message;
  } catch (e) {
   return 'An unexpected error occurred: ${e.toString()}';
  }
 }
 Future<List<Map<String, dynamic>>> getAccessLogs() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return []; // Return empty list if no user is logged in
    }

    try {
      final response = await supabase
          .from('access_logs')
          .select()
          .eq('user_id', userId) // Filter by the current user's ID
          .order('created_at', ascending: false); // Order by newest first
      
      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      print('Error fetching access logs: $e');
      return [];
    }
  }

  // 👇🏼 NEW: This function records an access event.
  Future<void> recordAccessLog(String action) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print('Warning: Cannot record log, no user is signed in.');
      return;
    }
    try {
      await supabase.from('access_logs').insert({
        'user_id': userId,
        'action': action,
      });
    } catch (e) {
      print('Error recording access log: $e');
    }
  }

  Future<String?> resetPasswordForEmail(String email) async {
    try {
      await supabase.auth.resetPasswordForEmail(
        email,
        // تأكد أن هذا الرابط هو الصحيح ويتطابق مع ما في Supabase Dashboard
        redirectTo: 'https://my-safe-control-1.web.app/#/update-password',
      );
      return null;
    } on AuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'An unexpected error occurred: ${e.toString()}';
    }
  }
}