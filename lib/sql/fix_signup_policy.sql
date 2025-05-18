-- Fix for signup RLS policy issue without causing recursion

-- APPROACH 1: User-specific policy
-- Drop the policy if it exists to avoid conflicts
DROP POLICY IF EXISTS users_insert_own ON users;

-- Create a more specific policy for signup
CREATE POLICY users_insert_own ON users
  FOR INSERT
  WITH CHECK (auth.uid() = id);

-- ALTERNATIVE APPROACH IF RECURSION PERSISTS:
-- You can temporarily disable RLS during the signup process with:
-- ALTER TABLE users DISABLE ROW LEVEL SECURITY;
-- Then re-enable it after testing that signup works:
-- ALTER TABLE users ENABLE ROW LEVEL SECURITY; 