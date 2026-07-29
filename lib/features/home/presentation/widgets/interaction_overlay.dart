import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/presentation/providers/my_list_providers.dart';
import '../providers/interaction_providers.dart';
import 'comments_sheet.dart';

class InteractionOverlay extends ConsumerStatefulWidget {
  final String videoId;
  final Map<String, dynamic> movie;
  
  const InteractionOverlay({
    super.key, 
    required this.videoId,
    required this.movie,
  });

  @override
  ConsumerState<InteractionOverlay> createState() => _InteractionOverlayState();
}

class _InteractionOverlayState extends ConsumerState<InteractionOverlay> {
  bool _showHint = false;

  @override
  void initState() {
    super.initState();
    _checkHint();
  }

  Future<void> _checkHint() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool('has_seen_interaction_hint') ?? false;
    if (!hasSeen) {
      setState(() => _showHint = true);
      await prefs.setBool('has_seen_interaction_hint', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = ref.watch(likeStatusProvider(widget.videoId)).value ?? false;
    final isSaved = ref.watch(myListProvider.notifier).isSaved(int.tryParse(widget.videoId) ?? widget.movie['id'] ?? 0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          
          if (_showHint)
            Positioned(
              top: MediaQuery.of(context).size.height * 0.3,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const Icon(Icons.touch_app, color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  const Text(
                    'Maintenez appuyé\npour interagir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border, 
                  label: 'J\'aime', 
                  color: AppColors.neonFuchsia,
                  isActive: isLiked,
                  onTap: () async {
                    await SupabaseService.toggleLike(widget.videoId);
                    ref.invalidate(likeStatusProvider(widget.videoId));
                  },
                ),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline, 
                  label: 'Commenter', 
                  color: AppColors.neonCyan,
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => CommentsSheet(videoId: widget.videoId),
                    );
                  },
                ),
                _buildActionButton(
                  icon: isSaved ? Icons.bookmark : Icons.bookmark_border, 
                  label: 'Collection', 
                  color: const Color(0xFFC0FF00), // Green/Lime
                  isActive: isSaved,
                  onTap: () {
                    ref.read(myListProvider.notifier).toggleItem(widget.movie);
                  },
                ),
                _buildActionButton(
                  icon: Icons.share_outlined, 
                  label: 'Partager', 
                  color: const Color(0xFF007BFF), // Blue
                  onTap: () {
                    Share.share('Regarde ce contenu sur Eyez : ${widget.movie['title'] ?? widget.movie['name']}');
                  },
                ),
                _buildActionButton(
                  icon: Icons.person_add_outlined, 
                  label: 'Suivre', 
                  color: const Color(0xFF9D44FF), // Purple
                  onTap: () {
                    // Follow logic
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon, 
    required String label, 
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black54,
                border: Border.all(
                  color: color.withValues(alpha: isActive ? 1.0 : 0.4), 
                  width: isActive ? 2 : 1
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isActive ? 0.4 : 0.2),
                    blurRadius: isActive ? 15 : 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: 24),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
