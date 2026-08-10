import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tmdb_service.dart';

final tmdbServiceProvider = Provider((ref) => TMDBService());

final trendingProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(tmdbServiceProvider).getTrendingEnriched();
});

final popularMoviesProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.watch(tmdbServiceProvider).getPopularMovies();
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'Pour toi');
final selectedGenreProvider = StateProvider<int?>((ref) => null);
final selectedPlatformProvider = StateProvider<String?>((ref) => null);

final filteredContentProvider = FutureProvider<List<dynamic>>((ref) async {
  final category = ref.watch(selectedCategoryProvider);
  final genreId = ref.watch(selectedGenreProvider);
  final platformName = ref.watch(selectedPlatformProvider);
  final service = ref.watch(tmdbServiceProvider);
  
  if (platformName != null) {
    return service.getMoviesByProvider(platformName);
  }

  if (genreId != null) {
    return service.getMoviesByGenre(genreId);
  }

  switch (category) {
    case 'Films':
      return service.getPopularMovies();
    case 'Séries':
      return service.getPopularTVShows();
    case 'Animes':
      return service.getAnimes();
    case 'Musique':
      return service.getMusicContent();
    case 'Pour toi':
    default:
      return service.getTrendingEnriched();
  }
});

final searchQueryProvider = StateProvider<String>((ref) => '');

final searchResultsProvider = FutureProvider<List<dynamic>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];
  return ref.watch(tmdbServiceProvider).search(query);
});

final platformContentProvider = FutureProvider.family<List<dynamic>, String>((ref, platformName) async {
  return ref.watch(tmdbServiceProvider).getMoviesByProvider(platformName);
});
