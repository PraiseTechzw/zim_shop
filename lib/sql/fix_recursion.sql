-- IMMEDIATE FIX FOR RECURSION ISSUES
-- This completely removes and recreates the policies to stop the infinite recursion

-- First, drop ALL existing policies on users table
DROP POLICY IF EXISTS users_view_own ON users;
DROP POLICY IF EXISTS users_update_own ON users;
DROP POLICY IF EXISTS users_insert_own ON users;
DROP POLICY IF EXISTS admin_view_all ON users;
DROP POLICY IF EXISTS admin_modify_all ON users;
DROP POLICY IF EXISTS "Users can view their own data" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Allow insert during signup" ON users;

-- Temporarily disable RLS on users table to stop recursion
ALTER TABLE users DISABLE ROW LEVEL SECURITY;

-- Create minimal set of policies

-- 1. Create a simple policy for user selection (viewing)
CREATE POLICY users_select ON users
  FOR SELECT USING (true);
  
-- 2. Create a simple policy for user insertion during signup
CREATE POLICY users_insert ON users
  FOR INSERT WITH CHECK (true);
  
-- 3. Create a policy for users to update their own records
CREATE POLICY users_update ON users
  FOR UPDATE USING (auth.uid() = id);

-- Re-enable RLS on users table
ALTER TABLE users ENABLE ROW LEVEL SECURITY; 