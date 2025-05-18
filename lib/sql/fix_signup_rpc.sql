-- Create a PostgreSQL function to handle user creation that bypasses RLS
-- This is a better approach than trying to configure complex RLS policies

CREATE OR REPLACE FUNCTION public.insert_new_user(
  user_id UUID,
  user_email TEXT,
  user_name TEXT,
  user_role TEXT,
  is_user_approved BOOLEAN
) RETURNS VOID AS $$
BEGIN
  -- This function runs with SECURITY DEFINER privileges
  -- which means it executes with the privileges of the function creator (typically a superuser)
  -- This bypasses RLS completely
  
  -- Insert directly into the users table
  INSERT INTO public.users (id, email, username, role, is_approved)
  VALUES (user_id, user_email, user_name, user_role, is_user_approved)
  ON CONFLICT (id) DO UPDATE SET
    email = user_email,
    username = user_name,
    role = user_role,
    is_approved = is_user_approved;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 