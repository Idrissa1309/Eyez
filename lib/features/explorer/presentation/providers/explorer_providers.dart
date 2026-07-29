import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tmdb_service.dart';

final tmdbServiceProvider = Provider((ref) => TMDBService());

final trendingProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(tmdbServiceProvider).getTrending();
});

final popularMoviesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(tmdbServiceProvider).getPopularMovies();
});

final selectedCategoryProvider = StateProvider<String>((ref) => "Pour toi");

final filteredContentProvider = FutureProvider<List<dynamic>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final service = ref.watch(tmdbServiceProvider);
  
  switch (category) {
    case "Films":
      return service.getPopularMovies();
    case "Séries":
      return service.getPopularTVShows();
    case "Animes":
      return service.getAnimes();
    case "Musique":
      return service.getMusicContent();
    case "Pour toi":
    default:
      return service.getTrending();
  }
});

final searchQueryProvider = StateProvider<String>((ref) => "");

final searchResultsProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return ref.watch(tmdbServiceProvider).search(query);
});
