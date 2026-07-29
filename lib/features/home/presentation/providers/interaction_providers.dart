import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

final likeStatusProvider = FutureProvider.family<bool, String>((ref, videoId) async {
  return SupabaseService.isLiked(videoId);
});

final commentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, videoId) async {
  return SupabaseService.getComments(videoId);
});
