import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GoogleColoredIcon extends StatelessWidget {
  final double size;
  const GoogleColoredIcon({super.key, this.size = 19});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          FaIcon(FontAwesomeIcons.google, size: size, color: Colors.white),
          // We can use a shader mask or just leave it white for simplicity if FontAwesome doesn't support layers
          // But to be "true colors", we use a ShaderMask
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [
                  Color(0xFF4285F4), // Blue
                  Color(0xFF34A853), // Green
                  Color(0xFFFBBC05), // Yellow
                  Color(0xFFEA4335), // Red
                ],
                stops: [0.25, 0.5, 0.75, 1.0],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: FaIcon(FontAwesomeIcons.google, size: size, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class PlatformIcon extends StatelessWidget {
  final String name;
  final double size;
  const PlatformIcon({super.key, required this.name, this.size = 18});

  @override
  Widget build(BuildContext context) {
    switch (name.toLowerCase()) {
      case 'netflix':
        return FaIcon(FontAwesomeIcons.n, color: const Color(0xFFE50914), size: size);
      case 'amazon prime video':
      case 'prime video':
        return FaIcon(FontAwesomeIcons.p, color: const Color(0xFF00A8E1), size: size);
      case 'disney+':
      case 'disney':
        return FaIcon(FontAwesomeIcons.d, color: const Color(0xFF113CCF), size: size);
      case 'apple tv+':
      case 'apple tv':
        return FaIcon(FontAwesomeIcons.apple, color: Colors.white, size: size);
      case 'crunchyroll':
        return FaIcon(FontAwesomeIcons.c, color: const Color(0xFFF47521), size: size);
      default:
        return Icon(Icons.play_circle_fill, color: Colors.white, size: size);
    }
  }
}
