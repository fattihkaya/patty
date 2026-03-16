-- Migration: Add pet task assignments for automatic task assignment and user customization

-- Pet task assignments (user's personalized tasks for their pets)
CREATE TABLE IF NOT EXISTS pet_task_assignments (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  task_id UUID REFERENCES tasks(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  custom_frequency_days INTEGER, -- Override default frequency (null = use task default)
  custom_name TEXT, -- Custom task name (null = use task default)
  custom_description TEXT, -- Custom description (null = use task default)
  notes TEXT, -- User notes for this task
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(pet_id, task_id) -- One assignment per pet-task combination
);

-- Function to automatically assign tasks when a pet is created
CREATE OR REPLACE FUNCTION assign_tasks_to_new_pet()
RETURNS TRIGGER AS $$ 
DECLARE 
  task_record RECORD;
  normalized_type TEXT;
BEGIN
  -- Normalize pet type (Turkish to English)
  normalized_type := CASE 
    WHEN NEW.type = 'Köpek' THEN 'dog'
    WHEN NEW.type = 'Kedi' THEN 'cat'
    WHEN NEW.type = 'Kuş' THEN 'bird'
    WHEN NEW.type = 'Hamster' THEN 'hamster'
    WHEN NEW.type = 'Tavşan' THEN 'rabbit'
    ELSE 'other'
  END;

  -- Assign tasks for this pet type and breed
  -- Tasks are assigned if:
  -- 1. Task matches pet type AND (breed is null OR breed matches pet breed)
  FOR task_record IN 
    SELECT id FROM tasks 
    WHERE pet_type = normalized_type 
    AND is_active = true
    AND (breed IS NULL OR breed = NEW.breed)
  LOOP
    INSERT INTO pet_task_assignments (pet_id, task_id, user_id)
    VALUES (NEW.id, task_record.id, NEW.owner_id)
    ON CONFLICT (pet_id, task_id) DO NOTHING;
  END LOOP;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to assign tasks when a pet is created
DROP TRIGGER IF EXISTS on_pet_created_assign_tasks ON pets;
CREATE TRIGGER on_pet_created_assign_tasks
  AFTER INSERT ON pets
  FOR EACH ROW
  EXECUTE FUNCTION assign_tasks_to_new_pet();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_pet_task_assignment_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS on_pet_task_assignment_updated ON pet_task_assignments;
CREATE TRIGGER on_pet_task_assignment_updated
  BEFORE UPDATE ON pet_task_assignments
  FOR EACH ROW
  EXECUTE FUNCTION update_pet_task_assignment_updated_at();

-- Grant access
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_task_assignments TO authenticated;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_pet_task_assignments_pet ON pet_task_assignments(pet_id, is_active);
CREATE INDEX IF NOT EXISTS idx_pet_task_assignments_user ON pet_task_assignments(user_id);
