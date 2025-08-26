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
}