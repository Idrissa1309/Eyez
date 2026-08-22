import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

const _ytCinematicCacheKey = 'yt_cinematic_cache';
const _ytCinematicCacheExpiryKey = 'yt_cinematic_cache_expiry';
const _cacheDuration = Duration(hours: 1);

class YouTubeService {
  final _yt = YoutubeExplode();

  /// Expose the underlying YoutubeExplode instance for direct stream/manifest access.
  YoutubeExplode get yt => _yt;

  // --- Circuit breaker against YouTube rate limiting ---
  // When YouTube starts rejecting watch-page requests (RequestLimitExceeded),
  // hammering it further only extends the block. We stop all stream
  // extraction for a while and let the embedded player take over.
  DateTime? _rateLimitedUntil;
  int _rateLimitStrikes = 0;

  static const _cooldownSteps = [Duration(minutes: 1), Duration(minutes: 2), Duration(minutes: 5), Duration(minutes: 10)];

  /// True while YouTube is blocking stream extraction for this IP.
  bool get isRateLimited {
    final until = _rateLimitedUntil;
    return until != null && DateTime.now().isBefore(until);
  }

  void _markRateLimited() {
    final strike = _rateLimitStrikes.clamp(0, _cooldownSteps.length - 1);
    _rateLimitedUntil = DateTime.now().add(_cooldownSteps[strike]);
    _rateLimitStrikes = (strike + 1).clamp(1, _cooldownSteps.length);
    debugPrint('YouTube rate limit detected: pausing stream extraction until $_rateLimitedUntil');
  }

  void _markHealthy() {
    _rateLimitedUntil = null;
    _rateLimitStrikes = 0;
  }

