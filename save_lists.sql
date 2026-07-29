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