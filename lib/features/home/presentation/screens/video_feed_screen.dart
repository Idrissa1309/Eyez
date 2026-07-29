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
import '../../../../core/services/tmdb_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../widgets/interaction_overlay.dart';
import '../widgets/movie_details_sheet.dart';
import '../widgets/platform_popup.dart';
import '../providers/video_feed_providers.dart';

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

class UniversalVideoPlayerItem extends StatefulWidget {
  final Map<String, dynamic> movie;
  final bool isFocused;
  
  const UniversalVideoPlayerItem({
    super.key, 
    required this.movie, 
    required this.isFocused,
  });

  @override
  State<UniversalVideoPlayerItem> createState() => _UniversalVideoPlayerItemState();
}

class _UniversalVideoPlayerItemState extends State<UniversalVideoPlayerItem> with TickerProviderStateMixin {
  VideoPlayerController? _nativeController;
  YoutubePlayerController? _webController;
  
  bool _initialized = false;
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
        params: const YoutubePlayerParams(
          showControls: false,
          showFullscreenButton: false,
          mute: false,
          loop: true,
        ),
      );
      if (mounted) {
        setState(() => _initialized = true);
      }
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
          setState(() => _error = "Erreur de chargement.");
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
      } else {
        _webController?.pauseVideo();
      }
    } else {
      if (widget.isFocused) {
        _nativeController?.play();
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

    return GestureDetector(
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
      onTap: _togglePlay,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (posterPath != null)
            CachedNetworkImage(
              imageUrl: '${TMDBService.imageBaseUrl}$posterPath',
              fit: BoxFit.cover,
            ),
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
          
          if (_initialized)
            Center(
              child: kIsWeb 
                ? YoutubePlayer(controller: _webController!)
                : AspectRatio(
                    aspectRatio: _nativeController!.value.aspectRatio,
                    child: VideoPlayer(_nativeController!),
                  ),
            )
          else if (_error != null)
            Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
          else
            const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),

          if (_showIcon)
            PointerInterceptor(
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: Colors.black26, shape: BoxShape.circle),
                  child: Icon(_lastIcon, color: Colors.white, size: 50),
                ),
              ),
            ),
          
          _buildHeartAnimation(),

          PointerInterceptor(child: _buildInfoOverlay()),
          
          if (_initialized && !kIsWeb)
            Positioned(
              bottom: 87,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _nativeController!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: widget.movie['accent_color'] ?? AppColors.neonCyan,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
              ),
            ),

          PointerInterceptor(
            child: Positioned(
              top: 60,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.search, color: Colors.white, size: 28),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoOverlay() {
    final title = widget.movie['title'] ?? widget.movie['name'] ?? 'Inconnu';
    final overview = widget.movie['overview'] ?? '';

    return Positioned(
      bottom: 140,
      left: 20,
      right: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPlatformBadge(),
          const SizedBox(height: 10),
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  overview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    shadows: [Shadow(color: Colors.black, blurRadius: 10)],
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(
          platform,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
