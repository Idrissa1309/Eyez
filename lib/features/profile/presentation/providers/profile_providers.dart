import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

final profileDataProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return SupabaseService.getUserProfile();
});

final likedMoviesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return SupabaseService.getLikedMovies();
});

final profileStatsProvider = Provider<Map<String, int>>((ref) {
  final likedCount = ref.watch(likedMoviesProvider).value?.length ?? 0;
  // Note: List count can be fetched from myListProvider in profile screen
  return {
    'likes': likedCount,
  };
});
