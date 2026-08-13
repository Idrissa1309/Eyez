# Implementation Plan - Video Stream Caching (Zero Reload)

This plan implements a caching mechanism for resolved YouTube stream URLs to ensure that returning to a previously watched video is instantaneous, without re-triggering the extraction logic.

## User Review Required

> [!IMPORTANT]
> - **Caching Strategy**: The app will store the direct MP4 stream URL in a global state after the first successful extraction.
> - **Instant Playback**: Swiping back to a video you've already seen will skip the "Searching on YouTube" step entirely, launching the player in milliseconds.
> - **Memory Safety**: The cache is purely in-memory (RAM) and resets when the app is fully closed, ensuring it doesn't take up permanent disk space.

## Proposed Changes

### 1. Global Cache Provider

#### [MODIFY] [video_feed_providers.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/home/presentation/providers/video_feed_providers.dart)
- Add `resolvedVideoUrlsProvider`: A `StateProvider<Map<String, String>>` where the key is the `video_key` and the value is the direct `mp4` URL.

### 2. Video Player Integration

#### [MODIFY] [video_feed_screen.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/home/presentation/screens/video_feed_screen.dart)
- Update `_initPlayer` in `_UniversalVideoPlayerItemState`:
    - **Step 1**: Check if `videoKey` exists in `resolvedVideoUrlsProvider`.
    - **Step 2**: If it exists, use the cached URL to initialize the `VideoPlayerController` immediately.
    - **Step 3**: If not, proceed with `youtube_explode` extraction and save the result to the provider once finished.

## Verification Plan

### Manual Verification
- [ ] Open Accueil and scroll to the 3rd video.
- [ ] Scroll to the 10th video (Video #3 will be disposed from memory).
- [ ] Scroll back to Video #3.
- [ ] **Expected Result**: Video #3 should start playing instantly without showing the "Searching" or "Rate Limit" delay, as it uses the cached direct URL.
- [ ] Verify that no errors occur during rapid back-and-forth swiping.
