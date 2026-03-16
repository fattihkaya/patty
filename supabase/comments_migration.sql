-- Migration: Comment System
-- Phase 4: Social Features

-- Log comments table
CREATE TABLE IF NOT EXISTS log_comments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  log_id UUID REFERENCES daily_logs(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  comment_text TEXT NOT NULL,
  parent_comment_id UUID REFERENCES log_comments(id) ON DELETE CASCADE, -- For nested comments
  is_edited BOOLEAN DEFAULT false,
  edited_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Comment likes table
CREATE TABLE IF NOT EXISTS comment_likes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  comment_id UUID REFERENCES log_comments(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(comment_id, user_id)
);

-- User follows table
CREATE TABLE IF NOT EXISTS user_follows (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  follower_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  following_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id) -- Can't follow yourself
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_log_comments_log_id ON log_comments(log_id);
CREATE INDEX IF NOT EXISTS idx_log_comments_user_id ON log_comments(user_id);
CREATE INDEX IF NOT EXISTS idx_log_comments_parent_id ON log_comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_log_comments_created_at ON log_comments(created_at);
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON comment_likes(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_user_id ON comment_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_follower ON user_follows(follower_id);
CREATE INDEX IF NOT EXISTS idx_user_follows_following ON user_follows(following_id);

-- Function to get comment count for a log
CREATE OR REPLACE FUNCTION get_log_comment_count(p_log_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM log_comments
  WHERE log_id = p_log_id;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get like count for a comment
CREATE OR REPLACE FUNCTION get_comment_like_count(p_comment_id UUID)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO v_count
  FROM comment_likes
  WHERE comment_id = p_comment_id;
  
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE log_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_follows ENABLE ROW LEVEL SECURITY;

-- RLS: Anyone can view comments on public/members logs
CREATE POLICY "Anyone can view comments on visible logs" ON log_comments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM daily_logs
      WHERE daily_logs.id = log_comments.log_id
        AND (daily_logs.visibility = 'public' OR daily_logs.visibility = 'members')
    )
  );

-- RLS: Authenticated users can insert comments on visible logs
CREATE POLICY "Authenticated users can insert comments" ON log_comments
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM daily_logs
      WHERE daily_logs.id = log_comments.log_id
        AND (daily_logs.visibility = 'public' OR daily_logs.visibility = 'members')
    )
  );

-- RLS: Users can update their own comments
CREATE POLICY "Users can update their own comments" ON log_comments
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- RLS: Users can delete their own comments
CREATE POLICY "Users can delete their own comments" ON log_comments
  FOR DELETE USING (auth.uid() = user_id);

-- RLS: Anyone can view comment likes
CREATE POLICY "Anyone can view comment likes" ON comment_likes
  FOR SELECT USING (true);

-- RLS: Authenticated users can like/unlike comments
CREATE POLICY "Authenticated users can like comments" ON comment_likes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS: Users can delete their own likes
CREATE POLICY "Users can delete their own likes" ON comment_likes
  FOR DELETE USING (auth.uid() = user_id);

-- RLS: Anyone can view follows
CREATE POLICY "Anyone can view follows" ON user_follows
  FOR SELECT USING (true);

-- RLS: Authenticated users can follow others
CREATE POLICY "Authenticated users can follow others" ON user_follows
  FOR INSERT WITH CHECK (auth.uid() = follower_id);

-- RLS: Users can unfollow (delete their own follow)
CREATE POLICY "Users can unfollow" ON user_follows
  FOR DELETE USING (auth.uid() = follower_id);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON log_comments TO authenticated;
GRANT SELECT, INSERT, DELETE ON comment_likes TO authenticated;
GRANT SELECT, INSERT, DELETE ON user_follows TO authenticated;
