import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
  final bool isCircular;
  final String? imageUrl;

  const PlatformIcon({
    super.key, 
    required this.name, 
    this.size = 18,
    this.isCircular = false,
    this.imageUrl,
  });

  static const Map<String, String> _logoUrls = {
    'netflix': 'https://upload.wikimedia.org/wikipedia/commons/f/ff/Netflix-new-icon.png',
    'disney+': 'https://upload.wikimedia.org/wikipedia/commons/3/3e/Disney%2B_logo.svg',
    'amazon prime video': 'https://upload.wikimedia.org/wikipedia/commons/f/f1/Prime_Video.png',
    'prime video': 'https://upload.wikimedia.org/wikipedia/commons/f/f1/Prime_Video.png',
    'apple tv+': 'https://upload.wikimedia.org/wikipedia/commons/2/28/Apple_TV_Plus_Logo.svg',
    'crunchyroll': 'https://upload.wikimedia.org/wikipedia/commons/0/08/Crunchyroll_Logo.svg',
    'hbo': 'https://upload.wikimedia.org/wikipedia/commons/d/de/HBO_logo.svg',
    'paramount plus': 'https://upload.wikimedia.org/wikipedia/commons/a/a5/Paramount_Plus.svg',
    'peacock premium': 'https://upload.wikimedia.org/wikipedia/commons/d/d3/Peacock_Logo.svg',
    'peacock': 'https://upload.wikimedia.org/wikipedia/commons/d/d3/Peacock_Logo.svg',
  };

  @override
  Widget build(BuildContext context) {
    final normalized = name.toLowerCase().replaceAll('+', '').replaceAll(' ', '');
    
    // Check for hardcoded map by searching for containing keys
    String? foundUrl;
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      foundUrl = imageUrl;
    } else {
      try {
        final key = _logoUrls.keys.firstWhere((k) => normalized.contains(k.replaceAll('+', '').replaceAll(' ', '')));
        foundUrl = _logoUrls[key];
      } catch (_) {
        foundUrl = null;
      }
    }

    Widget icon;
    if (foundUrl != null && foundUrl.isNotEmpty) {
      if (foundUrl.endsWith('.svg')) {
        icon = SvgPicture.network(
          foundUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildPlaceholder(),
        );
      } else {
        icon = CachedNetworkImage(
          imageUrl: foundUrl,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholder: (context, url) => _buildPlaceholder(),
          errorWidget: (context, url, error) => _buildPlaceholder(),
        );
      }
    } else {
      icon = _buildPlaceholder();
    }

    if (isCircular) {
      return Container(
        width: size,
        height: size,
        padding: EdgeInsets.all(size * 0.15),
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: icon,
      );
    }

    return icon;
  }

  Widget _buildPlaceholder() {
    return Icon(Icons.play_circle_fill, color: Colors.white, size: size);
  }
}
