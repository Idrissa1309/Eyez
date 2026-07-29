-- Likes Table
create table likes (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  video_id text not null, -- Currently we use TMDB IDs or placeholder strings
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(user_id, video_id)
);

-- Comments Table
create table comments (
  id uuid default uuid_generate_v4() primary key,
  user_id uuid references auth.users not null,
  video_id text not null,
  content text not null,
  username text not null, -- Cached for performance
  created_at timestamp with time zone default timezone('utc'::text, now()) not null
);

-- Follows Table
create table follows (
  id uuid default uuid_generate_v4() primary key,
  follower_id uuid references auth.users not null,
  following_id uuid references auth.users not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  unique(follower_id, following_id)
);

-- Enable RLS for all
alter table likes enable row level security;
alter table comments enable row level security;
alter table follows enable row level security;

-- Policies (Simplified for dev)
create policy "Anyone can view likes/comments" on likes for select using (true);
create policy "Users can like videos" on likes for insert with check (auth.uid() = user_id);
create policy "Users can unlike" on likes for delete using (auth.uid() = user_id);

create policy "Anyone can view comments" on comments for select using (true);
create policy "Users can post comments" on comments for insert with check (auth.uid() = user_id);

create policy "Anyone can view follows" on follows for select using (true);
create policy "Users can follow/unfollow" on follows for all using (auth.uid() = follower_id);