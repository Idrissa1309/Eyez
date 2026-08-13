import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/ambient_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
import '../../../../core/providers/volume_provider.dart';
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/services/supabase_service.dart';
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
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(tmdbVideoFeedProvider);
    final activeTab = ref.watch(navigationIndexProvider);
    final isTabActive = activeTab == 0;

    return Scaffold(
      backgroundColor: Colors.black,
      body: feedAsync.when(
        data: (videos) {
          if (videos.isEmpty) {
            return const Center(child: Text('Aucune vidéo trouvée.', style: TextStyle(color: Colors.white)));
          }
          return PageView.builder(
            scrollDirection: Axis.vertical,
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _focusedIndex = index);
              final accentColor = videos[index]['accent_color'] as Color;
              ref.read(ambientColorProvider.notifier).state = accentColor;
            },
            itemCount: videos.length,
            itemBuilder: (context, index) {
              return UniversalVideoPlayerItem(
                movie: videos[index],
                isFocused: index == _focusedIndex,
                index: index,
                focusedIndex: _focusedIndex,
                isTabActive: isTabActive,
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
  String? _error;
  bool _showIcon = false;
  IconData _lastIcon = Icons.play_arrow;
  Timer? _iconTimer;

  late AnimationController _heartController;
  late Animation<double> _heartAnimation;
  bool _showHeart = false;
  bool _isUnlike = false;
  
  @override
  void initState() {
    super.initState();
    // Only init if it's near the focused index AND the tab is active
    if ((widget.index - widget.focusedIndex).abs() <= 1 && widget.isTabActive) {
      _initPlayer();
    }
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _heartAnimation = CurvedAnimation(parent: _heartController, curve: Curves.elasticOut);
  }

  void _initPlayer() async {
    if (_initialized) return;

    // Add a small delay and double-check focus to avoid rate-limiting during fast swiping
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted || (widget.index - widget.focusedIndex).abs() > 1 || !widget.isTabActive) return;

    final videoKey = widget.movie['video_key'];
    final isMuted = ref.read(isMutedProvider);

    // 1. Check Cache first
    final cachedUrl = ref.read(resolvedVideoUrlsProvider)[videoKey];
    if (cachedUrl != null && !kIsWeb) {
      _initNativeController(cachedUrl, isMuted);
      return;
    }

    if (kIsWeb) {
      _webController = YoutubePlayerController.fromVideoId(
        videoId: videoKey,
        autoPlay: true,
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
      
      _webController!.stream.listen((state) {
        if (state.playerState == PlayerState.playing && !_webVideoStarted) {
          if (mounted) {
            setState(() => _webVideoStarted = true);
            WakelockPlus.enable(); 
          }
        }
      });
    } else {
      final yt = YoutubeExplode();
      try {
        final manifest = await yt.videos.streamsClient.getManifest(videoKey);
        final streamInfo = manifest.muxed.withHighestBitrate();
        final directUrl = streamInfo.url.toString();

        // Save to cache for future use
        ref.read(resolvedVideoUrlsProvider.notifier).update((state) => {
          ...state,
          videoKey: directUrl,
        });

        _initNativeController(directUrl, isMuted);
      } catch (e) {
        if (mounted) {
          setState(() => _error = 'Rate Limit YouTube. Veuillez patienter.');
        }
      } finally {
        yt.close();
      }
    }
  }

  void _initNativeController(String url, bool isMuted) {
    _nativeController = VideoPlayerController.networkUrl(Uri.parse(url))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            _nativeController!.setVolume(isMuted ? 0.0 : 1.0);
            if (widget.isFocused) {
              _nativeController!.play();
              WakelockPlus.enable();
            }
            _nativeController!.setLooping(true);
          });
        }
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
    if (widget.isFocused && widget.isTabActive) {
      WakelockPlus.enable();
      if (kIsWeb) {
        _webController?.playVideo();
      } else {
        _nativeController?.play();
      }
      ref.read(historyProvider.notifier).addToHistory(widget.movie);
    } else {
      if (kIsWeb) {
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
    if (kIsWeb) {
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
      if (kIsWeb) {
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
        // 1. Cinematic Backdrop (Handle TMDB or Direct YouTube)
        if (posterPath != null)
          CachedNetworkImage(
            imageUrl: '${TMDBService.imageBaseUrl}$posterPath',
            fit: BoxFit.cover,
          )
        else if (thumbnailUrl != null || backdropPath != null)
          CachedNetworkImage(
            imageUrl: thumbnailUrl ?? backdropPath!,
            fit: BoxFit.cover,
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
        
        if (_initialized)
          Center(
            child: kIsWeb 
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
            bottom: 87,
            left: 10,
            right: 10,
            child: PointerInterceptor(
              child: kIsWeb 
                ? _WebVideoProgressIndicator(
                    controller: _webController!,
                    playedColor: widget.movie['accent_color'] ?? AppColors.neonCyan,
                  )
                : VideoProgressIndicator(
                    _nativeController!,
                    allowScrubbing: true,
                    colors: VideoProgressColors(
                      playedColor: widget.movie['accent_color'] ?? AppColors.neonCyan,
                      bufferedColor: Colors.white24,
                      backgroundColor: Colors.white10,
                    ),
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
      bottom: 120, // Moved up slightly for better visibility
      left: 20,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlatformBadge(),
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20, // Reduced from 22
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
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

  Widget _buildPlatformBadge() {
    final String platform = widget.movie['platform'] ?? 'Netflix';
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => PlatformPopup(platformName: platform),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white10),
        ),
        child: Text(
          platform,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
        ),
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
