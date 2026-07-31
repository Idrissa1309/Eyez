import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  static String get _url => dotenv.get('SUPABASE_URL');
  static String get _publishabeKey => dotenv.get('SUPABASE_PUBLISHABLE_KEY');

  static Future<void> init() async {
    await Supabase.initialize(
      url: _url,
      publishableKey: _publishabeKey,
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

  static Future<void> updatePassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(
      password: newPassword,
    ));
  }

  // --- Saved Lists Methods ---

  static Future<List<Map<String, dynamic>>> getSavedItems() async {
    try {
      final user = currentUser;
      if (user == null) return [];
      
      final response = await client
          .from('saved_lists')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase Error (getSavedItems): $e');
      return [];
    }
  }

  static Future<void> toggleSavedItem(Map<String, dynamic> movie) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final tmdbId = movie['id'];
      
      final existing = await client
          .from('saved_lists')
          .select()
          .eq('user_id', user.id)
          .eq('tmdb_id', tmdbId)
          .maybeSingle();

      if (existing != null) {
        await client
            .from('saved_lists')
            .delete()
            .eq('user_id', user.id)
            .eq('tmdb_id', tmdbId);
      } else {
        await client.from('saved_lists').insert({
          'user_id': user.id,
          'tmdb_id': tmdbId,
          'title': movie['title'] ?? movie['name'] ?? 'Unknown',
          'poster_path': movie['poster_path'],
          'media_type': movie['release_date'] != null ? 'movie' : 'tv',
        });
      }
    } catch (e) {
      debugPrint('Supabase Error (toggleSavedItem): $e');
    }
  }

  // --- Social Interactions ---

  static Future<bool> isLiked(String videoId) async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      final response = await client
          .from('likes')
          .select()
          .eq('user_id', user.id)
          .eq('video_id', videoId)
          .maybeSingle();
          
      return response != null;
    } catch (e) {
      debugPrint('Supabase Error (isLiked): $e');
      return false;
    }
  }

  static Future<void> toggleLike(String videoId) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final liked = await isLiked(videoId);
      if (liked) {
        await client.from('likes').delete().eq('user_id', user.id).eq('video_id', videoId);
      } else {
        await client.from('likes').insert({'user_id': user.id, 'video_id': videoId});
      }
    } catch (e) {
      debugPrint('Supabase Error (toggleLike): $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getComments(String videoId) async {
    try {
      final response = await client
          .from('comments')
          .select()
          .eq('video_id', videoId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase Error (getComments): $e');
      return [];
    }
  }

  static Future<void> postComment(String videoId, String content) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await client.from('comments').insert({
        'user_id': user.id,
        'video_id': videoId,
        'content': content,
        'username': user.userMetadata?['username'] ?? 'Utilisateur',
      });
    } catch (e) {
      debugPrint('Supabase Error (postComment): $e');
    }
  }

  // --- Follows Methods ---

  static Future<bool> isFollowing(String targetUserId) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final response = await client
          .from('follows')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('Supabase Error (isFollowing): $e');
      return false;
    }
  }

  static Future<void> toggleFollow(String targetUserId) async {
    try {
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
    } catch (e) {
      debugPrint('Supabase Error (toggleFollow): $e');
    }
  }

  // --- Platform Subscriptions ---

  static Future<bool> isFollowingPlatform(String platformName) async {
    try {
      final user = currentUser;
      if (user == null) return false;

      final response = await client
          .from('platform_follows')
          .select()
          .eq('user_id', user.id)
          .eq('platform_name', platformName)
          .maybeSingle();

      return response != null;
    } catch (e) {
      // Return false if table is missing or network error
      debugPrint('Supabase Error (isFollowingPlatform): $e');
      return false;
    }
  }

  static Future<void> togglePlatformFollow(String platformName) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final following = await isFollowingPlatform(platformName);
      if (following) {
        await client
            .from('platform_follows')
            .delete()
            .eq('user_id', user.id)
            .eq('platform_name', platformName);
      } else {
        await client.from('platform_follows').insert({
          'user_id': user.id,
          'platform_name': platformName,
        });
      }
    } catch (e) {
      debugPrint('Supabase Error (togglePlatformFollow): $e');
    }
  }

  static Future<List<String>> getFollowedPlatforms() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final response = await client
          .from('platform_follows')
          .select('platform_name')
          .eq('user_id', user.id);
          
      return (response as List).map((e) => e['platform_name'] as String).toList();
    } catch (e) {
      debugPrint('Supabase Error (getFollowedPlatforms): $e');
      return []; // Return empty list instead of error
    }
  }

  // --- Profile Methods ---

  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final response = await client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();
          
      return response;
    } catch (e) {
      debugPrint('Supabase Error (getUserProfile): $e');
      return null;
    }
  }

  static Future<void> updateProfile({required String username, String? bio}) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await client.from('profiles').upsert({
        'id': user.id,
        'username': username,
        'bio': bio,
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      await client.auth.updateUser(UserAttributes(
        data: {'username': username},
      ));
    } catch (e) {
      debugPrint('Supabase Error (updateProfile): $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLikedMovies() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final response = await client
          .from('likes')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase Error (getLikedMovies): $e');
      return [];
    }
  }

  // --- History Methods ---

  static Future<void> addToHistory(Map<String, dynamic> movie) async {
    try {
      final user = currentUser;
      if (user == null) return;

      final tmdbId = movie['id'];
      if (tmdbId == null) return;

      await client.from('watched_history').upsert({
        'user_id': user.id,
        'tmdb_id': tmdbId,
        'title': movie['title'] ?? movie['name'] ?? 'Inconnu',
        'poster_path': movie['poster_path'],
        'watched_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, tmdb_id');
    } catch (e) {
      debugPrint('Supabase Error (addToHistory): $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getHistory() async {
    try {
      final user = currentUser;
      if (user == null) return [];

      final response = await client
          .from('watched_history')
          .select()
          .eq('user_id', user.id)
          .order('watched_at', ascending: false);
          
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Supabase Error (getHistory): $e');
      return [];
    }
  }
}
