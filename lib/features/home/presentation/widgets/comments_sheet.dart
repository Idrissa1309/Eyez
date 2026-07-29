import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_service.dart';
import '../providers/interaction_providers.dart';

class CommentsSheet extends ConsumerStatefulWidget {
  final String videoId;
  const CommentsSheet({super.key, required this.videoId});

  @override
  ConsumerState<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends ConsumerState<CommentsSheet> {
  final _commentController = TextEditingController();
  bool _isPosting = false;

  Future<void> _handlePost() async {
    if (_commentController.text.trim().isEmpty) return;
    
    setState(() => _isPosting = true);
    try {
      await SupabaseService.postComment(widget.videoId, _commentController.text.trim());
      _commentController.clear();
      ref.invalidate(commentsProvider(widget.videoId));
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.parse(dateStr);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'il y a ${diff.inHours}h';
    return DateFormat('dd/MM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsProvider(widget.videoId));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'COMMENTAIRES',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.5),
          ),
          const SizedBox(height: 25),
          
          Expanded(
            child: commentsAsync.when(
              data: (comments) => comments.isEmpty 
                ? const Center(child: Text('Soyez le premier à commenter !', style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    itemCount: comments.length,
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 25),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.outline,
                              child: Icon(Icons.person, size: 22, color: Colors.white70),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        c['username'] ?? 'Anonyme',
                                        style: const TextStyle(color: AppColors.neonFuchsia, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        _formatTime(c['created_at']),
                                        style: const TextStyle(color: Colors.white24, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    c['content'],
                                    style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.4),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
              error: (err, stack) => Center(child: Text('Erreur: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
          
          // Input
          Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                      fillColor: Colors.black26,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 10),
                if (_isPosting)
                  const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan))
                else
                  IconButton(
                    icon: const Icon(Icons.send, color: AppColors.neonCyan),
                    onPressed: _handlePost,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
