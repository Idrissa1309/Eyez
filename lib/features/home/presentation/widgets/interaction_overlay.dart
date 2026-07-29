import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class InteractionOverlay extends StatelessWidget {
  const InteractionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Top instruction
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
          
          // Interaction Buttons
          Positioned(
            bottom: 200,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(Icons.favorite, '-J\'aime', AppColors.neonFuchsia),
                _buildActionButton(Icons.chat_bubble, 'Commenter', AppColors.neonCyan),
                _buildActionButton(Icons.bookmark, 'Sauvegarder', Colors.white),
                _buildActionButton(Icons.share, 'Partager', Colors.white),
                _buildActionButton(Icons.add, 'Suivre', AppColors.neonFuchsia),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black54,
              border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
