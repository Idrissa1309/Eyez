import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/ambient_provider.dart';
import '../widgets/interaction_overlay.dart';
import '../widgets/movie_details_sheet.dart';

class VideoItem {
  final String title;
  final String description;
  final String videoUrl;
  final Color accentColor;

  VideoItem({
    required this.title,
    required this.description,
    required this.videoUrl,
    required this.accentColor,
  });
}

class VideoFeedScreen extends ConsumerStatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  ConsumerState<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends ConsumerState<VideoFeedScreen> {
  final PageController _pageController = PageController();
  int _focusedIndex = 0;

  final List<VideoItem> _videos = [
    VideoItem(
      title: 'Interstellar',
      description: 'Un voyage au-delà du temps.',
      videoUrl: 'https://www.w3schools.com/html/mov_bbb.mp4',
      accentColor: const Color(0xFF00D2FF),
    ),
    VideoItem(
      title: 'Dune Part Two',
      description: 'Le destin de l\'univers.',
      videoUrl: 'https://samplelib.com/lib/preview/mp4/sample-10s.mp4',
      accentColor: const Color(0xFFFF9F00),
    ),
    VideoItem(
      title: 'Spider-Man',
      description: 'À travers le Spider-Verse.',
      videoUrl: 'https://raw.githubusercontent.com/intel-iot-devkit/sample-videos/master/person-bicycle-car-detection.mp4',
      accentColor: const Color(0xFFFF2E93),
    ),
    VideoItem(
      title: 'The Batman',
      description: 'La vengeance a un visage.',
      videoUrl: 'https://media.w3.org/2010/05/sintel/trailer.mp4',
      accentColor: const Color(0xFFFF0000),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ambientColorProvider.notifier).state = _videos[0].accentColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _focusedIndex = index);
          ref.read(ambientColorProvider.notifier).state = _videos[index].accentColor;
        },
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          return VideoPlayerItem(
            video: _videos[index],
            isFocused: index == _focusedIndex,
          );
        },
      ),
    );
  }
}

class VideoPlayerItem extends StatefulWidget {
  final VideoItem video;
  final bool isFocused;
  const VideoPlayerItem({super.key, required this.video, required this.isFocused});

  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  String? _error;
  bool _showIcon = false;
  IconData _lastIcon = Icons.play_arrow;
  Timer? _iconTimer;

  @override
  void initState() {
    super.initState();
    _initController();
  }

  void _initController() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.video.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() {
            _initialized = true;
            if (widget.isFocused) {
              _controller.play();
            }
            _controller.setLooping(true);
          });
        }
      }).catchError((error) {
        if (mounted) {
          setState(() {
            _error = error.toString();
          });
        }
      });
  }

  @override
  void didUpdateWidget(VideoPlayerItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_initialized) {
      if (widget.isFocused) {
        _controller.play();
      } else {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _iconTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _lastIcon = Icons.pause;
      } else {
        _controller.play();
        _lastIcon = Icons.play_arrow;
      }
      _showIcon = true;
    });
    _iconTimer?.cancel();
    _iconTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _showIcon = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showDialog(
          context: context,
          barrierColor: Colors.black54,
          builder: (context) => InteractionOverlay(
            videoId: widget.video.title,
            movie: {
              'id': widget.video.title.hashCode,
              'title': widget.video.title,
              'overview': widget.video.description,
            },
          ),
        );
      },
      onTap: _togglePlay,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video Layer
          if (_initialized)
            Center(
              child: AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              ),
            )
          else if (_error != null)
            _buildErrorState()
          else
            const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),

          // Play/Pause Icon Overlay
          if (_showIcon)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.black26,
                  shape: BoxShape.circle,
                ),
                child: Icon(_lastIcon, color: Colors.white, size: 50),
              ),
            ),

          // Progress Bar Layer
          if (_initialized)
            Positioned(
              bottom: 75, // Adjusted for the new smaller nav bar (75 height + 12 margin)
              left: 0,
              right: 0,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: widget.video.accentColor,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white10,
                ),
                padding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),

          // Info Layer
          Positioned(
            bottom: 140,
            left: 20,
            right: 80,
            child: _buildVideoInfo(),
          ),

          // Search Icon
          Positioned(
            top: 60,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 28),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoInfo() {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MovieDetailsSheet(
            movie: {
              'title': widget.video.title,
              'overview': widget.video.description,
            },
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.video.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.video.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 40),
            const SizedBox(height: 10),
            Text(
              'Erreur de lecture : $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _initialized = false;
                });
                _initController();
              },
              child: const Text('Réessayer', style: TextStyle(color: AppColors.neonCyan)),
            ),
          ],
        ),
      ),
    );
  }
}
