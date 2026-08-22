import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';

class MyListNotifier extends AsyncNotifier<List<Map<String, dynamic>>> {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    return SupabaseService.getSavedItems();
  }

  Future<void> toggleItem(Map<String, dynamic> movie) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.toggleSavedItem(movie);
      // Refresh the list after toggle
      state = AsyncValue.data(await SupabaseService.getSavedItems());
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  bool isSaved(Object? tmdbId) {
    if (tmdbId == null) return false;
    final id = tmdbId.toString();
    return state.value?.any((item) => item['tmdb_id'].toString() == id) ?? false;
  }
}

final myListProvider = AsyncNotifierProvider<MyListNotifier, List<Map<String, dynamic>>>(() {
  return MyListNotifier();
});
