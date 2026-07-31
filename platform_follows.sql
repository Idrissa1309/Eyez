-- Create table for following platforms/channels
CREATE TABLE IF NOT EXISTS public.platform_follows (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  platform_name TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now() NOT NULL,
  UNIQUE(user_id, platform_name)
);

-- Enable Row Level Security
ALTER TABLE public.platform_follows ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can see their own follows" ON public.platform_follows
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can follow platforms" ON public.platform_follows
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unfollow platforms" ON public.platform_follows
  FOR DELETE USING (auth.uid() = user_id);