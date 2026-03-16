-- Migration: Achievement System & Points Shop
-- Phase 2: Gamification Enhancement

-- Achievements table (achievement definitions)
CREATE TABLE IF NOT EXISTS achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  code TEXT UNIQUE NOT NULL, -- 'first_log', 'streak_7', 'perfect_month', etc.
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT, -- Icon identifier for UI
  points_reward INTEGER DEFAULT 0,
  category TEXT DEFAULT 'general', -- 'streak', 'log_count', 'health', 'social', 'financial'
  rarity TEXT DEFAULT 'common' CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
  is_active BOOLEAN DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- User achievements table (unlocked achievements)
CREATE TABLE IF NOT EXISTS user_achievements (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  achievement_id UUID REFERENCES achievements(id) ON DELETE CASCADE NOT NULL,
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  pet_id UUID REFERENCES pets(id) ON DELETE SET NULL, -- If achievement is pet-specific
  metadata JSONB DEFAULT '{}'::jsonb, -- Additional achievement data
  UNIQUE(user_id, achievement_id)
);

-- Points shop items
CREATE TABLE IF NOT EXISTS points_shop_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  icon_name TEXT,
  points_cost INTEGER NOT NULL,
  item_type TEXT NOT NULL CHECK (item_type IN ('premium_trial', 'badge', 'customization', 'discount', 'theme')),
  item_value TEXT, -- JSON or string value for the item
  is_available BOOLEAN DEFAULT true,
  stock_limit INTEGER, -- NULL for unlimited
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Points redemptions
CREATE TABLE IF NOT EXISTS points_redemptions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  shop_item_id UUID REFERENCES points_shop_items(id) ON DELETE CASCADE NOT NULL,
  points_spent INTEGER NOT NULL,
  redeemed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  status TEXT DEFAULT 'active' CHECK (status IN ('active', 'used', 'expired')),
  expires_at TIMESTAMP WITH TIME ZONE, -- For trial items
  metadata JSONB DEFAULT '{}'::jsonb,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Streak rewards configuration
