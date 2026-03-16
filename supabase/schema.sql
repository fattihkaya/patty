-- Profiles table to store user data
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Pets table to store pet information
CREATE TABLE pets (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  owner_id UUID REFERENCES profiles(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  breed TEXT,
  birth_date DATE,
  photo_url TEXT,
  -- optional shared ownership note
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Daily logs table for timeline photos and AI comments
CREATE TABLE daily_logs (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  photo_url TEXT NOT NULL,
  ai_comment TEXT,
  health_note TEXT,
  ai_conditions JSONB DEFAULT '[]'::jsonb,
  confirmed_conditions JSONB DEFAULT '[]'::jsonb,
  visibility TEXT DEFAULT 'members' CHECK (visibility IN ('private', 'members', 'followers', 'public')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Pet membership (multi-owner / family)
CREATE TABLE pet_members (
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  role TEXT DEFAULT 'viewer' CHECK (role IN ('owner','editor','viewer')),
  added_by UUID REFERENCES profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (pet_id, user_id)
);

-- Likes on logs
CREATE TABLE log_likes (
  log_id UUID REFERENCES daily_logs(id) ON DELETE CASCADE,
  user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  PRIMARY KEY (log_id, user_id)
);

CREATE TABLE pet_conditions (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  pet_id UUID REFERENCES pets(id) ON DELETE CASCADE NOT NULL,
  source_log_id UUID REFERENCES daily_logs(id) ON DELETE SET NULL,
  label TEXT NOT NULL,
  category TEXT,
  status TEXT DEFAULT 'confirmed',
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now())
);

-- Enable Row Level Security (RLS)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE pets ENABLE ROW LEVEL SECURITY;
ALTER TABLE daily_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE pet_conditions ENABLE ROW LEVEL SECURITY;

-- Profiles Policies
CREATE POLICY "Users can view their own profile." ON profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile." ON profiles FOR UPDATE USING (auth.uid() = id);

-- Pets Policies
CREATE POLICY "Users can view their own pets." ON pets FOR SELECT USING (auth.uid() = owner_id);
CREATE POLICY "Users can insert their own pets." ON pets FOR INSERT WITH CHECK (auth.uid() = owner_id);
CREATE POLICY "Users can update their own pets." ON pets FOR UPDATE USING (auth.uid() = owner_id);
CREATE POLICY "Users can delete their own pets." ON pets FOR DELETE USING (auth.uid() = owner_id);

-- Daily Logs Policies
CREATE POLICY "Users can view logs for their pets." ON daily_logs FOR SELECT USING (
  EXISTS (SELECT 1 FROM pets WHERE pets.id = daily_logs.pet_id AND pets.owner_id = auth.uid())
);
CREATE POLICY "Users can insert logs for their pets." ON daily_logs FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM pets WHERE pets.id = daily_logs.pet_id AND pets.owner_id = auth.uid())
);

-- Pet Conditions Policies
CREATE POLICY "Users can view their pet conditions." ON pet_conditions FOR SELECT USING (
  EXISTS (SELECT 1 FROM pets WHERE pets.id = pet_conditions.pet_id AND pets.owner_id = auth.uid())
);
CREATE POLICY "Users can insert pet conditions." ON pet_conditions FOR INSERT WITH CHECK (
  EXISTS (SELECT 1 FROM pets WHERE pets.id = pet_conditions.pet_id AND pets.owner_id = auth.uid())
);
CREATE POLICY "Users can update their pet conditions." ON pet_conditions FOR UPDATE USING (
  EXISTS (SELECT 1 FROM pets WHERE pets.id = pet_conditions.pet_id AND pets.owner_id = auth.uid())
);
CREATE POLICY "Users can delete their pet conditions." ON pet_conditions FOR DELETE USING (
  EXISTS (SELECT 1 FROM pets WHERE pets.id = pet_conditions.pet_id AND pets.owner_id = auth.uid())
);

-- Trigger to create profile on signup
CREATE OR REPLACE FUNCTION public.handle_new_user() 
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email)
  VALUES (new.id, new.email);
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- STORAGE POLICIES
-- Note: Make sure you have created the 'pets_bucket' in the Supabase Dashboard first.

-- Allow public access to read files (or restrict to authenticated if preferred)
CREATE POLICY "Public Access" ON storage.objects FOR SELECT USING (bucket_id = 'pets_bucket');

-- Allow authenticated users to upload files to their own folders
CREATE POLICY "Allow Authenticated Upload" ON storage.objects FOR INSERT WITH CHECK (
  bucket_id = 'pets_bucket' AND auth.role() = 'authenticated'
);

-- Allow users to delete their own files
CREATE POLICY "Allow Individual Delete" ON storage.objects FOR DELETE USING (
  bucket_id = 'pets_bucket' AND auth.uid() = owner
);
