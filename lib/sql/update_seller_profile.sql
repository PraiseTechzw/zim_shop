-- Drop the existing function first
DROP FUNCTION IF EXISTS public.update_seller_profile(UUID, TEXT, TEXT, TEXT, TEXT, TEXT);

-- Create a function to update seller profile that bypasses RLS
CREATE OR REPLACE FUNCTION public.update_seller_profile(
  p_seller_id UUID,
  p_phone_number TEXT DEFAULT NULL,
  p_whatsapp_number TEXT DEFAULT NULL,
  p_seller_bio TEXT DEFAULT NULL,
  p_business_name TEXT DEFAULT NULL,
  p_business_address TEXT DEFAULT NULL
) RETURNS BOOLEAN AS $$
BEGIN
  -- This function runs with SECURITY DEFINER privileges
  -- which means it executes with the privileges of the function creator (typically a superuser)
  -- This bypasses RLS completely
  
  -- Update the seller's profile in the users table
  UPDATE public.users
  SET 
    phone_number = COALESCE(p_phone_number, users.phone_number),
    whatsapp_number = COALESCE(p_whatsapp_number, users.whatsapp_number),
    seller_bio = COALESCE(p_seller_bio, users.seller_bio),
    business_name = COALESCE(p_business_name, users.business_name),
    business_address = COALESCE(p_business_address, users.business_address),
    updated_at = NOW()
  WHERE id = p_seller_id;
  
  RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER; 