CREATE TABLE IF NOT EXISTS streak_rewards (
  milestone_days INTEGER PRIMARY KEY, -- 7, 14, 30, 60, 100
  reward_type TEXT NOT NULL CHECK (reward_type IN ('badge', 'premium_trial', 'points', 'discount', 'achievement')),
  reward_value TEXT NOT NULL, -- Points amount, badge code, premium days, etc.
  reward_name TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- User badges (unlocked badges)
CREATE TABLE IF NOT EXISTS user_badges (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  badge_code TEXT NOT NULL, -- 'streak_7', 'perfect_month', etc.
  unlocked_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  source TEXT, -- 'achievement', 'streak_reward', 'shop_purchase'
  display_order INTEGER DEFAULT 0,
  UNIQUE(user_id, badge_code)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_user_achievements_user_id ON user_achievements(user_id);
CREATE INDEX IF NOT EXISTS idx_user_achievements_achievement_id ON user_achievements(achievement_id);
CREATE INDEX IF NOT EXISTS idx_points_redemptions_user_id ON points_redemptions(user_id);
CREATE INDEX IF NOT EXISTS idx_user_badges_user_id ON user_badges(user_id);

-- Insert default achievements
INSERT INTO achievements (code, name, description, icon_name, points_reward, category, rarity, display_order) VALUES
('first_log', 'İlk Adım', 'İlk günlük kaydını oluşturdun!', 'first_step', 50, 'log_count', 'common', 1),
('log_10', 'Düzenli Takip', '10 günlük kayıt oluşturdun', 'calendar', 100, 'log_count', 'common', 2),
('log_50', 'Uzman Gözlemci', '50 günlük kayıt oluşturdun', 'analytics', 250, 'log_count', 'rare', 3),
('log_100', 'Sağlık Dedektifi', '100 günlük kayıt oluşturdun', 'detective', 500, 'log_count', 'epic', 4),
('log_500', 'Efsane Takipçi', '500 günlük kayıt oluşturdun', 'legend', 1000, 'log_count', 'legendary', 5),
('streak_7', 'Haftalık Şampiyon', '7 gün üst üste kayıt oluşturdun', 'flame', 100, 'streak', 'common', 6),
('streak_14', 'İki Haftalık Seri', '14 gün üst üste kayıt oluşturdun', 'flame_strong', 200, 'streak', 'rare', 7),
('streak_30', 'Mükemmel Ay', '30 gün üst üste kayıt oluşturdun', 'perfect_month', 500, 'streak', 'epic', 8),
('streak_60', 'İki Aylık Disiplin', '60 gün üst üste kayıt oluşturdun', 'discipline', 750, 'streak', 'epic', 9),
('streak_100', 'Yüz Günlük Efsane', '100 gün üst üste kayıt oluşturdun', 'legend_flame', 1500, 'streak', 'legendary', 10),
('perfect_health', 'Mükemmel Sağlık', 'Tüm parametrelerde 5/5 skor aldın', 'perfect', 300, 'health', 'rare', 11),
('health_improvement', 'İyileşme Ustası', 'Sağlık skorunu 1 ay içinde %20 artırdın', 'improvement', 250, 'health', 'rare', 12),
('social_100_likes', 'Sosyal Kelebek', 'Logların toplam 100 beğeni aldı', 'social', 200, 'social', 'common', 13),
('social_500_likes', 'Popüler İçerik', 'Logların toplam 500 beğeni aldı', 'viral', 500, 'social', 'epic', 14),
('budget_master', 'Finans Ustası', 'Bir ay boyunca bütçende kaldın', 'budget', 150, 'financial', 'common', 15),
('early_adopter', 'Erken Kullanıcı', 'Uygulamanın ilk 1000 kullanıcısındansın', 'rocket', 1000, 'general', 'legendary', 16)
ON CONFLICT (code) DO NOTHING;

-- Insert default points shop items
INSERT INTO points_shop_items (name, description, icon_name, points_cost, item_type, item_value, display_order) VALUES
('3 Gün Premium Trial', 'Premium özellikleri 3 gün ücretsiz dene', 'premium', 500, 'premium_trial', '{"days": 3}', 1),
('7 Gün Premium Trial', 'Premium özellikleri 1 hafta ücretsiz dene', 'premium_week', 1000, 'premium_trial', '{"days": 7}', 2),
('Özel Profil Teması', 'Profilin için özel renk teması', 'theme', 300, 'customization', '{"theme": "custom"}', 3),
('Premium Badge', 'Özel Premium rozeti', 'badge_premium', 750, 'badge', '{"badge": "premium_supporter"}', 4),
('%10 Premium İndirimi', 'Yıllık Premium alırken %10 indirim', 'discount', 1500, 'discount', '{"discount": 10, "type": "yearly"}', 5),
('Özel Pet Avatar Frame', 'Pet profilinde özel çerçeve', 'frame', 400, 'customization', '{"frame": "special"}', 6)
ON CONFLICT DO NOTHING;

-- Insert default streak rewards
INSERT INTO streak_rewards (milestone_days, reward_type, reward_value, reward_name, description) VALUES
(7, 'achievement', 'streak_7', 'Haftalık Şampiyon Rozeti', '7 günlük seri için özel rozet'),
(14, 'points', '200', '200 Pati Puanı', '14 günlük seri için bonus puan'),
(30, 'premium_trial', '7', '7 Gün Premium Ücretsiz', 'Mükemmel ay için 1 haftalık Premium trial'),
(60, 'achievement', 'streak_60', 'Disiplin Rozeti', '60 günlük disiplin için özel rozet'),
(100, 'points', '1500', '1500 Pati Puanı', '100 günlük efsane seri için büyük ödül')
ON CONFLICT (milestone_days) DO NOTHING;

-- Function to check and grant achievements
CREATE OR REPLACE FUNCTION check_and_grant_achievement(
  p_user_id UUID,
  p_achievement_code TEXT,
  p_pet_id UUID DEFAULT NULL
)
RETURNS BOOLEAN AS $$
DECLARE
  v_achievement_id UUID;
  v_already_unlocked BOOLEAN;
BEGIN
  -- Get achievement ID
  SELECT id INTO v_achievement_id
  FROM achievements
  WHERE code = p_achievement_code AND is_active = true;
  
  IF v_achievement_id IS NULL THEN
    RETURN false;
  END IF;
  
  -- Check if already unlocked
  SELECT EXISTS(
    SELECT 1 FROM user_achievements
    WHERE user_id = p_user_id AND achievement_id = v_achievement_id
  ) INTO v_already_unlocked;
  
  IF v_already_unlocked THEN
    RETURN false;
  END IF;
  
  -- Grant achievement
  INSERT INTO user_achievements (user_id, achievement_id, pet_id)
  VALUES (p_user_id, v_achievement_id, p_pet_id);
  
  -- Add points to user
  UPDATE profiles
  SET total_pati_points = COALESCE(total_pati_points, 0) + (
    SELECT points_reward FROM achievements WHERE id = v_achievement_id
  )
  WHERE id = p_user_id;
  
  RETURN true;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check streak milestones and grant rewards
CREATE OR REPLACE FUNCTION check_streak_milestones(p_user_id UUID)
RETURNS void AS $$
DECLARE
  v_current_streak INTEGER;
  v_reward_record RECORD;
BEGIN
  -- Get current streak
  SELECT current_streak INTO v_current_streak
  FROM profiles
  WHERE id = p_user_id;
  
  IF v_current_streak IS NULL OR v_current_streak = 0 THEN
    RETURN;
  END IF;
  
  -- Check if milestone reached
  FOR v_reward_record IN
    SELECT * FROM streak_rewards
    WHERE milestone_days = v_current_streak
  LOOP
    -- Grant achievement if reward is achievement
    IF v_reward_record.reward_type = 'achievement' THEN
      PERFORM check_and_grant_achievement(p_user_id, v_reward_record.reward_value);
    END IF;
    
    -- Add points if reward is points
    IF v_reward_record.reward_type = 'points' THEN
      UPDATE profiles
      SET total_pati_points = COALESCE(total_pati_points, 0) + v_reward_record.reward_value::INTEGER
      WHERE id = p_user_id;
    END IF;
  END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to check streak milestones on streak update
CREATE OR REPLACE FUNCTION trigger_check_streak_milestones()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.current_streak > OLD.current_streak THEN
    PERFORM check_streak_milestones(NEW.id);
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_streak_updated ON profiles;
CREATE TRIGGER on_streak_updated
  AFTER UPDATE OF current_streak ON profiles
  FOR EACH ROW
  WHEN (NEW.current_streak > OLD.current_streak)
  EXECUTE FUNCTION trigger_check_streak_milestones();

-- RLS Policies
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_shop_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE points_redemptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE streak_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges ENABLE ROW LEVEL SECURITY;

-- RLS: Anyone can view active achievements
CREATE POLICY "Anyone can view active achievements" ON achievements
  FOR SELECT USING (is_active = true);

-- RLS: Users can view their own achievements
CREATE POLICY "Users can view their own achievements" ON user_achievements
  FOR SELECT USING (auth.uid() = user_id);

-- RLS: System can insert achievements (via functions)
CREATE POLICY "System can insert user achievements" ON user_achievements
  FOR INSERT WITH CHECK (true);

-- RLS: Anyone can view available shop items
CREATE POLICY "Anyone can view available shop items" ON points_shop_items
  FOR SELECT USING (is_available = true);

-- RLS: Users can view their own redemptions
CREATE POLICY "Users can view their own redemptions" ON points_redemptions
  FOR SELECT USING (auth.uid() = user_id);

-- RLS: Users can insert their own redemptions
CREATE POLICY "Users can insert their own redemptions" ON points_redemptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- RLS: Anyone can view streak rewards
CREATE POLICY "Anyone can view streak rewards" ON streak_rewards
  FOR SELECT USING (true);

-- RLS: Users can view their own badges
CREATE POLICY "Users can view their own badges" ON user_badges
  FOR SELECT USING (auth.uid() = user_id);

-- RLS: System can insert badges
CREATE POLICY "System can insert badges" ON user_badges
  FOR INSERT WITH CHECK (true);

-- Grants
GRANT SELECT ON achievements TO authenticated;
GRANT SELECT, INSERT ON user_achievements TO authenticated;
GRANT SELECT ON points_shop_items TO authenticated;
GRANT SELECT, INSERT ON points_redemptions TO authenticated;
GRANT SELECT ON streak_rewards TO authenticated;
GRANT SELECT, INSERT ON user_badges TO authenticated;
