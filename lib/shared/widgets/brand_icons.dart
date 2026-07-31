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

  const PlatformIcon({
    super.key, 
    required this.name, 
    this.size = 18,
    this.isCircular = false,
  });

  static const Map<String, String> _logoUrls = {
    'netflix': 'https://upload.wikimedia.org/wikipedia/commons/0/03/Netflix-icon.png',
    'disney+': 'https://cdn.sortiraparis.com/images/80/69688/1115446-logo-disney.jpg',
    'amazon prime video': 'https://www.pngall.com/wp-content/uploads/15/Amazon-Prime-Video-Logo-PNG-Cutout.png',
    'prime video': 'https://www.pngall.com/wp-content/uploads/15/Amazon-Prime-Video-Logo-PNG-Cutout.png',
    'apple tv+': 'https://upload.wikimedia.org/wikipedia/commons/a/ad/AppleTVLogo.svg',
    'crunchyroll': 'https://upload.wikimedia.org/wikipedia/commons/9/9a/Crunchyroll_logo_.webp',
  };

  @override
  Widget build(BuildContext context) {
    final normalized = name.toLowerCase();
    final url = _logoUrls[normalized];

    Widget icon;
    if (url != null) {
      if (url.endsWith('.svg')) {
        icon = SvgPicture.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.contain,
          placeholderBuilder: (context) => _buildPlaceholder(),
        );
      } else {
        icon = CachedNetworkImage(
          imageUrl: url,
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
