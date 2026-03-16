-- Migration: Add breed column to tasks table for breed-specific tasks

-- Add breed column to tasks table (nullable - null means task applies to all breeds)
ALTER TABLE tasks ADD COLUMN IF NOT EXISTS breed TEXT;

-- Create index for better query performance
CREATE INDEX IF NOT EXISTS idx_tasks_pet_type_breed ON tasks(pet_type, breed) WHERE breed IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_tasks_pet_type ON tasks(pet_type) WHERE breed IS NULL;
