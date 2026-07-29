import 'package:flutter/material.dart';
import '../../../home/presentation/screens/video_feed_screen.dart';
import '../../../../shared/widgets/app_border_wrapper.dart';

class ProfileVideoPlayerScreen extends StatelessWidget {
  final Map<String, dynamic> movie;

  const ProfileVideoPlayerScreen({super.key, required this.movie});

  @override
  Widget build(BuildContext context) {
    return AppBorderWrapper(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        extendBodyBehindAppBar: true,
        body: UniversalVideoPlayerItem(
          movie: movie,
          isFocused: true,
        ),
      ),
    );
  }
}
