-- Expenses tablosunu ve gerekli yapıları oluştur

-- 1. Expenses tablosu oluştur
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

-- 2. RLS etkinleştir
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies
-- Kullanıcılar kendi pet'lerinin harcamalarını görebilir
DROP POLICY IF EXISTS "Users can view expenses for their pets" ON expenses;
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

-- Kullanıcılar kendi pet'lerine harcama ekleyebilir
DROP POLICY IF EXISTS "Users can insert expenses for their pets" ON expenses;
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

-- Kullanıcılar kendi harcamalarını güncelleyebilir
DROP POLICY IF EXISTS "Users can update expenses for their pets" ON expenses;
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

-- Kullanıcılar kendi harcamalarını silebilir
DROP POLICY IF EXISTS "Users can delete expenses for their pets" ON expenses;
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

-- 4. Yetkiler
GRANT SELECT, INSERT, UPDATE, DELETE ON expenses TO authenticated;

-- 5. İndeksler (performans için)
CREATE INDEX IF NOT EXISTS idx_expenses_pet_date ON expenses(pet_id, expense_date DESC);
CREATE INDEX IF NOT EXISTS idx_expenses_user ON expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON expenses(category_id);

-- 6. updated_at için trigger
CREATE OR REPLACE FUNCTION update_expense_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_expense_updated ON expenses;
CREATE TRIGGER on_expense_updated
  BEFORE UPDATE ON expenses
  FOR EACH ROW
  EXECUTE FUNCTION update_expense_updated_at();
