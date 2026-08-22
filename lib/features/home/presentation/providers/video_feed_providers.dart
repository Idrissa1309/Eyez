import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../explorer/presentation/providers/explorer_providers.dart';

/// YouTube direct stream URLs are signed and stop working after ~6 hours.
const resolvedUrlTtl = Duration(hours: 5, minutes: 30);

/// In-memory cache for direct video URLs (MP4) to avoid re-resolving YouTube keys.
/// Values are {'url': String, 'ts': int (epoch ms)}.
final resolvedVideoUrlsProvider = StateProvider<Map<String, Map<String, dynamic>>>((ref) => {});

const _resolvedUrlsPrefsKey = 'resolved_video_urls';

bool _isFresh(Map<String, dynamic>? entry) {
  if (entry == null) return false;
  final ts = entry['ts'];
  final url = entry['url'];
  if (ts is! int || url is! String || url.isEmpty) return false;
  return DateTime.now().millisecondsSinceEpoch - ts < resolvedUrlTtl.inMilliseconds;
}

/// Pure cache lookup usable from both [Ref] and [WidgetRef] contexts.
String? freshUrlFromEntry(Map<String, dynamic>? entry) {
  if (entry == null || !_isFresh(entry)) return null;
  return entry['url'] as String;
}

/// Returns the cached direct URL for [videoKey] if it exists AND is still
/// fresh enough to be playable, otherwise null.
String? getFreshResolvedUrl(WidgetRef ref, String videoKey) {
  return freshUrlFromEntry(ref.read(resolvedVideoUrlsProvider)[videoKey]);
}

/// Restores the persisted direct-URL cache into [resolvedVideoUrlsProvider]
/// so previously resolved YouTube keys are reused across app launches.
/// Expired entries (and legacy entries without a timestamp) are dropped.
Future<void> loadResolvedVideoUrlsCache(WidgetRef ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_resolvedUrlsPrefsKey);
    if (cached == null || cached.isEmpty) return;

    final decoded = Map<String, dynamic>.from(jsonDecode(cached) as Map);
    final urls = <String, Map<String, dynamic>>{};
    decoded.forEach((key, value) {
      if (value is Map) {
        final entry = Map<String, dynamic>.from(value);
        if (_isFresh(entry)) urls[key.toString()] = entry;
      }
      // Legacy plain-string values have unknown age -> treat as expired.
    });
    if (urls.isNotEmpty) {
      ref.read(resolvedVideoUrlsProvider.notifier).update((state) => {...state, ...urls});
    }
  } catch (_) {
    // Ignore corrupt or missing cache
  }
}

/// Stores a freshly resolved URL both in memory and in [SharedPreferences]
/// to limit the number of YouTube manifest resolutions (rate limiting).
Future<void> cacheResolvedVideoUrl(WidgetRef ref, String videoKey, String url) async {
  final entry = <String, dynamic>{
    'url': url,
    'ts': DateTime.now().millisecondsSinceEpoch,
  };
  ref.read(resolvedVideoUrlsProvider.notifier).update((state) => {...state, videoKey: entry});
  await _persistResolvedUrls(ref.read(resolvedVideoUrlsProvider));
}

Future<void> _persistResolvedUrls(Map<String, Map<String, dynamic>> urls) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_resolvedUrlsPrefsKey, jsonEncode(urls));
  } catch (_) {
    // Ignore persistence failures
  }
}

/// Fast initial feed: fetches TMDB trending with minimal enrichment.
/// YouTube videos are fetched separately and merged in background.
/// The user sees TMDB content within ~1-2 seconds instead of waiting 10+ seconds.
final tmdbVideoFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final tmdbService = ref.watch(tmdbServiceProvider);

  // Fast TMDB preview: 1 trending call + only 5 enriched items ≈ 600ms
  final preview = await tmdbService.getTrendingPreview(previewCount: 5);

  return preview..shuffle();
});

/// YouTube cinematic videos – loaded separately and merged into the feed
/// by the UI layer once ready. This prevents blocking the initial render.
final youtubeFeedProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final ytService = ref.watch(youtubeServiceProvider);
  return ytService.getCinematicVideos();
});

/// Resolves direct stream URLs for UPCOMING videos in the background so that
/// swiping to the next item starts playback instantly instead of waiting for
/// a fresh YouTube manifest resolution (2-5s).
///
/// Resolutions are strictly serialized with a small pause between each one to
/// stay under YouTube's rate-limiting radar.
final videoPreloaderProvider = Provider<VideoPreloader>((ref) => VideoPreloader(ref));

class VideoPreloader {
  VideoPreloader(this._ref);

  final Ref _ref;
  final List<String> _queue = [];
  bool _running = false;

  /// Queues the videos right after [focusIndex] (up to 3 ahead).
  void preloadAround(List<Map<String, dynamic>> videos, int focusIndex) {
    for (int i = focusIndex; i < focusIndex + 3 && i < videos.length; i++) {
      final key = videos[i]['video_key'];
      if (key is! String || key.isEmpty || _queue.contains(key)) continue;
      if (freshUrlFromEntry(_ref.read(resolvedVideoUrlsProvider)[key]) != null) continue;
      _queue.add(key);
    }
    _pump();
  }

  Future<void> _pump() async {
    if (_running) return;
    _running = true;
    try {
      while (_queue.isNotEmpty) {
        final ytService = _ref.read(youtubeServiceProvider);

        // YouTube is blocking extraction: stop hammering it entirely, the
        // player falls back to the embedded player in the meantime.
        if (ytService.isRateLimited) {
          _queue.clear();
          break;
        }

        final key = _queue.removeAt(0);
        // Already resolved while queued (or by the player itself)?
        if (freshUrlFromEntry(_ref.read(resolvedVideoUrlsProvider)[key]) != null) continue;

        try {
          final url = await ytService.resolveStreamUrl(key);
          if (url != null) {
            final notifier = _ref.read(resolvedVideoUrlsProvider.notifier);
            notifier.update((state) => {
              ...state,
              key: {'url': url, 'ts': DateTime.now().millisecondsSinceEpoch},
            });
            await _persistResolvedUrls(_ref.read(resolvedVideoUrlsProvider));
          }
        } catch (_) {
          // Unexpected failure: leave uncached, the player's own fallback
          // (embedded iframe) will take over when needed.
        }

        // If this resolution just tripped the breaker, drop the rest.
        if (_ref.read(youtubeServiceProvider).isRateLimited) {
          _queue.clear();
          break;
        }

        // Gentle spacing between manifest requests.
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    } finally {
      _running = false;
    }
  }
}
