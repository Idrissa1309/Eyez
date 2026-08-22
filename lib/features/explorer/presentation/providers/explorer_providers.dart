import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../../core/constants/platform_constants.dart';

final tmdbServiceProvider = Provider((ref) => TMDBService());
final youtubeServiceProvider = Provider((ref) => YouTubeService());

final platformDetailsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, platformName) async {
  final foundKey = PlatformConstants.findKey(platformName);
  
  if (foundKey != null) {
    final data = PlatformConstants.platformData[foundKey]!;
    return {
      'name': foundKey,
      'logo': data['logo'],
      'banner': data['banner'],
      'description': data['description'],
      'subscribers': data['subscribers'],
      'is_youtube': false,
    };
  }

  // If not in constants, check YouTube
  final ytService = ref.watch(youtubeServiceProvider);
  final ytDetails = await ytService.getChannelDetails(platformName);
  
  if (ytDetails != null) {
    return {
      ...ytDetails,
      'is_youtube': true,
    };
  }

  // Fallback
  final fallback = PlatformConstants.getFallbackData(platformName);
  return {
    'name': platformName,
    'logo': fallback['logo'],
    'banner': fallback['banner'],
    'description': fallback['description'],
    'subscribers': fallback['subscribers'],
    'is_youtube': false,
  };
});

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
  final details = await ref.watch(platformDetailsProvider(platformName).future);
  
  if (details['is_youtube'] == true && details['id'] != null) {
    return ref.watch(youtubeServiceProvider).getChannelVideos(details['id']);
  }
  
  return ref.watch(tmdbServiceProvider).getMoviesByProvider(platformName);
});
