import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/ambient_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/volume_provider.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/youtube_service.dart';
import '../../../explorer/presentation/providers/explorer_providers.dart';
import '../widgets/interaction_overlay.dart';
import '../widgets/movie_details_sheet.dart';
import '../widgets/platform_popup.dart';
import '../providers/video_feed_providers.dart';
import '../providers/interaction_providers.dart';
import '../../../profile/presentation/providers/history_providers.dart';

class VideoFeedScreen extends ConsumerStatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  ConsumerState<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends ConsumerState<VideoFeedScreen> {
  final PageController _pageController = PageController();
  int _focusedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadResolvedVideoUrlsCache(ref);
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(tmdbVideoFeedProvider);
    final ytAsync = ref.watch(youtubeFeedProvider);
    final activeTab = ref.watch(navigationIndexProvider);
    final isTabActive = activeTab == 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedAsync.when(
        data: (videos) {
          // Merge YouTube videos when available
          final ytVideos = ytAsync.valueOrNull;
          final allVideos = [
            ...videos,
            ...?ytVideos,
          ];
          if (allVideos.isEmpty) {
            return const Center(child: Text('Aucune vidéo trouvée.', style: TextStyle(color: Colors.white)));
          }
          // Pre-resolve stream URLs for the next items so swiping is instant
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(videoPreloaderProvider).preloadAround(allVideos, _focusedIndex);
            }
          });
          return PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            physics: const _RelaxedPagePhysics(),
            dragStartBehavior: DragStartBehavior.down,
            allowImplicitScrolling: true,
            onPageChanged: (index) {
              setState(() => _focusedIndex = index);
              final accentColor = allVideos[index]['accent_color'] as Color;
              ref.read(ambientColorProvider.notifier).state = accentColor;
              ref.read(videoPreloaderProvider).preloadAround(allVideos, index);
            },
            itemCount: allVideos.length,
            itemBuilder: (context, index) {
              return RepaintBoundary(
                child: UniversalVideoPlayerItem(
                  movie: allVideos[index],
                  isFocused: index == _focusedIndex,
                  index: index,
                  focusedIndex: _focusedIndex,
                  isTabActive: isTabActive,
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
      ),
    );
  }
}

/// Page physics tuned for a short-video feed:
/// - a gentle flick (low velocity) reliably advances to the next page
/// - the settle spring is stiffer so pages snap quickly without bounce lag
class _RelaxedPagePhysics extends PageScrollPhysics {
  const _RelaxedPagePhysics({super.parent});

  @override
  _RelaxedPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _RelaxedPagePhysics(parent: buildParent(ancestor));

  @override
  SpringDescription get spring {
    return SpringDescription.withDampingRatio(
      mass: 0.5,
      stiffness: 420,
      ratio: 1.05,
    );
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    final Tolerance tolerance = toleranceFor(position);

    // A quick flick in either direction always turns the page, even when the
    // finger travelled a very short distance.
    if (velocity.abs() > 320) {
      final double page = position.pixels / position.viewportDimension;
      final double target =
          velocity > 0 ? (page.floor() + 1).toDouble() : (page.ceil() - 1).toDouble();
      final double targetPixels =
          (target * position.viewportDimension).clamp(position.minScrollExtent, position.maxScrollExtent);
      if ((targetPixels - position.pixels).abs() > tolerance.distance) {
        return ScrollSpringSimulation(spring, position.pixels, targetPixels, velocity, tolerance: tolerance);
      }
      return null;
    }

    // Slow drags: accept the page turn as soon as ~25% of the viewport was
    // travelled instead of the default ~50%.
    return super.createBallisticSimulation(position, velocity);
  }

  @override
  double get minFlingVelocity => 320.0;
}

class UniversalVideoPlayerItem extends ConsumerStatefulWidget {
  final Map<String, dynamic> movie;
  final bool isFocused;
  final int index;
  final int focusedIndex;
  final bool isTabActive;
  
  const UniversalVideoPlayerItem({
    super.key, 
    required this.movie, 
    required this.isFocused,
    required this.index,
    required this.focusedIndex,
    required this.isTabActive,
  });

  @override
  ConsumerState<UniversalVideoPlayerItem> createState() => _UniversalVideoPlayerItemState();
}

