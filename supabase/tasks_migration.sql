-- Migration: Add tasks system for pets

-- Tasks table (template tasks for different pet types)
CREATE TABLE IF NOT EXISTS tasks (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  pet_type TEXT NOT NULL CHECK (pet_type IN ('dog', 'cat', 'bird', 'rabbit', 'hamster', 'other')),
  category TEXT NOT NULL CHECK (category IN ('health', 'care', 'hygiene', 'social', 'training')),
  frequency_days INTEGER DEFAULT 1, -- How often this task should be done (e.g., 7 for weekly)
  points INTEGER DEFAULT 10, -- Pati points earned when completed
  icon_name TEXT, -- Icon identifier for UI
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Pet task completions (user's completed tasks)
CREATE TABLE IF NOT EXISTS pet_task_completions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  notes TEXT,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);


-- Task notifications (scheduled reminders)
CREATE TABLE IF NOT EXISTS task_notifications (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  scheduled_for TIMESTAMP WITH TIME ZONE NOT NULL,
  is_sent BOOLEAN DEFAULT false,
  sent_at TIMESTAMP WITH TIME ZONE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Insert default tasks for different pet types
INSERT INTO tasks (name, description, pet_type, category, frequency_days, points, icon_name) VALUES
-- Dog tasks
('Aşı Kontrolü', 'Yıllık aşılarını kontrol et', 'dog', 'health', 365, 50, 'vaccines'),
('Veteriner Kontrolü', 'Düzenli sağlık kontrolü', 'dog', 'health', 180, 30, 'medical_services'),
('Tırnak Kesimi', 'Tırnaklarını kes', 'dog', 'care', 30, 15, 'content_cut'),
('Banyo', 'Banyo yaptır', 'dog', 'hygiene', 14, 20, 'bathtub'),
('Diş Fırçalama', 'Dişlerini fırçala', 'dog', 'hygiene', 1, 10, 'brush'),
('Egzersiz', 'Günlük yürüyüş veya oyun', 'dog', 'health', 1, 15, 'directions_run'),
('Köpek Eğitimi', 'Temel komutlar ve sosyalleşme', 'dog', 'training', 7, 25, 'school'),

-- Cat tasks
('Aşı Kontrolü', 'Yıllık aşılarını kontrol et', 'cat', 'health', 365, 50, 'vaccines'),
('Veteriner Kontrolü', 'Düzenli sağlık kontrolü', 'cat', 'health', 180, 30, 'medical_services'),
('Kum Değişimi', 'Kum kabını temizle ve değiştir', 'cat', 'hygiene', 3, 15, 'cleaning_services'),
('Tırnak Kesimi', 'Tırnaklarını kes', 'cat', 'care', 30, 15, 'content_cut'),
('Banyo', 'Banyo yaptır (gerekirse)', 'cat', 'hygiene', 60, 20, 'bathtub'),
('Diş Fırçalama', 'Dişlerini fırçala', 'cat', 'hygiene', 1, 10, 'brush'),
('Oyun Zamanı', 'Günlük oyun ve aktivite', 'cat', 'social', 1, 15, 'sports_esports'),

-- Bird tasks
('Aşı Kontrolü', 'Yıllık aşılarını kontrol et', 'bird', 'health', 365, 50, 'vaccines'),
('Veteriner Kontrolü', 'Düzenli sağlık kontrolü', 'bird', 'health', 180, 30, 'medical_services'),
('Kafes Temizliği', 'Kafesi temizle', 'bird', 'hygiene', 3, 15, 'cleaning_services'),
('Su Değişimi', 'Su kabını temizle ve değiştir', 'bird', 'hygiene', 1, 10, 'water_drop'),
('Tünek Temizliği', 'Tünekleri temizle', 'bird', 'hygiene', 7, 10, 'cleaning_services'),
('Sosyalleşme', 'Onunla vakit geçir', 'bird', 'social', 1, 15, 'favorite'),

-- Rabbit tasks
('Aşı Kontrolü', 'Yıllık aşılarını kontrol et', 'rabbit', 'health', 365, 50, 'vaccines'),
('Veteriner Kontrolü', 'Düzenli sağlık kontrolü', 'rabbit', 'health', 180, 30, 'medical_services'),
('Kafes Temizliği', 'Kafesi temizle', 'rabbit', 'hygiene', 3, 15, 'cleaning_services'),
('Su Değişimi', 'Su kabını temizle ve değiştir', 'rabbit', 'hygiene', 1, 10, 'water_drop'),
('Tırnak Kesimi', 'Tırnaklarını kes', 'rabbit', 'care', 30, 15, 'content_cut'),
('Oyun Zamanı', 'Günlük oyun ve aktivite', 'rabbit', 'social', 1, 15, 'sports_esports'),

-- Hamster tasks
('Veteriner Kontrolü', 'Düzenli sağlık kontrolü', 'hamster', 'health', 180, 30, 'medical_services'),
('Kafes Temizliği', 'Kafesi temizle', 'hamster', 'hygiene', 3, 15, 'cleaning_services'),
('Su Değişimi', 'Su kabını temizle ve değiştir', 'hamster', 'hygiene', 1, 10, 'water_drop'),
('Yemek Verme', 'Günlük yemek kontrolü', 'hamster', 'care', 1, 10, 'restaurant'),
('Oyun Zamanı', 'Günlük oyun ve aktivite', 'hamster', 'social', 1, 15, 'sports_esports'),

-- General tasks (for all types)
('Ağırlık Kontrolü', 'Ağırlığını ölç ve kaydet', 'other', 'health', 30, 15, 'monitor_weight'),
('Fotoğraf Çek', 'Günlük fotoğraf çek', 'other', 'care', 1, 10, 'camera_alt'),
('Sağlık Notu', 'Sağlık durumu hakkında not al', 'other', 'health', 7, 10, 'note');

-- Function to award points when task is completed
CREATE OR REPLACE FUNCTION award_task_points()
RETURNS TRIGGER AS $$
DECLARE
  task_points INTEGER;
  user_id UUID;
BEGIN
  -- Get task points
  SELECT points INTO task_points FROM tasks WHERE id = NEW.task_id;
  
  -- Get pet owner
  SELECT owner_id INTO user_id FROM pets WHERE id = NEW.pet_id;
  
  IF user_id IS NOT NULL AND task_points IS NOT NULL THEN
    -- Update user's total pati points
    UPDATE profiles
    SET total_pati_points = COALESCE(total_pati_points, 0) + task_points
    WHERE id = user_id;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to prevent duplicate completions per day
CREATE OR REPLACE FUNCTION prevent_duplicate_task_completion()
RETURNS TRIGGER AS $$
DECLARE
  existing_count INTEGER;
BEGIN
  -- Check if this task was already completed today for this pet
  SELECT COUNT(*) INTO existing_count
  FROM pet_task_completions
  WHERE pet_id = NEW.pet_id
    AND task_id = NEW.task_id
    AND date_trunc('day', completed_at AT TIME ZONE 'UTC') = date_trunc('day', NEW.completed_at AT TIME ZONE 'UTC');
  
  IF existing_count > 0 THEN
    RAISE EXCEPTION 'Bu görev bugün zaten tamamlandı';
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to prevent duplicate completions
DROP TRIGGER IF EXISTS on_task_completion_prevent_duplicate ON pet_task_completions;
CREATE TRIGGER on_task_completion_prevent_duplicate
  BEFORE INSERT ON pet_task_completions
  FOR EACH ROW
  EXECUTE FUNCTION prevent_duplicate_task_completion();

-- Trigger to award points on task completion
DROP TRIGGER IF EXISTS on_task_completed ON pet_task_completions;
CREATE TRIGGER on_task_completed
  AFTER INSERT ON pet_task_completions
  FOR EACH ROW
  EXECUTE FUNCTION award_task_points();

-- Function to create recurring task notifications
CREATE OR REPLACE FUNCTION schedule_task_notifications()
RETURNS TRIGGER AS $$
DECLARE
  task_frequency INTEGER;
  next_due_date TIMESTAMP WITH TIME ZONE;
  user_id UUID;
BEGIN
  -- Get task frequency
  SELECT frequency_days INTO task_frequency FROM tasks WHERE id = NEW.task_id;
  
  -- Get pet owner
  SELECT owner_id INTO user_id FROM pets WHERE id = NEW.pet_id;
  
  IF user_id IS NOT NULL AND task_frequency IS NOT NULL THEN
    -- Calculate next due date
    next_due_date := NEW.completed_at + (task_frequency || ' days')::INTERVAL;
    
    -- Create notification for next occurrence
    INSERT INTO task_notifications (pet_id, task_id, user_id, scheduled_for)
    VALUES (NEW.pet_id, NEW.task_id, user_id, next_due_date)
    ON CONFLICT DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to schedule next notification
DROP TRIGGER IF EXISTS on_task_completion_schedule ON pet_task_completions;
CREATE TRIGGER on_task_completion_schedule
  AFTER INSERT ON pet_task_completions
  FOR EACH ROW
  EXECUTE FUNCTION schedule_task_notifications();

-- Grant access
GRANT SELECT, INSERT, UPDATE ON tasks TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_task_completions TO authenticated;
GRANT SELECT, INSERT, UPDATE ON task_notifications TO authenticated;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_task_notifications_user_scheduled ON task_notifications(user_id, scheduled_for, is_sent);
