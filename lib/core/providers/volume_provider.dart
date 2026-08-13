import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider to manage global mute/unmute state across the video feed.
final isMutedProvider = StateProvider<bool>((ref) {
  return false; // Default to unmuted as requested
});
