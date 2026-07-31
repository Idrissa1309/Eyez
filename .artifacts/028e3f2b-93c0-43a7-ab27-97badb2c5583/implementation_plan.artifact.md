# Implementation Plan - Feature Enrichment & Content Realism

This plan focuses on making movie metadata dynamic, implementing the History feature, and enriching the Explorer screen with Genres and Platforms as requested.

## User Review Required

> [!IMPORTANT]
> **Action Required in Supabase**: To enable the **History** feature, please execute the following SQL in your Supabase dashboard:
>
> ```sql
> -- Create table for user watch history
> CREATE TABLE IF NOT EXISTS public.history (
>   id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
>   user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
>   tmdb_id INTEGER NOT NULL,
>   title TEXT NOT NULL,
>   poster_path TEXT,
>   watched_at TIMESTAMPTZ DEFAULT now() NOT NULL,
>   UNIQUE(user_id, tmdb_id) -- Updates the same movie entry
> );
>
> -- Enable Row Level Security
> ALTER TABLE public.history ENABLE ROW LEVEL SECURITY;
>
> -- Create policies
> CREATE POLICY "Users can see their own history" ON public.history
>   FOR SELECT USING (auth.uid() = user_id);
> CREATE POLICY "Users can manage their history" ON public.history
>   FOR ALL USING (auth.uid() = user_id);
> ```

## Proposed Changes

### 1. Real Metadata & Dynamic Content
- **`movie_details_sheet.dart`**: Replace hardcoded "EN" and "Netflix" with actual data from the `movie` object (`original_language`, `platform`).
- **`tmdb_service.dart`**: Ensure `original_language` is included and formatted (e.g., 'fr' -> 'FR').

### 2. Profile Overhaul
- **Stats**:
    - Remove "Abonnés".
    - Update "Abonnements" to show the real count of followed platforms.
    - Update "J'aime" to show the real count of liked videos.
- **History Feature**:
    - **`supabase_service.dart`**: Add `addToHistory(movie)` and `getHistory()`.
    - **`video_feed_screen.dart`**: Trigger `addToHistory` when a video remains in focus for more than 3 seconds.
    - **`profile_screen.dart`**: Implement the "Historique" tab to show a grid of recently watched content.

### 3. Platform & Channel Experience
- **`platform_popup.dart`**: Fix platform logo display and add a tap action to the header to navigate to the new `PlatformChannelScreen`.
- **`PlatformChannelScreen`**: [NEW] A dedicated page for a streaming platform (e.g., Disney+) showing its description, subscriber count, and a grid of its featured movies.

### 4. Explorer Screen Enrichment
- **`explorer_screen.dart`**:
    - Add a **Genres** horizontal list (Action, Aventure, Animation, etc.).
    - Add a **Plateformes** horizontal list with small logos (Netflix, Prime, Disney+, etc.).
    - Update the filtering logic to combine Category, Genre, and Platform selections.

## Verification Plan

### Manual Verification
- [ ] Open a movie, verify its language (e.g., FR) and platform (e.g., Disney+) are correct in the popup.
- [ ] Check Profile stats: confirm they match your actual follows and likes.
- [ ] Watch a video for 5 seconds, go to Profile -> Historique, and verify it appears there.
- [ ] In Explorer, tap "Animation" and "Crunchyroll" to verify the results are filtered correctly.
- [ ] Click the Disney+ logo in a popup to open its dedicated "Channel" page.
