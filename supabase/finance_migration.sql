-- Migration: Add finance management system for pets

-- Expense categories table
CREATE TABLE IF NOT EXISTS expense_categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  icon_name TEXT,
  color TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Expenses table
CREATE TABLE IF NOT EXISTS expenses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  category_id UUID REFERENCES expense_categories(id) ON DELETE SET NULL,
  amount NUMERIC(10, 2) NOT NULL,
  description TEXT,
  expense_date DATE NOT NULL,
  receipt_url TEXT,
  is_recurring BOOLEAN DEFAULT false,
  recurring_interval_days INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Expense reminders table
CREATE TABLE IF NOT EXISTS expense_reminders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  expense_id UUID REFERENCES expenses(id) ON DELETE SET NULL,
  reminder_type TEXT NOT NULL CHECK (reminder_type IN ('food_low', 'recurring_expense', 'custom')),
  title TEXT NOT NULL,
  message TEXT,
  reminder_date DATE NOT NULL,
  is_active BOOLEAN DEFAULT true,
  is_sent BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Pet food tracking table
CREATE TABLE IF NOT EXISTS pet_food_tracking (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  food_name TEXT NOT NULL,
  purchase_date DATE NOT NULL,
  estimated_days INTEGER NOT NULL,
  estimated_finish_date DATE NOT NULL,
  is_finished BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Insert default expense categories
INSERT INTO expense_categories (name, icon_name, color) VALUES
('Mama ve Beslenme', 'restaurant', '#FF6B6B'),
('Veteriner ve Sağlık', 'medical_services', '#4ECDC4'),
('Oyuncaklar', 'toys', '#FFE66D'),
('Aksesuarlar', 'shopping_bag', '#95E1D3'),
('Temizlik ve Bakım', 'cleaning_services', '#A8E6CF'),
('Sigorta', 'security', '#FFD3A5'),
('Diğer', 'more_horiz', '#C7CEEA')
ON CONFLICT DO NOTHING;

-- Function to update updated_at timestamp for expenses
CREATE OR REPLACE FUNCTION update_expense_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at for expenses
DROP TRIGGER IF EXISTS on_expense_updated ON expenses;
CREATE TRIGGER on_expense_updated
  BEFORE UPDATE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_expense_updated_at();

-- Function to update updated_at timestamp for pet_food_tracking
CREATE OR REPLACE FUNCTION update_food_tracking_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at for pet_food_tracking
DROP TRIGGER IF EXISTS on_food_tracking_updated ON pet_food_tracking;
CREATE TRIGGER on_food_tracking_updated
  BEFORE UPDATE ON pet_food_tracking
  FOR EACH ROW
  EXECUTE FUNCTION update_food_tracking_updated_at();

-- Function to create food reminder when food tracking is added
CREATE OR REPLACE FUNCTION create_food_reminder()
RETURNS TRIGGER AS $$
DECLARE
  reminder_date DATE;
BEGIN
  -- Create reminder 3 days before estimated finish date
  reminder_date := NEW.estimated_finish_date - INTERVAL '3 days';
  
  INSERT INTO expense_reminders (
    pet_id,
    user_id,
    reminder_type,
    title,
    message,
    reminder_date,
    is_active
  )
  VALUES (
    NEW.pet_id,
    NEW.user_id,
    'food_low',
    'Mama Bitmek Üzere',
    NEW.food_name || ' için mama bitmek üzere. Yeni mama almayı unutmayın!',
    reminder_date,
    true
  )
  ON CONFLICT DO NOTHING;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create food reminder
DROP TRIGGER IF EXISTS on_food_tracking_created ON pet_food_tracking;
CREATE TRIGGER on_food_tracking_created
  AFTER INSERT ON pet_food_tracking
  FOR EACH ROW
  EXECUTE FUNCTION create_food_reminder();

-- Function to create recurring expense reminder
CREATE OR REPLACE FUNCTION create_recurring_expense_reminder()
RETURNS TRIGGER AS $$
DECLARE
  next_reminder_date DATE;
BEGIN
  IF NEW.is_recurring = true AND NEW.recurring_interval_days IS NOT NULL THEN
    -- Create reminder 2 days before next occurrence
    next_reminder_date := NEW.expense_date + (NEW.recurring_interval_days || ' days')::INTERVAL - INTERVAL '2 days';
    
    INSERT INTO expense_reminders (
      pet_id,
      user_id,
      expense_id,
      reminder_type,
      title,
      message,
      reminder_date,
      is_active
    )
    VALUES (
      NEW.pet_id,
      NEW.user_id,
      NEW.id,
      'recurring_expense',
      'Tekrarlayan Harcama Hatırlatması',
      COALESCE(NEW.description, 'Tekrarlayan harcama') || ' için hatırlatma',
      next_reminder_date,
      true
    )
    ON CONFLICT DO NOTHING;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger to create recurring expense reminder
DROP TRIGGER IF EXISTS on_recurring_expense_created ON expenses;
CREATE TRIGGER on_recurring_expense_created
  AFTER INSERT ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION create_recurring_expense_reminder();

-- Enable Row Level Security (RLS)
ALTER TABLE expense_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_food_tracking ENABLE ROW LEVEL SECURITY;

-- RLS Policies for expense_categories (public read)
CREATE POLICY "Anyone can view expense categories" ON expense_categories FOR SELECT USING (true);

-- RLS Policies for expenses
CREATE POLICY "Users can view expenses for their pets" ON expenses FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM pets 
    WHERE pets.id = expenses.pet_id 
    AND (pets.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM pet_members 
      WHERE pet_members.pet_id = pets.id 
      AND pet_members.user_id = auth.uid()
    ))
  )
);

