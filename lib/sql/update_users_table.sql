-- Add additional seller fields to users table
ALTER TABLE IF EXISTS users 
ADD COLUMN IF NOT EXISTS phone_number TEXT,
ADD COLUMN IF NOT EXISTS whatsapp_number TEXT,
ADD COLUMN IF NOT EXISTS seller_bio TEXT,
ADD COLUMN IF NOT EXISTS seller_rating REAL DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS business_name TEXT,
ADD COLUMN IF NOT EXISTS business_address TEXT,
ADD COLUMN IF NOT EXISTS verification_documents JSONB DEFAULT '[]'::jsonb;

-- Create seller profiles view for easier queries
CREATE OR REPLACE VIEW seller_profiles AS
SELECT 
  id,
  username,
  email,
  phone_number,
  whatsapp_number,
  seller_bio,
  seller_rating,
  business_name,
  business_address,
  is_approved,
  verification_documents
FROM 
  users
WHERE 
  role = 'seller';

-- Update Row Level Security to include new fields
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Policy for users to view their own data
CREATE POLICY users_view_own ON users
  FOR SELECT
  USING (auth.uid() = id);

-- Policy for users to update their own data
CREATE POLICY users_update_own ON users
  FOR UPDATE
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- Policy for admin to view all data
CREATE POLICY admin_view_all ON users
  FOR SELECT
  USING (
    auth.uid() IN (
      SELECT id FROM users WHERE role = 'admin'
    )
  );

-- Policy for admin to modify all data
CREATE POLICY admin_modify_all ON users
  FOR ALL
  USING (
    auth.uid() IN (
      SELECT id FROM users WHERE role = 'admin'
    )
  ); 