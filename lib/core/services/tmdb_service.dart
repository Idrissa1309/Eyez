import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class TMDBService {
  Dio get _dio {
    final key = dotenv.get('TMDB_API_KEY', fallback: '').trim();
    
    return Dio(BaseOptions(
      baseUrl: 'https://api.themoviedb.org/3',
      queryParameters: {
        'api_key': key,
        'language': 'fr-FR',
      },
    ));
  }

  static const String imageBaseUrl = 'https://image.tmdb.org/t/p/w500';

  static const Map<String, String> languageMap = {
    'fr': 'Français',
    'en': 'Anglais',
    'es': 'Espagnol',
    'de': 'Allemand',
    'it': 'Italien',
    'ja': 'Japonais',
    'ko': 'Coréen',
    'zh': 'Chinois',
    'pt': 'Portugais',
    'ru': 'Russe',
  };

  static String getLanguageName(String? code) {
    if (code == null) return 'Inconnue';
    final lowerCode = code.toLowerCase();
    return languageMap[lowerCode] ?? code.toUpperCase();
  }

  Future<List<Map<String, dynamic>>> getGenres() async {
    try {
      final movieGenres = await _dio.get('/genre/movie/list');
      final tvGenres = await _dio.get('/genre/tv/list');
      
      final List<dynamic> allGenres = [
        ...movieGenres.data['genres'],
        ...tvGenres.data['genres'],
      ];
      
      // Remove duplicates by ID
      final seenIds = <int>{};
      final uniqueGenres = <Map<String, dynamic>>[];
      for (var g in allGenres) {
        if (seenIds.add(g['id'])) {
          uniqueGenres.add(Map<String, dynamic>.from(g));
        }
      }
      return uniqueGenres;
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getTrending() async {
    try {
      final response = await _dio.get('/trending/all/day');
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        final msg = e.response?.data['status_message'] ?? e.message;
        throw Exception('TMDB API Error: $msg');
      }
      throw Exception('Failed to fetch trending: $e');
    }
  }

  Future<List<dynamic>> getPopularMovies() async {
    try {
      final response = await _dio.get('/movie/popular');
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch popular movies: $e');
    }
  }

  Future<List<dynamic>> getPopularTVShows() async {
    try {
      final response = await _dio.get('/tv/popular');
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch TV shows: $e');
    }
  }

  Future<List<dynamic>> getAnimes() async {
    try {
      final response = await _dio.get('/discover/movie', queryParameters: {
        'with_genres': '16', // Animation
      });
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch animes: $e');
    }
  }

  Future<List<dynamic>> getMusicContent() async {
    try {
      final response = await _dio.get('/discover/movie', queryParameters: {
        'with_genres': '10402', // Music
      });
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch music content: $e');
    }
  }

  Future<List<dynamic>> search(String query) async {
    try {
      final response = await _dio.get('/search/multi', queryParameters: {'query': query});
      return response.data['results'];
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to search: $e');
    }
  }

  Future<Map<String, dynamic>> getDetails(int id, String type) async {
    try {
      final response = await _dio.get('/$type/$id', queryParameters: {
        'append_to_response': 'videos,watch/providers',
      });
      return response.data;
    } catch (e) {
      if (e is DioException) {
        throw Exception('TMDB API Error: ${e.response?.data['status_message'] ?? e.message}');
      }
      throw Exception('Failed to fetch details: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getTrendingWithVideos() async {
    try {
      final trending = await getTrending();
      
      // Fetch details for the top 15 trending items in parallel
      final List<Future<Map<String, dynamic>?>> detailFutures = trending.take(15).map((item) async {
        final id = item['id'];
        final type = item['media_type'] ?? 'movie';
        final isAnime = (item['genre_ids'] as List?)?.contains(16) ?? false;

        try {
          final details = await getDetails(id, type);
          final videos = details['videos']?['results'] as List<dynamic>?;
          
          if (videos != null && videos.isNotEmpty) {
            final trailer = videos.firstWhere(
              (v) => v['site'] == 'YouTube' && (v['type'] == 'Trailer' || v['type'] == 'Teaser'),
              orElse: () => videos.firstWhere((v) => v['site'] == 'YouTube', orElse: () => null),
            );

            if (trailer != null) {
              final List<String> platformNames = [];
              if (isAnime) platformNames.add('Crunchyroll');
              
              final regions = ['FR', 'US', 'JP'];
              for (var region in regions) {
                final providers = details['watch/providers']?['results']?[region]?['flatrate'] as List<dynamic>?;
                if (providers != null) {
                  for (var p in providers) {
                    final name = p['provider_name'] as String;
                    if (!platformNames.contains(name)) platformNames.add(name);
                  }
                }
              }

              if (platformNames.isEmpty) platformNames.add('Netflix');

              return <String, dynamic>{
                ...Map<String, dynamic>.from(item),
                'video_key': trailer['key'],
                'platforms': platformNames,
                'platform': platformNames.first,
                'accent_color': _getAccentColorForGenre(item['genre_ids']?.first),
              };
            }
          }
          return null;
        } catch (e) {
          debugPrint('Error fetching details for $id: $e');
          return null;
        }
      }).toList();

      final List<Map<String, dynamic>?> results = await Future.wait(detailFutures);
      return results.whereType<Map<String, dynamic>>().toList();
    } catch (e) {
      throw Exception('Failed to fetch trending with videos: $e');
    }
  }

  Color _getAccentColorForGenre(int? genreId) {
    if (genreId == null) return const Color(0xFF00D2FF); // Cyan
    
    // Map some genre IDs to colors
    switch (genreId) {
      case 28: return const Color(0xFFFF0000); // Action -> Red
      case 12: return const Color(0xFFFFA500); // Adventure -> Orange
      case 16: return const Color(0xFFFF2E93); // Animation -> Fuchsia
      case 35: return const Color(0xFFFFFF00); // Comedy -> Yellow
      case 80: return const Color(0xFF8B0000); // Crime -> Dark Red
      case 18: return const Color(0xFF9D44FF); // Drama -> Purple
      case 14: return const Color(0xFF00D2FF); // Fantasy -> Cyan
      case 27: return const Color(0xFF4A4A4A); // Horror -> Grey
      case 10749: return const Color(0xFFFF69B4); // Romance -> Pink
      case 878: return const Color(0xFF007BFF); // Science Fiction -> Blue
      default: return const Color(0xFF00D2FF);
    }
  }
}