  /// Resolves the best muxed stream URL for [videoKey], or null when
  /// unavailable (currently rate-limited, blocked or transient failure).
  ///
  /// Returns null immediately while the circuit breaker is open.
  Future<String?> resolveStreamUrl(String videoKey) async {
    if (isRateLimited) return null;
    try {
      final manifest = await yt.videos.streamsClient.getManifest(videoKey);
      _markHealthy();
      final muxed = manifest.muxed.sortByBitrate();
      if (muxed.isEmpty) return null;
      return muxed.first.url.toString();
    } catch (e) {
      if (e is RequestLimitExceededException) {
        _markRateLimited();
      } else if (e is StateError) {
        // No playable muxed stream for this video: expected for some
        // uploads, the embedded player takes over. Stay silent.
      } else {
        debugPrint('Stream resolution failed for $videoKey: $e');
      }
      return null;
    }
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), '')
        .replaceAll(RegExp(r'official\s*(trailer|teaser|movie|video|4k|hd|music video|lyric video|audio|clip)', caseSensitive: false), '')
        .replaceAll(RegExp(r'\|.*'), '')
        .replaceAll(RegExp(r'\:.*'), '')
        .trim();
  }

  Future<Map<String, dynamic>?> getChannelDetails(String channelNameOrId) async {
    try {
      ChannelId channelId;
      if (channelNameOrId.startsWith('UC')) {
        channelId = ChannelId(channelNameOrId);
      } else {
        final search = await _yt.search.search(channelNameOrId, filter: TypeFilters.channel);
        if (search.isEmpty) return null;

        final results = search.whereType<SearchChannel>();
        if (results.isEmpty) return null;

        SearchChannel? exactMatch;
        for (final c in results) {
          if (c.name.toLowerCase() == channelNameOrId.toLowerCase()) {
            exactMatch = c;
            break;
          }
        }
        final channel = exactMatch ?? results.first;
        channelId = channel.id;
      }

      final fullChannel = await _yt.channels.get(channelId);

      // The about page endpoint is unreliable (crashes / rate-limited inside
      // youtube_explode_dart). Treat it as optional so the channel name, logo
      // and banner survive when it fails.
      String description = '';
      try {
        final about = await _yt.channels.getAboutPage(channelId);
        description = about.description ?? '';
      } catch (_) {
        debugPrint('About page unavailable for $channelNameOrId, continuing without it');
      }

      return {
        'id': channelId.value,
        'name': fullChannel.title,
        'logo': fullChannel.logoUrl,
        'banner': fullChannel.bannerUrl,
        'description': _decodeEntities(description),
        'subscribers': _formatSubscribers(fullChannel.subscribersCount),
      };
    } catch (e) {
      debugPrint('Error getting channel details: $e');
      return null;
    }
  }

  String _formatSubscribers(int? count) {
    if (count == null) return 'N/A';
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }

  Future<List<Map<String, dynamic>>> getChannelVideos(String channelId) async {
    List<Map<String, dynamic>> results = [];
    try {
      final channel = await _yt.channels.get(channelId);
      final uploads = _yt.channels.getUploads(channel.id);

      await for (final video in uploads.take(10)) {
        results.add({
          'id': video.id.value,
          'tmdb_id': video.id.value,
          'channel_id': video.channelId.value,
          'title': _cleanTitle(video.title),
          'overview': video.description,
          'video_key': video.id.value,
          'poster_path': null,
          'backdrop_path': video.thumbnails.highResUrl,
          'thumbnail_url': video.thumbnails.highResUrl,
          'accent_color': Colors.blueAccent,
          'platform': video.author,
          'platforms': [video.author],
          'original_language_name': 'YouTube',
          'is_youtube_direct': true,
        });
      }
    } catch (e) {
      debugPrint('Error getting channel videos: $e');
    }

    // youtube_explode_dart uploads are frequently empty or blocked by
    // YouTube; fall back to the official channel RSS feed which always works.
    if (results.isEmpty) {
      debugPrint('Channel uploads unavailable for $channelId, falling back to RSS feed');
      return _getChannelVideosFromRss(channelId);
    }
    return results;
  }

  /// Fetches the latest videos of a channel from its official, unauthenticated
  /// RSS feed (https://www.youtube.com/feeds/videos.xml?channel_id=...).
  Future<List<Map<String, dynamic>>> _getChannelVideosFromRss(String channelId) async {
    try {
      final response = await Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        responseType: ResponseType.plain,
      )).get<String>('https://www.youtube.com/feeds/videos.xml', queryParameters: {
        'channel_id': channelId,
      });

      final xml = response.data ?? '';
      return _parseChannelRss(xml, channelId);
    } catch (e) {
      debugPrint('RSS fallback failed for $channelId: $e');
      return [];
    }
  }

  /// Parses a YouTube channel RSS feed into feed items compatible with the app.
  List<Map<String, dynamic>> _parseChannelRss(String xml, String channelId) {
    final channelTitleMatch = RegExp(r'<title>([^<]+)</title>').firstMatch(xml);
    final channelName = _decodeEntities(channelTitleMatch?.group(1)?.trim() ?? 'YouTube');

    final entries = xml.split('<entry>').skip(1);
    final List<Map<String, dynamic>> results = [];

    for (final entry in entries) {
      final videoId = RegExp(r'<yt:videoId>([^<]+)</yt:videoId>').firstMatch(entry)?.group(1);
      if (videoId == null || videoId.isEmpty) continue;

      final title = RegExp(r'<title>([^<]+)</title>').firstMatch(entry)?.group(1) ?? '';
      final description =
          RegExp(r'<media:description>([\s\S]*?)</media:description>').firstMatch(entry)?.group(1) ?? '';
      final thumbnail =
          RegExp(r'<media:thumbnail[^>]+url="([^"]+)"').firstMatch(entry)?.group(1) ??
              'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';

      results.add({
        'id': videoId,
        'tmdb_id': videoId,
        'channel_id': channelId,
        'title': _cleanTitle(_decodeEntities(title)),
        'overview': _decodeEntities(description),
        'video_key': videoId,
        'poster_path': null,
        'backdrop_path': thumbnail,
        'thumbnail_url': thumbnail,
        'accent_color': Colors.blueAccent,
        'platform': channelName,
        'platforms': [channelName],
        'original_language_name': 'YouTube',
        'is_youtube_direct': true,
      });
    }
    return results;
  }

  String _decodeEntities(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'");
  }

  Future<List<Map<String, dynamic>>> getCinematicVideos() async {
    // 1. Try loading from cache first
    final cached = await _loadCinematicCache();
    if (cached != null && cached.isNotEmpty) {
      debugPrint('YouTube: Using ${cached.length} cached cinematic videos');
      return cached;
    }

    // 2. Cache miss or expired – fetch from YouTube
    try {
      final searchList = await _yt.search.search(
        'official movie trailers 4K',
        filter: TypeFilters.video,
      );

      final List<Map<String, dynamic>> results = [];

      for (final video in searchList.take(10)) {
        results.add({
          'id': video.id.value,
          'tmdb_id': video.id.value,
          'channel_id': video.channelId.toString(),
          'title': _cleanTitle(video.title),
          'overview': video.description,
          'video_key': video.id.value,
          'poster_path': null,
          'backdrop_path': video.thumbnails.highResUrl,
          'thumbnail_url': video.thumbnails.highResUrl,
          'accent_color': Colors.blueAccent,
          'platform': video.author,
          'platforms': [video.author],
          'original_language_name': 'YouTube',
          'is_youtube_direct': true,
        });
      }

      // 3. Persist to cache for next launch
      if (results.isNotEmpty) {
        await _saveCinematicCache(results);
      }

      return results;
    } catch (e) {
      debugPrint('YouTube Service Error: $e');
      return [];
    }
  }

  // --- Cache helpers ---

  Future<List<Map<String, dynamic>>?> _loadCinematicCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiryMs = prefs.getInt(_ytCinematicCacheExpiryKey);
      if (expiryMs == null) return null;
      if (DateTime.now().millisecondsSinceEpoch > expiryMs) {
        // Cache expired
        await prefs.remove(_ytCinematicCacheKey);
        await prefs.remove(_ytCinematicCacheExpiryKey);
        return null;
      }
      final raw = prefs.getString(_ytCinematicCacheKey);
      if (raw == null || raw.isEmpty) return null;
      final list = jsonDecode(raw) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveCinematicCache(List<Map<String, dynamic>> videos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_ytCinematicCacheKey, jsonEncode(videos));
      await prefs.setInt(
        _ytCinematicCacheExpiryKey,
        DateTime.now().add(_cacheDuration).millisecondsSinceEpoch,
      );
    } catch (_) {
      // Ignore persistence failures
    }
  }

  void dispose() {
    _yt.close();
  }
}
