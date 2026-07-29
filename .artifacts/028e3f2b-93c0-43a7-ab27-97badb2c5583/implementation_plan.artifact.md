# Implementation Plan - Interactive Platform Popup

This plan details the implementation of an interactive platform "channel" popup that appears when clicking on the platform badge in the video feed.

## User Review Required

> [!IMPORTANT]
> - **Platform Data**: Since TMDB doesn't provide subscriber counts or specific channel descriptions for streaming services, I will use high-quality **mock data** for major platforms (Netflix, Disney+, etc.) to match the high-fidelity UI requirements.
> - **Redirection**: Tapping "Voir la plateforme" will open the official URL in the browser.
> - **Visuals**: The popup will be a centered dark card with neon accents, matching the provided design.

## Proposed Changes

### 1. Data Layer

#### [MODIFY] [tmdb_service.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/core/services/tmdb_service.dart)
- Update `getTrendingWithVideos()` to extract the primary streaming provider (Netflix, Disney+, etc.) for each movie using the `watch/providers` metadata.
- Map the provider name to a normalized key (e.g., 'netflix', 'disney').

### 2. UI Components

#### [NEW] [platform_popup.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/home/presentation/widgets/platform_popup.dart)
- Create a dedicated widget for the platform details card.
- **Features**:
    - Platform logo (circular).
    - Platform name & subscriber count.
    - Custom description.
    - "Suivre" (Follow) button with a gradient look.
    - "Voir la plateforme" text link.
    - Close button (X) in the top-right.

### 3. Screen Integration

#### [MODIFY] [video_feed_screen.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/home/presentation/screens/video_feed_screen.dart)
- Update `_buildPlatformBadge` to:
    - Display the actual platform name from the movie data.
    - On tap, trigger `showDialog` to display the `PlatformPopup`.

## Verification Plan

### Manual Verification
- [ ] Open the Accueil tab and wait for a video to load.
- [ ] Tap the platform badge (e.g., "Netflix" or "Disney+").
- [ ] Verify the popup matches the requested design (centered card, follow button, description).
- [ ] Tap "Suivre" and verify it provides visual feedback.
- [ ] Tap "Voir la plateforme" and confirm it opens the browser.
- [ ] Tap the "X" or outside the card to close the popup.