CREATE POLICY "Users can insert expenses for their pets" ON expenses FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM pets 
    WHERE pets.id = expenses.pet_id 
    AND (pets.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM pet_members 
      WHERE pet_members.pet_id = pets.id 
      AND pet_members.user_id = auth.uid()
      AND pet_members.role IN ('owner', 'editor')
    ))
  )
  AND expenses.user_id = auth.uid()
);

CREATE POLICY "Users can update expenses for their pets" ON expenses FOR UPDATE USING (
  EXISTS (
    SELECT 1 FROM pets 
    WHERE pets.id = expenses.pet_id 
    AND (pets.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM pet_members 
      WHERE pet_members.pet_id = pets.id 
      AND pet_members.user_id = auth.uid()
      AND pet_members.role IN ('owner', 'editor')
    ))
  )
  AND expenses.user_id = auth.uid()
);

CREATE POLICY "Users can delete expenses for their pets" ON expenses FOR DELETE USING (
  EXISTS (
    SELECT 1 FROM pets 
    WHERE pets.id = expenses.pet_id 
    AND (pets.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM pet_members 
      WHERE pet_members.pet_id = pets.id 
      AND pet_members.user_id = auth.uid()
      AND pet_members.role IN ('owner', 'editor')
    ))
  )
  AND expenses.user_id = auth.uid()
);

-- RLS Policies for expense_reminders
CREATE POLICY "Users can view their reminders" ON expense_reminders FOR SELECT USING (
  user_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM pets 
    WHERE pets.id = expense_reminders.pet_id 
    AND (pets.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM pet_members 
      WHERE pet_members.pet_id = pets.id 
      AND pet_members.user_id = auth.uid()
    ))
  )
);

CREATE POLICY "Users can insert their reminders" ON expense_reminders FOR INSERT WITH CHECK (
  user_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM pets 
    WHERE pets.id = expense_reminders.pet_id 
    AND (pets.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM pet_members 
      WHERE pet_members.pet_id = pets.id 
      AND pet_members.user_id = auth.uid()
      AND pet_members.role IN ('owner', 'editor')
    ))
  )
);

CREATE POLICY "Users can update their reminders" ON expense_reminders FOR UPDATE USING (
  user_id = auth.uid()
);

CREATE POLICY "Users can delete their reminders" ON expense_reminders FOR DELETE USING (
  user_id = auth.uid()
);

-- RLS Policies for pet_food_tracking
CREATE POLICY "Users can view food tracking for their pets" ON pet_food_tracking FOR SELECT USING (
  user_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM pets 
    WHERE pets.id = pet_food_tracking.pet_id 
    AND (pets.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM pet_members 
      WHERE pet_members.pet_id = pets.id 
      AND pet_members.user_id = auth.uid()
    ))
  )
);

CREATE POLICY "Users can insert food tracking for their pets" ON pet_food_tracking FOR INSERT WITH CHECK (
  user_id = auth.uid() AND
  EXISTS (
    SELECT 1 FROM pets 
    WHERE pets.id = pet_food_tracking.pet_id 
    AND (pets.owner_id = auth.uid() OR EXISTS (
      SELECT 1 FROM pet_members 
      WHERE pet_members.pet_id = pets.id 
      AND pet_members.user_id = auth.uid()
      AND pet_members.role IN ('owner', 'editor')
    ))
  )
);

CREATE POLICY "Users can update food tracking for their pets" ON pet_food_tracking FOR UPDATE USING (
  user_id = auth.uid()
);

CREATE POLICY "Users can delete food tracking for their pets" ON pet_food_tracking FOR DELETE USING (
  user_id = auth.uid()
);

-- Grant access
GRANT SELECT ON expense_categories TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON expenses TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON expense_reminders TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON pet_food_tracking TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_expenses_pet_date ON expenses(pet_id, expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);
CREATE INDEX IF NOT EXISTS idx_expense_reminders_user_active ON expense_reminders(user_id, is_active, reminder_date);
CREATE INDEX IF NOT EXISTS idx_expense_reminders_pet ON expense_reminders(pet_id);
CREATE INDEX IF NOT EXISTS idx_food_tracking_pet ON pet_food_tracking(pet_id, is_finished);
CREATE INDEX IF NOT EXISTS idx_food_tracking_user ON pet_food_tracking(user_id);
