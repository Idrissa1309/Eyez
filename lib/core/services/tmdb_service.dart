import 'package:dio/dio.dart';
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
}