class _UniversalVideoPlayerItemState extends ConsumerState<UniversalVideoPlayerItem> with TickerProviderStateMixin {
  VideoPlayerController? _nativeController;
  YoutubePlayerController? _webController;
  
  bool _initialized = false;
  bool _webVideoStarted = false;
  /// True when direct MP4 playback failed (YouTube rate-limiting / stale URL)
  /// and we fell back to the official embedded YouTube player.
  bool _useEmbeddedFallback = false;
  String? _error;
  bool _showIcon = false;
  IconData _lastIcon = Icons.play_arrow;
  Timer? _iconTimer;

  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  bool _showHeart = false;
  bool _isUnlike = false;

  late final AppLifecycleListener _lifecycleListener;
  bool _resumePlaybackOnForeground = false;

  @override
  void initState() {
    super.initState();
    // Only init if it's near the focused index AND the tab is active
    if ((widget.index - widget.focusedIndex).abs() <= 1 && widget.isTabActive) {
      _initPlayer();
    }
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _heartAnimation = CurvedAnimation(parent: _heartController, curve: Curves.elasticOut);

    _lifecycleListener = AppLifecycleListener(
      onPause: _pausePlayback,
      onHide: _pausePlayback,
      onInactive: _pausePlayback,
      onResume: _resumePlayback,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pause if the route is no longer the top one (e.g. pushed PlatformChannelScreen)
    final isRouteActive = ModalRoute.of(context)?.isCurrent ?? true;
    if (!isRouteActive) {
      _pausePlayback();
    } else if (widget.isFocused && widget.isTabActive) {
      _resumePlayback();
    }
  }

  /// Whether this item renders through the YouTube iframe player
  /// (web build, or mobile fallback when stream extraction is blocked).
  bool get _useWebPlayer => kIsWeb || _useEmbeddedFallback;

  void _pausePlayback() {
    if (!_initialized) return;
    final bool wasPlaying;
    if (_useWebPlayer) {
      wasPlaying = _webController?.value.playerState == PlayerState.playing;
      if (wasPlaying) _webController?.pauseVideo();
    } else {
      wasPlaying = _nativeController?.value.isPlaying ?? false;
      if (wasPlaying) _nativeController?.pause();
    }
    if (wasPlaying) _resumePlaybackOnForeground = true;
    WakelockPlus.disable();
  }

  void _resumePlayback() {
    if (!_initialized || !widget.isFocused || !widget.isTabActive) return;
    if (!_resumePlaybackOnForeground) return;
    _resumePlaybackOnForeground = false;
    if (_useWebPlayer) {
      _webController?.playVideo();
    } else {
      _nativeController?.play();
    }
    WakelockPlus.enable();
  }

  void _initPlayer() async {
    if (_initialized) return;

    // Short guard against rate-limiting during very fast swiping; the
    // background preloader usually has the URL ready anyway.
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted || (widget.index - widget.focusedIndex).abs() > 1 || !widget.isTabActive) return;

    final videoKey = widget.movie['video_key'];
    final isMuted = ref.read(isMutedProvider);

    // Defensive: some entries may have no trailer at all.
    if (videoKey is! String || videoKey.isEmpty) {
      if (mounted) {
        setState(() => _error = 'Aucune bande-annonce disponible pour ce titre.');
      }
      return;
    }

    if (!kIsWeb && _useEmbeddedFallback) {
      _initEmbeddedPlayer(isMuted);
      return;
    }

    // 1. Check Cache first (only fresh entries: signed URLs expire ~6h)
    final cachedUrl = getFreshResolvedUrl(ref, videoKey);
    if (cachedUrl != null && !kIsWeb) {
      _initNativeController(cachedUrl, isMuted);
      return;
    }

    if (kIsWeb) {
      _initEmbeddedPlayer(isMuted);
    } else {
      final YouTubeService ytService = ref.read(youtubeServiceProvider);

      // Circuit breaker open (YouTube blocking this IP): skip the doomed
      // manifest resolution and its retry storm, play via the official
      // embedded player right away.
      if (!ytService.isRateLimited) {
        final directUrl = await ytService.resolveStreamUrl(videoKey);
        if (!mounted) return;
        if (directUrl != null) {
          // Save to cache for future use (memory + disk)
          cacheResolvedVideoUrl(ref, videoKey, directUrl);
          _initNativeController(directUrl, isMuted);
          return;
        }
        debugPrint('Stream resolution unavailable for $videoKey, using embedded player');
      }

      if (mounted) {
        setState(() => _useEmbeddedFallback = true);
        _initEmbeddedPlayer(isMuted);
      }
    }
  }

