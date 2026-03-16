-- Migration: Add streaks, leaderboard, and scoring system

-- Add streak tracking to profiles
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS current_streak INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS longest_streak INTEGER DEFAULT 0;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS last_log_date DATE;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS total_pati_points INTEGER DEFAULT 0;

-- Add scoring to daily_logs
ALTER TABLE daily_logs ADD COLUMN IF NOT EXISTS total_score NUMERIC(5,2); -- Average of all 10 parameter scores

-- Create leaderboard view (weekly)
CREATE OR REPLACE VIEW weekly_leaderboard AS
SELECT 
  p.id as pet_id,
  p.name as pet_name,
  p.photo_url,
  pr.email as owner_email,
  AVG(dl.total_score) as avg_score,
  COUNT(dl.id) as log_count,
  MAX(dl.created_at) as last_log_date
FROM pets p
JOIN profiles pr ON p.owner_id = pr.id
LEFT JOIN daily_logs dl ON p.id = dl.pet_id 
  AND dl.created_at >= date_trunc('week', CURRENT_DATE)
GROUP BY p.id, p.name, p.photo_url, pr.email
HAVING COUNT(dl.id) > 0
ORDER BY avg_score DESC, log_count DESC
LIMIT 100;

-- Create leaderboard view (global/all-time)
CREATE OR REPLACE VIEW global_leaderboard AS
SELECT 
  p.id as pet_id,
  p.name as pet_name,
  p.photo_url,
  pr.email as owner_email,
  AVG(dl.total_score) as avg_score,
  COUNT(dl.id) as log_count,
  MAX(dl.created_at) as last_log_date
FROM pets p
JOIN profiles pr ON p.owner_id = pr.id
LEFT JOIN daily_logs dl ON p.id = dl.pet_id
GROUP BY p.id, p.name, p.photo_url, pr.email
HAVING COUNT(dl.id) > 0
ORDER BY avg_score DESC, log_count DESC
LIMIT 100;

-- Function to update streak on log insert
CREATE OR REPLACE FUNCTION update_user_streak()
RETURNS TRIGGER AS $$
DECLARE
  user_id UUID;
  last_date DATE;
  current_streak_count INTEGER;
  longest_streak_count INTEGER;
  log_date DATE;
BEGIN
  -- Get pet owner
  SELECT owner_id INTO user_id FROM pets WHERE id = NEW.pet_id;
  
  IF user_id IS NULL THEN
    RETURN NEW;
  END IF;
  
  log_date := DATE(NEW.created_at);
  
  -- Get current streak info
  SELECT current_streak, longest_streak, last_log_date
  INTO current_streak_count, longest_streak_count, last_date
  FROM profiles
  WHERE id = user_id;
  
  IF last_date IS NULL OR last_date < log_date THEN
    -- New day
    IF last_date IS NULL OR last_date = log_date - INTERVAL '1 day' THEN
      -- Consecutive day
      current_streak_count := COALESCE(current_streak_count, 0) + 1;
    ELSE
      -- Streak broken
      current_streak_count := 1;
    END IF;
    
    -- Update longest streak if needed
    IF current_streak_count > COALESCE(longest_streak_count, 0) THEN
      longest_streak_count := current_streak_count;
    END IF;
    
    -- Update profile
    UPDATE profiles
    SET 
      current_streak = current_streak_count,
      longest_streak = longest_streak_count,
      last_log_date = log_date,
      total_pati_points = COALESCE(total_pati_points, 0) + 10 -- 10 points per log
    WHERE id = user_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to update streak
DROP TRIGGER IF EXISTS on_daily_log_inserted ON daily_logs;
CREATE TRIGGER on_daily_log_inserted
  AFTER INSERT ON daily_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_user_streak();

-- Function to calculate total_score from AI comment JSON
CREATE OR REPLACE FUNCTION calculate_log_score()
RETURNS TRIGGER AS $$
DECLARE
  parsed_json JSONB;
  score_sum NUMERIC := 0;
  score_count INTEGER := 0;
  param_key TEXT;
  param_score NUMERIC;
BEGIN
  -- Try to parse AI comment as JSON
  IF NEW.ai_comment IS NOT NULL THEN
    BEGIN
      parsed_json := NEW.ai_comment::JSONB;
    EXCEPTION
      WHEN OTHERS THEN
        RETURN NEW; -- Not valid JSON, skip
    END;
    
    -- Calculate average of all parameter scores
    FOR param_key IN SELECT unnest(ARRAY[
      'fur_luster_score',
      'skin_hygiene_score',
      'eye_clarity_score',
      'nasal_discharge_score',
      'ear_posture_score',
      'weight_index_score',
      'posture_alignment_score',
      'facial_relaxation_score',
      'energy_vibe_score',
      'stress_level_score'
    ]) LOOP
      param_score := (parsed_json->>param_key)::NUMERIC;
      IF param_score IS NOT NULL AND param_score BETWEEN 1 AND 5 THEN
        score_sum := score_sum + param_score;
        score_count := score_count + 1;
      END IF;
    END LOOP;
    
    -- Also include mood_score and energy_score if available
    param_score := (parsed_json->>'mood_score')::NUMERIC;
    IF param_score IS NOT NULL AND param_score BETWEEN 1 AND 5 THEN
      score_sum := score_sum + param_score;
      score_count := score_count + 1;
    END IF;
    
    param_score := (parsed_json->>'energy_score')::NUMERIC;
    IF param_score IS NOT NULL AND param_score BETWEEN 1 AND 5 THEN
      score_sum := score_sum + param_score;
      score_count := score_count + 1;
    END IF;
    
    -- Set total_score
    IF score_count > 0 THEN
      NEW.total_score := score_sum / score_count;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to calculate score on insert/update
DROP TRIGGER IF EXISTS on_log_score_calculation ON daily_logs;
CREATE TRIGGER on_log_score_calculation
  BEFORE INSERT OR UPDATE ON daily_logs
  FOR EACH ROW
  EXECUTE FUNCTION calculate_log_score();

-- Grant access to leaderboard views
GRANT SELECT ON weekly_leaderboard TO authenticated;
GRANT SELECT ON global_leaderboard TO authenticated;
