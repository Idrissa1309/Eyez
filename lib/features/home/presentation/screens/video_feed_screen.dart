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
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/ambient_provider.dart';
import '../../../../core/providers/navigation_provider.dart';
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
  
  const UniversalVideoPlayerItem({
    super.key, 
    required this.movie, 
    required this.isFocused,
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
  
  @override
  void initState() {
    super.initState();
    _initPlayer();
    _heartController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _heartAnimation = CurvedAnimation(parent: _heartController, curve: Curves.elasticOut);
  }

  void _initPlayer() async {
    final videoKey = widget.movie['video_key'];

    if (kIsWeb) {
      _webController = YoutubePlayerController.fromVideoId(
        videoId: videoKey,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          mute: true,
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
      
      // Listen for video start to hide the red button/thumbnail
      _webController!.stream.listen((state) {
        if (state.playerState == PlayerState.playing && !_webVideoStarted) {
          if (mounted) {
            setState(() => _webVideoStarted = true);
          }
        }
      });
    } else {
      final yt = YoutubeExplode();
      try {
        final manifest = await yt.videos.streamsClient.getManifest(videoKey);
        final streamInfo = manifest.muxed.withHighestBitrate();
        _nativeController = VideoPlayerController.networkUrl(Uri.parse(streamInfo.url.toString()))
          ..initialize().then((_) {
            if (mounted) {
              setState(() {
                _initialized = true;
                if (widget.isFocused) {
                  _nativeController!.play();
                }
                _nativeController!.setLooping(true);
              });
            }
          });
      } catch (e) {
        if (mounted) {
          setState(() => _error = 'Erreur de chargement.');
        }
      } finally {
        yt.close();
      }
    }
  }

  @override
  void didUpdateWidget(UniversalVideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_initialized) return;

    if (kIsWeb) {
      if (widget.isFocused) {
        _webController?.playVideo();
        ref.read(historyProvider.notifier).addToHistory(widget.movie);
      } else {
        _webController?.pauseVideo();
        // Reset web video started state when losing focus to show poster again if needed
        // No, maybe keep it.
      }
    } else {
      if (widget.isFocused) {
        _nativeController?.play();
        ref.read(historyProvider.notifier).addToHistory(widget.movie);
      } else {
        _nativeController?.pause();
      }
    }
  }

  @override
  void dispose() {
    _iconTimer?.cancel();
    _heartController.dispose();
    _nativeController?.dispose();
    _webController?.close();
    super.dispose();
  }

  void _handleDoubleTap() async {
    final videoId = widget.movie['id'].toString();
    await SupabaseService.toggleLike(videoId);
    ref.invalidate(likeStatusProvider(videoId));
    if (mounted) {
      setState(() => _showHeart = true);
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
        child: const Icon(Icons.favorite, color: AppColors.neonFuchsia, size: 100),
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
      } else {
        _webController?.playVideo();
      }
    } else {
      isPlaying = _nativeController!.value.isPlaying;
      if (isPlaying) {
        _nativeController?.pause();
      } else {
        _nativeController?.play();
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

    Widget content = Stack(
      fit: StackFit.expand,
      children: [
        // 1. Cinematic Backdrop
        if (posterPath != null)
          CachedNetworkImage(
            imageUrl: '${TMDBService.imageBaseUrl}$posterPath',
            fit: BoxFit.cover,
          ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
        
        // 2. Video Surface
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
                    if (!_webVideoStarted && posterPath != null)
                      Positioned.fill(
                        child: CachedNetworkImage(
                          imageUrl: '${TMDBService.imageBaseUrl}$posterPath',
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
          Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
        else
          const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),

        // 2b. Interaction Layer for Web (Captures taps above Iframe)
        if (kIsWeb)
          Positioned.fill(
            child: PointerInterceptor(
              intercepting: true,
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

        // Legibility Gradient
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
        
        // 5. Progress Indicator
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
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).state = 1; // Go to Explorer tab
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
