import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

final historyProvider = StateNotifierProvider<HistoryNotifier, AsyncValue<List<Map<String, dynamic>>>>((ref) {
  return HistoryNotifier();
});

class HistoryNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  HistoryNotifier() : super(const AsyncValue.loading()) {
    loadHistory();
  }

  Future<void> loadHistory() async {
    state = const AsyncValue.loading();
    try {
      final items = await SupabaseService.getHistory();
      state = AsyncValue.data(items);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addToHistory(Map<String, dynamic> movie) async {
    try {
      await SupabaseService.addToHistory(movie);
      // Refresh local state if data is already loaded
      if (state.hasValue) {
        final current = state.value!;
        final tmdbId = movie['id'];
        
        // Remove if already exists to move to top
        final newList = current.where((item) => item['tmdb_id'] != tmdbId).toList();
        
        newList.insert(0, {
          'tmdb_id': tmdbId,
          'title': movie['title'] ?? movie['name'] ?? 'Inconnu',
          'poster_path': movie['poster_path'],
          'watched_at': DateTime.now().toIso8601String(),
        });
        
        state = AsyncValue.data(newList);
      }
    } catch (e) {
      // Fail silently for background updates
    }
  }
}