  void _initEmbeddedPlayer(bool isMuted) {
    if (_webController != null) {
      if (_initialized && widget.isFocused && widget.isTabActive) _webController!.playVideo();
      return;
    }

    _webController = YoutubePlayerController.fromVideoId(
      videoId: widget.movie['video_key'],
      autoPlay: false,
      params: YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        mute: isMuted,
        loop: true,
        showVideoAnnotations: false,
        strictRelatedVideos: true,
        enableCaption: false,
        color: 'white',
      ),
    );

    if (mounted) {
      setState(() => _initialized = true);
    }

    if (widget.isFocused && widget.isTabActive) {
      _webController!.playVideo();
      WakelockPlus.enable();
    }

    _webController!.stream.listen((state) {
      if (state.playerState == PlayerState.playing && !_webVideoStarted) {
        if (mounted) {
          setState(() => _webVideoStarted = true);
          WakelockPlus.enable(); 
        }
      }
    });
  }

  void _initNativeController(String url, bool isMuted) {
    _nativeController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
          _nativeController!.setVolume(isMuted ? 0.0 : 1.0);
          if (widget.isFocused) {
            _nativeController!.play();
            WakelockPlus.enable();
          }
          _nativeController!.setLooping(true);
        });
      }).catchError((Object e) {
        // Cached URL went stale or playback failed: retry through the
        // official embedded player.
        debugPrint('Native player failed for $url, falling back to embedded player: $e');
        if (!mounted) return;
        _disposePlayer();
        setState(() => _useEmbeddedFallback = true);
        _initEmbeddedPlayer(ref.read(isMutedProvider));
      });
  }

  @override
  void didUpdateWidget(UniversalVideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // SLIDING WINDOW LOGIC:
    // 1. If we are now far from focus, dispose to free up network/IP rate limits
    if ((widget.index - widget.focusedIndex).abs() > 1) {
      if (_initialized) {
        _disposePlayer();
      }
      return;
    }

    // 2. If we are now near focus but not initialized, init
    if (!_initialized && widget.isTabActive) {
      _initPlayer();
      return;
    }

    // 3. Normal Play/Pause logic
    final isRouteActive = ModalRoute.of(context)?.isCurrent ?? true;
    
    if (widget.isFocused && widget.isTabActive && isRouteActive) {
      WakelockPlus.enable();
      if (_useWebPlayer) {
        _webController?.playVideo();
      } else {
        _nativeController?.play();
      }
      ref.read(historyProvider.notifier).addToHistory(widget.movie);
    } else {
      if (_useWebPlayer) {
        _webController?.pauseVideo();
      } else {
        _nativeController?.pause();
      }
    }
  }

  void _disposePlayer() {
    _nativeController?.dispose();
    _webController?.close();
    _nativeController = null;
    _webController = null;
    if (mounted) {
      setState(() {
        _initialized = false;
        _webVideoStarted = false;
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    _lifecycleListener.dispose();
    _iconTimer?.cancel();
    _heartController.dispose();
    _nativeController?.dispose();
    _webController?.close();
    super.dispose();
  }

  void _handleDoubleTap() async {
    final videoId = widget.movie['id'].toString();
    final wasLiked = ref.read(likeStatusProvider(videoId)).value ?? false;
    
    await SupabaseService.toggleLike(widget.movie); // Updated to pass movie map
    ref.invalidate(likeStatusProvider(videoId));
    
    if (mounted) {
      setState(() {
        _isUnlike = wasLiked;
        _showHeart = true;
      });
    }
    
    _heartController.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _showHeart = false);
        }
      });
    });
  }

  Widget _buildHeartAnimation() {
    if (!_showHeart) return const SizedBox();
    return Center(
      child: ScaleTransition(
        scale: _heartAnimation,
        child: Icon(
          _isUnlike ? Icons.favorite_border : Icons.favorite, 
          color: _isUnlike ? Colors.white54 : AppColors.neonFuchsia, 
          size: 100,
        ),
      ),
    );
  }

  void _togglePlay() async {
    if (!_initialized) return;

    bool isPlaying;
    if (_useWebPlayer) {
      isPlaying = _webController?.value.playerState == PlayerState.playing;
      if (isPlaying) {
        _webController?.pauseVideo();
        WakelockPlus.disable();
      } else {
        _webController?.playVideo();
        WakelockPlus.enable();
      }
    } else {
      isPlaying = _nativeController!.value.isPlaying;
      if (isPlaying) {
        _nativeController?.pause();
        WakelockPlus.disable();
      } else {
        _nativeController?.play();
        WakelockPlus.enable();
      }
    }

    setState(() {
      _lastIcon = isPlaying ? Icons.pause : Icons.play_arrow;
      _showIcon = true;
    });

    _iconTimer?.cancel();
    _iconTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _showIcon = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final posterPath = widget.movie['poster_path'];
    final backdropPath = widget.movie['backdrop_path'];
    final thumbnailUrl = widget.movie['thumbnail_url'];
    final isMuted = ref.watch(isMutedProvider);

    // React to volume changes immediately
    ref.listen(isMutedProvider, (previous, next) {
      if (_useWebPlayer) {
        if (next) {
          _webController?.mute();
        } else {
          _webController?.unMute();
        }
      } else {
        _nativeController?.setVolume(next ? 0.0 : 1.0);
      }
    });

    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        // 1. Cinematic Backdrop (Handle TMDB or Direct YouTube).
        // Static pre-blurred image instead of a live BackdropFilter:
        // the result is raster-cached once, so swiping stays smooth on
        // low-end devices.
        if (posterPath != null)
          _BlurredBackdrop(url: '${TMDBService.imageBaseUrl}$posterPath')
        else if (thumbnailUrl != null || backdropPath != null)
          _BlurredBackdrop(url: thumbnailUrl ?? backdropPath!)
        else
          const ColoredBox(color: Colors.black),
        
        if (_initialized)
          Center(
            child: _useWebPlayer 
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    OverflowBox(
                      maxWidth: double.infinity,
                      maxHeight: double.infinity,
                      child: Transform.scale(
                        scale: 1.4,
                        child: FittedBox(
                          fit: BoxFit.cover,
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width,
                            height: MediaQuery.of(context).size.width * (9 / 16),
                            child: YoutubePlayer(controller: _webController!),
                          ),
                        ),
                      ),
                    ),
                    if (!_webVideoStarted && (posterPath != null || thumbnailUrl != null))
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: posterPath != null ? '${TMDBService.imageBaseUrl}$posterPath' : (thumbnailUrl ?? backdropPath!),
                          fit: BoxFit.cover,
                        ),
                      ),
                  ],
                )
              : AspectRatio(
                  aspectRatio: _nativeController!.value.aspectRatio,
                  child: VideoPlayer(_nativeController!),
                ),
          )
        else if (_error != null)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.speed, color: Colors.orange, size: 40),
                const SizedBox(height: 10),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
              ],
            ),
          )
        else
          const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),

        if (kIsWeb)
          Positioned.fill(
            child: PointerInterceptor(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _togglePlay,
                onDoubleTap: _handleDoubleTap,
                onLongPress: () {
                  showDialog(
                    context: context,
                    barrierColor: Colors.black54,
                    builder: (context) => InteractionOverlay(
                      videoId: widget.movie['id'].toString(),
                      movie: widget.movie,
                    ),
                  );
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4],
                ),
              ),
            ),
          ),
        ),

        if (_showIcon)
          PointerInterceptor(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: Icon(_lastIcon, color: Colors.white, size: 50),
                ),
              ),
            ),
          ),
        
        _buildHeartAnimation(),

        PointerInterceptor(
          child: _buildInfoOverlay(),
        ),
        
        if (_initialized)
          Positioned(
            // Just above the central "eye" logo (visible top ~85px)
            bottom: 108,
            left: 10,
            right: 10,
            child: PointerInterceptor(
              child: _useWebPlayer
                ? _WebVideoProgressIndicator(
                    controller: _webController!,
                    playedColor: widget.movie['accent_color'] ?? AppColors.neonCyan,
                  )
                : AnimatedBuilder(
                    animation: _nativeController!,
                    builder: (context, _) {
                      final value = _nativeController!.value;
                      final durationMs = value.duration.inMilliseconds.toDouble();
                      final positionMs = value.position.inMilliseconds.toDouble();
                      final progress = durationMs > 0 ? (positionMs / durationMs).clamp(0.0, 1.0) : 0.0;
                      return LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white10,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.movie['accent_color'] ?? AppColors.neonCyan,
                        ),
                        minHeight: 2.5,
                      );
                    },
                  ),
            ),
          ),

        PointerInterceptor(
          child: Positioned(
            top: 60,
            right: 20,
            child: IconButton(
              icon: Icon(
                isMuted ? Icons.volume_off : Icons.volume_up, 
                color: Colors.white, 
                size: 28
              ),
              onPressed: () {
                ref.read(isMutedProvider.notifier).state = !isMuted;
              },
            ),
          ),
        ),
      ],
    );

    if (kIsWeb) return content;

    return GestureDetector(
      onTap: _togglePlay,
      onDoubleTap: _handleDoubleTap,
      onLongPress: () {
        showDialog(
          context: context,
          barrierColor: Colors.black54,
          builder: (context) => InteractionOverlay(
            videoId: widget.movie['id'].toString(),
            movie: widget.movie,
          ),
        );
      },
      child: content,
    );
  }

  Widget _buildInfoOverlay() {
    final title = widget.movie['title'] ?? widget.movie['name'] ?? 'Inconnu';
    final overview = widget.movie['overview'] ?? '';

    return Positioned(
      // Sits just above the progress bar (bottom: 108)
      bottom: 138,
      left: 20,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PlatformBadge(movie: widget.movie),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => MovieDetailsSheet(movie: widget.movie),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18, // Reduced from 20
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), // Reduced opacity
                    fontSize: 12, // Reduced from 13
                    fontWeight: FontWeight.w400,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlatformBadge extends ConsumerWidget {
  final Map<String, dynamic> movie;

  const _PlatformBadge({required this.movie});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platform = movie['platform'] ?? 'Netflix';
    final channelId = movie['channel_id'] as String?;

    if (channelId != null && channelId.startsWith('UC')) {
      final detailsAsync = ref.watch(platformDetailsProvider(channelId));
      return detailsAsync.when(
        data: (details) => _buildBadge(context, details['name'], details['logo'], channelId),
        loading: () => _buildBadge(context, platform, null, channelId, isLoading: true),
        error: (e, s) => _buildBadge(context, platform, movie['platform_logo'], channelId),
      );
    }
    
    return _buildBadge(context, platform, movie['platform_logo'], channelId);
  }

  Widget _buildBadge(BuildContext context, String name, String? logoUrl, String? channelId, {bool isLoading = false}) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => PlatformPopup(
            platformName: name,
            platformLogo: logoUrl,
            channelId: channelId,
          ),
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (logoUrl != null && logoUrl.isNotEmpty) ...[
            ClipOval(
              child: CachedNetworkImage(
                imageUrl: logoUrl,
                width: 22,
                height: 22,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) =>
                    Container(width: 22, height: 22, color: Colors.white12),
              ),
            ),
            const SizedBox(width: 8),
          ] else if (isLoading) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              name,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

/// Static blurred backdrop: blur is applied to the image itself (not live to
/// what's behind it), so the raster is cached once and scrolling stays cheap.
class _BlurredBackdrop extends StatelessWidget {
  final String url;

  const _BlurredBackdrop({required this.url});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: 200,
              fadeInDuration: Duration.zero,
            ),
          ),
          ColoredBox(color: Colors.black.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}

class _WebVideoProgressIndicator extends StatelessWidget {
  final YoutubePlayerController controller;
  final Color playedColor;

  const _WebVideoProgressIndicator({
    required this.controller,
    required this.playedColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<YoutubeVideoState>(
      stream: controller.videoStateStream,
      builder: (context, snapshot) {
        final position = snapshot.data?.position.inMilliseconds.toDouble() ?? 0.0;
        final duration = controller.value.metaData.duration.inMilliseconds.toDouble();
        final progress = duration > 0 ? position / duration : 0.0;

        return LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.white10,
          valueColor: AlwaysStoppedAnimation<Color>(playedColor),
          minHeight: 2,
        );
      },
    );
  }
}
