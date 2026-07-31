import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

final likeStatusProvider = FutureProvider.family<bool, String>((ref, videoId) async {
  return SupabaseService.isLiked(videoId);
});

final commentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, videoId) async {
  return SupabaseService.getComments(videoId);
});

final platformFollowStatusProvider = FutureProvider.family<bool, String>((ref, platformName) async {
  return SupabaseService.isFollowingPlatform(platformName);
});

final followedPlatformsProvider = FutureProvider<List<String>>((ref) async {
  return SupabaseService.getFollowedPlatforms();
});
