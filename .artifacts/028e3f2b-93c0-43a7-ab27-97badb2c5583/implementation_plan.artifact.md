# Implementation Plan - "Ma Liste" Feature

This plan details how to implement the "Ma Liste" functionality, allowing users to save their favorite movies and TV shows to their personal list in Supabase.

## User Review Required

> [!IMPORTANT]
> - **Database Table**: You need to create a table named `saved_lists` in your Supabase SQL Editor using the script provided below.
> - **Real-time Sync**: The UI will update instantly across the app (Profile and Movie Sheets) using Riverpod.

### SQL Script for Supabase
```sql
create table saved_lists (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  tmdb_id integer not null,
  title text not null,
  poster_path text,
  media_type text,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, tmdb_id)
);

-- Enable RLS
alter table saved_lists enable row level security;

-- Policy: Users can see only their own saved items
create policy "Users can view their own saved items"
  on saved_lists for select
  using ( auth.uid() = user_id );

-- Policy: Users can insert their own saved items
create policy "Users can insert their own saved items"
  on saved_lists for insert
  with check ( auth.uid() = user_id );

-- Policy: Users can delete their own saved items
create policy "Users can delete their own saved items"
  on saved_lists for delete
  using ( auth.uid() = user_id );
```

## Proposed Changes

### Data & State Layer

#### [MODIFY] [supabase_service.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/core/services/supabase_service.dart)
- Add `toggleSavedItem(Map<String, dynamic> movie)`: Adds or removes an item based on its existence.
- Add `getSavedItems()`: Fetches the list for the current user.

#### [NEW] [my_list_providers.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/profile/presentation/providers/my_list_providers.dart)
- Create `myListProvider`: An `AsyncNotifierProvider` that manages the user's saved items.

### UI Implementation

#### [MODIFY] [movie_details_sheet.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/home/presentation/widgets/movie_details_sheet.dart)
- Convert to `ConsumerWidget`.
- Watch `myListProvider` to toggle the "Ma liste" button state (Change icon and text to "Retirer" if already saved).

#### [MODIFY] [profile_screen.dart](file:///C:/Users/I-Dev Sow/Desktop/AndroidStudioProjects/Eyez/lib/features/profile/presentation/screens/profile_screen.dart)
- Convert to `ConsumerWidget`.
- Implement a state variable for the active tab (Vidéos, Listes, etc.).
- When "Listes" is active, display the posters from `myListProvider`.

## Verification Plan

### Manual Verification
- [ ] Open a movie from the Explorer or Feed.
- [ ] Tap "Ma liste". Verify the button changes state.
- [ ] Go to the Profile screen and tap the "Listes" tab. Verify the movie appears in the grid.
- [ ] Tap the movie in the Profile grid. Verify it opens the details sheet.
- [ ] Tap "Retirer" in the details sheet. Verify it disappears from the Profile grid.
