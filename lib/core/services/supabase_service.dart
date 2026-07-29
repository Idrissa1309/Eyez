import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseService {
  static String get _url => dotenv.get('SUPABASE_URL');
  //static String get _anonKey => dotenv.get('SUPABASE_ANON_KEY');
  static String get _publishableKey => dotenv.get('SUPABASE_ANON_KEY');

  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      //anonKey: _anonKey,
      publishableKey: _publishableKey
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

  // --- Social Interactions ---

  static Future<bool> isLiked(String videoId) async {
    final user = currentUser;
    if (user == null) return false;
    
    final response = await client
        .from('likes')
        .select()
        .eq('user_id', user.id)
        .eq('video_id', videoId)
        .maybeSingle();
        
    return response != null;
  }

  static Future<void> toggleLike(String videoId) async {
    final user = currentUser;
    if (user == null) return;

    final liked = await isLiked(videoId);
    if (liked) {
      await client.from('likes').delete().eq('user_id', user.id).eq('video_id', videoId);
    } else {
      await client.from('likes').insert({'user_id': user.id, 'video_id': videoId});
    }
  }

  static Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    final response = await client
        .from('comments')
        .select()
        .eq('video_id', videoId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  static Future<void> postComment(String videoId, String content) async {
    final user = currentUser;
    if (user == null) return;

    await client.from('comments').insert({
      'user_id': user.id,
      'video_id': videoId,
      'content': content,
      'username': user.userMetadata?['username'] ?? 'Utilisateur',
    });
  }

  // --- Follows Methods ---

  static Future<bool> isFollowing(String targetUserId) async {
    final user = currentUser;
    if (user == null) return false;

    final response = await client
        .from('follows')
        .select()
        .eq('follower_id', user.id)
        .eq('following_id', targetUserId)
        .maybeSingle();

    return response != null;
  }

  static Future<void> toggleFollow(String targetUserId) async {
    final user = currentUser;
    if (user == null) return;

    final following = await isFollowing(targetUserId);
    if (following) {
      await client
          .from('follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);
    } else {
      await client.from('follows').insert({
        'follower_id': user.id,
        'following_id': targetUserId,
      });
    }
  }
}
