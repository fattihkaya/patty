-- Migration: Add vaccination records tracking

-- Vaccination records table (aşı kayıtları)
CREATE TABLE IF NOT EXISTS vaccination_records (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  vaccine_name TEXT NOT NULL, -- Aşı adı (örn: "İlk Karma Aşı (DHPPi)")
  vaccine_description TEXT, -- Aşı açıklaması
  recommended_age_days INTEGER, -- Önerilen yaş (gün)
  completed_at DATE NOT NULL, -- Yapıldığı tarih
  notes TEXT, -- Notlar (veteriner, parti no, vb.)
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  UNIQUE(pet_id, vaccine_name, completed_at) -- Aynı aşıyı aynı tarihte iki kez eklenmesin
);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_vaccination_record_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = timezone('utc'::text, now());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to update updated_at
DROP TRIGGER IF EXISTS on_vaccination_record_updated ON vaccination_records;
CREATE TRIGGER on_vaccination_record_updated
  BEFORE UPDATE ON vaccination_records
  FOR EACH ROW
  EXECUTE FUNCTION update_vaccination_record_updated_at();

-- Grant access
GRANT SELECT, INSERT, UPDATE, DELETE ON vaccination_records TO authenticated;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_vaccination_records_pet_id ON vaccination_records(pet_id);
CREATE INDEX IF NOT EXISTS idx_vaccination_records_user_id ON vaccination_records(user_id);
CREATE INDEX IF NOT EXISTS idx_vaccination_records_completed_at ON vaccination_records(completed_at);
