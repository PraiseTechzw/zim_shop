"-- SQL to run in Supabase SQL Editor to identify all policies on the users table:"  
"SELECT schemaname, tablename, policyname, cmd, qual, with_check FROM pg_policies WHERE tablename = 'users' OR qual::text LIKE '%%users%%';" 
