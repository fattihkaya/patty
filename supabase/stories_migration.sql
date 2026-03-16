-- Migration: Pet Stories (24-hour content)
-- Phase 4: Social Features

-- Pet stories table
CREATE TABLE IF NOT EXISTS pet_stories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  image_url TEXT NOT NULL,
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL, -- 24 hours after creation
  view_count INTEGER DEFAULT 0,
  is_active BOOLEAN DEFAULT true,
  CHECK (expires_at > created_at)
);

-- Story views table (track who viewed which story)
CREATE TABLE IF NOT EXISTS story_views (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  story_id UUID REFERENCES pet_stories(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(story_id, user_id)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_pet_stories_pet_id ON pet_stories(pet_id);
CREATE INDEX IF NOT EXISTS idx_pet_stories_user_id ON pet_stories(user_id);
CREATE INDEX IF NOT EXISTS idx_pet_stories_created_at ON pet_stories(created_at);
CREATE INDEX IF NOT EXISTS idx_pet_stories_expires_at ON pet_stories(expires_at);
CREATE INDEX IF NOT EXISTS idx_pet_stories_is_active ON pet_stories(is_active);
CREATE INDEX IF NOT EXISTS idx_story_views_story_id ON story_views(story_id);
CREATE INDEX IF NOT EXISTS idx_story_views_user_id ON story_views(user_id);

-- Function to mark story as viewed and increment view count
CREATE OR REPLACE FUNCTION view_story(p_story_id UUID, p_user_id UUID)
RETURNS void AS $$
BEGIN
  -- Insert view record (or ignore if already viewed)
  INSERT INTO story_views (story_id, user_id)
  VALUES (p_story_id, p_user_id)
  ON CONFLICT (story_id, user_id) DO NOTHING;
  
  -- Increment view count (only once per user)
  UPDATE pet_stories
  SET view_count = view_count + 1
  WHERE id = p_story_id
    AND NOT EXISTS (
      SELECT 1 FROM story_views
      WHERE story_id = p_story_id AND user_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get active stories for a user (from followed pets)
CREATE OR REPLACE FUNCTION get_active_stories_for_user(p_user_id UUID)
RETURNS TABLE (
  story_id UUID,
  pet_id UUID,
  pet_name TEXT,
  pet_photo_url TEXT,
  image_url TEXT,
  caption TEXT,
  created_at TIMESTAMP WITH TIME ZONE,
  view_count INTEGER,
  is_viewed BOOLEAN
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    s.id,
    s.pet_id,
    p.name,
    p.photo_url,
    s.image_url,
    s.caption,
    s.created_at,
    s.view_count,
    EXISTS(SELECT 1 FROM story_views sv WHERE sv.story_id = s.id AND sv.user_id = p_user_id) as is_viewed
  FROM pet_stories s
  JOIN pets p ON s.pet_id = p.id
  LEFT JOIN user_follows uf ON uf.following_id = s.user_id AND uf.follower_id = p_user_id
  WHERE s.is_active = true
    AND s.expires_at > NOW()
    AND (
      -- User's own pets
      p.owner_id = p_user_id
      -- Or pets from users they follow
      OR uf.id IS NOT NULL
      -- Or public pets (if visibility is public)
      OR EXISTS (
        SELECT 1 FROM daily_logs dl
        WHERE dl.pet_id = p.id
        AND dl.visibility = 'public'
        LIMIT 1
      )
    )
  ORDER BY s.created_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to cleanup expired stories (should be run periodically via cron)
CREATE OR REPLACE FUNCTION cleanup_expired_stories()
RETURNS INTEGER AS $$
DECLARE
  v_deleted_count INTEGER;
BEGIN
  UPDATE pet_stories
  SET is_active = false
  WHERE expires_at < NOW()
    AND is_active = true;
  
  GET DIAGNOSTICS v_deleted_count = ROW_COUNT;
  RETURN v_deleted_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- RLS Policies
ALTER TABLE pet_stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_views ENABLE ROW LEVEL SECURITY;

-- RLS: Users can view active stories from their own pets or pets they follow
CREATE POLICY "Users can view active stories" ON pet_stories
  FOR SELECT USING (
    is_active = true
    AND expires_at > NOW()
    AND (
      -- Own pets
      EXISTS (SELECT 1 FROM pets WHERE pets.id = pet_stories.pet_id AND pets.owner_id = auth.uid())
      -- Or pets from users they follow
      OR EXISTS (
        SELECT 1 FROM user_follows uf
        JOIN pets p ON p.owner_id = uf.following_id
        WHERE uf.follower_id = auth.uid()
        AND p.id = pet_stories.pet_id
      )
      -- Or public pets
      OR EXISTS (
        SELECT 1 FROM daily_logs dl
        WHERE dl.pet_id = pet_stories.pet_id
        AND dl.visibility = 'public'
        LIMIT 1
      )
    )
  );

-- RLS: Users can create stories for their own pets
CREATE POLICY "Users can create stories for their pets" ON pet_stories
  FOR INSERT WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM pets
      WHERE pets.id = pet_stories.pet_id
      AND pets.owner_id = auth.uid()
    )
  );

-- RLS: Users can update their own stories
CREATE POLICY "Users can update their own stories" ON pet_stories
  FOR UPDATE USING (auth.uid() = user_id);

-- RLS: Users can delete their own stories
CREATE POLICY "Users can delete their own stories" ON pet_stories
  FOR DELETE USING (auth.uid() = user_id);

-- RLS: Users can view story views (their own views)
CREATE POLICY "Users can view story views" ON story_views
  FOR SELECT USING (
    auth.uid() = user_id
    OR EXISTS (
      SELECT 1 FROM pet_stories s
      JOIN pets p ON s.pet_id = p.id
      WHERE s.id = story_views.story_id
      AND p.owner_id = auth.uid()
    )
  );

-- RLS: Users can insert their own story views
CREATE POLICY "Users can insert story views" ON story_views
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Grants
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_stories TO authenticated;
GRANT SELECT, INSERT ON story_views TO authenticated;
