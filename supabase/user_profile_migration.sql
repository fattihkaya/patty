-- Migration: Add user profile fields (first_name, last_name, username)
-- Ebeveyn bilgileri için profil alanları ekleme

-- Add new columns to profiles table
ALTER TABLE profiles 
  ADD COLUMN IF NOT EXISTS first_name TEXT,
  ADD COLUMN IF NOT EXISTS last_name TEXT,
  ADD COLUMN IF NOT EXISTS username TEXT UNIQUE;

-- Create index for username lookups
CREATE INDEX IF NOT EXISTS idx_profiles_username ON profiles(username) WHERE username IS NOT NULL;

-- Update RLS policies if needed (they should already allow users to update their own profile)
-- No changes needed as existing policies already allow users to update their own profile
