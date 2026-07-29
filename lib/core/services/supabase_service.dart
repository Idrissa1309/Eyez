import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static String get _url => dotenv.get('SUPABASE_URL');
  static String get _anonKey => dotenv.get('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      anonKey: _anonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp(String email, String password, String username) async {
    return await client.auth.signUp(
      email: email, 
      password: password,
      data: {'username': username},
    );
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // --- Saved Lists Methods ---

  static Future<List<Map<String, dynamic>>> getSavedItems() async {
    final user = currentUser;
    if (user == null) return [];
    
    final response = await client
        .from('saved_lists')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> toggleSavedItem(Map<String, dynamic> movie) async {
    final user = currentUser;
    if (user == null) return;

    final tmdbId = movie['id'];
    
    // Check if exists
    final existing = await client
        .from('saved_lists')
        .select()
        .eq('user_id', user.id)
        .eq('tmdb_id', tmdbId)
        .maybeSingle();

    if (existing != null) {
      // Remove
      await client
          .from('saved_lists')
          .delete()
          .eq('user_id', user.id)
          .eq('tmdb_id', tmdbId);
    } else {
      // Add
      await client.from('saved_lists').insert({
        'user_id': user.id,
        'tmdb_id': tmdbId,
        'title': movie['title'] ?? movie['name'] ?? 'Unknown',
        'poster_path': movie['poster_path'],
        'media_type': movie['release_date'] != null ? 'movie' : 'tv',
      });
    }
  }
}
