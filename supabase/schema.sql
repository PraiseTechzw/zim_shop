-- Begin transaction for atomic execution
BEGIN;

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Drop existing types if they exist to prevent conflicts
DROP TYPE IF EXISTS user_role CASCADE;
DROP TYPE IF EXISTS order_status CASCADE;

-- Create custom types
CREATE TYPE user_role AS ENUM ('buyer', 'seller', 'admin');
CREATE TYPE order_status AS ENUM ('pending', 'processing', 'shipped', 'delivered', 'cancelled');

-- Create schemas
CREATE SCHEMA IF NOT EXISTS public;

-- Drop existing tables if they exist to prevent conflicts
DROP TABLE IF EXISTS public.order_items CASCADE;
DROP TABLE IF EXISTS public.orders CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;
DROP TABLE IF EXISTS public.admin_settings CASCADE;

-- Create users table
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    username TEXT NOT NULL,
    role user_role NOT NULL DEFAULT 'buyer',
    is_approved BOOLEAN NOT NULL DEFAULT false,
    phone_number TEXT,
    whatsapp_number TEXT,
    seller_bio TEXT,
    seller_rating DECIMAL(3,2) CHECK (seller_rating >= 0 AND seller_rating <= 5),
    business_name TEXT,
    business_address TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create function to handle user creation and retrieval
CREATE OR REPLACE FUNCTION public.handle_user_creation()
RETURNS TRIGGER AS $$
BEGIN
    -- Set default values for new users
    IF NEW.role = 'buyer' THEN
        NEW.is_approved := true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for user creation
CREATE TRIGGER on_user_creation
    BEFORE INSERT ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_user_creation();

-- Create function to get user details
CREATE OR REPLACE FUNCTION public.get_user_details(user_id UUID)
RETURNS SETOF public.users AS $$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.users
    WHERE id = user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create products table (removed the valid_seller constraint, will add as trigger)
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    image_url TEXT,
    category TEXT,
    location TEXT,
    seller_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create orders table
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
    total_amount DECIMAL(10,2) NOT NULL CHECK (total_amount >= 0),
    status order_status NOT NULL DEFAULT 'pending',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create order_items table (removed the valid_order_item constraint, will add as trigger)
CREATE TABLE IF NOT EXISTS public.order_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    order_id UUID NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
    product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Drop existing functions if they exist
DROP FUNCTION IF EXISTS public.handle_updated_at() CASCADE;
DROP FUNCTION IF EXISTS public.check_valid_seller() CASCADE;
DROP FUNCTION IF EXISTS public.check_valid_order_item() CASCADE;

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create valid_seller check function
CREATE OR REPLACE FUNCTION public.check_valid_seller()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.users 
        WHERE id = NEW.seller_id AND role = 'seller'
    ) THEN
        RAISE EXCEPTION 'Invalid seller: User with ID % is not a seller', NEW.seller_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create valid_order_item check function
CREATE OR REPLACE FUNCTION public.check_valid_order_item()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM public.orders o
        WHERE o.id = NEW.order_id AND o.user_id IS NOT NULL
    ) THEN
        RAISE EXCEPTION 'Invalid order item: Order with ID % does not exist or has no user', NEW.order_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER set_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_products_updated_at
    BEFORE UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

CREATE TRIGGER set_orders_updated_at
    BEFORE UPDATE ON public.orders
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_updated_at();

-- Create triggers for valid_seller and valid_order_item
CREATE TRIGGER check_valid_seller_trigger
    BEFORE INSERT OR UPDATE ON public.products
    FOR EACH ROW
    EXECUTE FUNCTION public.check_valid_seller();

CREATE TRIGGER check_valid_order_item_trigger
    BEFORE INSERT OR UPDATE ON public.order_items
    FOR EACH ROW
    EXECUTE FUNCTION public.check_valid_order_item();

-- Drop existing function if it exists
DROP FUNCTION IF EXISTS public.update_seller_profile CASCADE;

-- Create function to update seller profile
CREATE OR REPLACE FUNCTION public.update_seller_profile(
    p_seller_id UUID,
    p_phone_number TEXT,
    p_whatsapp_number TEXT,
    p_seller_bio TEXT,
    p_business_name TEXT,
    p_business_address TEXT
)
RETURNS BOOLEAN AS $$
DECLARE
    v_is_seller BOOLEAN;
BEGIN
    -- Check if user is a seller
    SELECT EXISTS (
        SELECT 1 FROM public.users
        WHERE id = p_seller_id AND role = 'seller'
    ) INTO v_is_seller;

    IF NOT v_is_seller THEN
        RETURN FALSE;
    END IF;

    -- Update seller profile
    UPDATE public.users
    SET
        phone_number = COALESCE(p_phone_number, phone_number),
        whatsapp_number = COALESCE(p_whatsapp_number, whatsapp_number),
        seller_bio = COALESCE(p_seller_bio, seller_bio),
        business_name = COALESCE(p_business_name, business_name),
        business_address = COALESCE(p_business_address, business_address),
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_seller_id;
    
    RETURN FOUND;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Enable Row Level Security
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.order_items ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own profile" ON public.users;
DROP POLICY IF EXISTS "Users can update their own profile" ON public.users;
DROP POLICY IF EXISTS "Admins can view all users" ON public.users;
DROP POLICY IF EXISTS "Service role can manage users" ON public.users;
DROP POLICY IF EXISTS "Anyone can view products" ON public.products;
DROP POLICY IF EXISTS "Sellers can create their own products" ON public.products;
DROP POLICY IF EXISTS "Sellers can update their own products" ON public.products;
DROP POLICY IF EXISTS "Sellers can delete their own products" ON public.products;
DROP POLICY IF EXISTS "Users can view their own orders" ON public.orders;
DROP POLICY IF EXISTS "Users can create their own orders" ON public.orders;
DROP POLICY IF EXISTS "Sellers can view orders containing their products" ON public.orders;
DROP POLICY IF EXISTS "Users can view their own order items" ON public.order_items;
DROP POLICY IF EXISTS "Users can create their own order items" ON public.order_items;

-- Create policies with simplified conditions to avoid recursion
CREATE POLICY "Users can view their own profile"
    ON public.users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile"
    ON public.users FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Admins can view all users"
    ON public.users FOR SELECT
    USING (
        auth.jwt() ->> 'role' = 'admin'
    );

-- Add policy for service role
CREATE POLICY "Service role can manage users"
    ON public.users
    USING (auth.role() = 'service_role')
    WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Anyone can view products"
    ON public.products FOR SELECT
    USING (true);

CREATE POLICY "Sellers can create their own products"
    ON public.products FOR INSERT
    WITH CHECK (
        auth.uid() = seller_id AND
        auth.jwt() ->> 'role' = 'seller'
    );

CREATE POLICY "Sellers can update their own products"
    ON public.products FOR UPDATE
    USING (
        auth.uid() = seller_id AND
        auth.jwt() ->> 'role' = 'seller'
    );

CREATE POLICY "Sellers can delete their own products"
    ON public.products FOR DELETE
    USING (
        auth.uid() = seller_id AND
        auth.jwt() ->> 'role' = 'seller'
    );

CREATE POLICY "Users can view their own orders"
    ON public.orders FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own orders"
    ON public.orders FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Sellers can view orders containing their products"
    ON public.orders FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.order_items oi
            JOIN public.products p ON p.id = oi.product_id
            WHERE oi.order_id = orders.id AND p.seller_id = auth.uid()
        )
    );

CREATE POLICY "Users can view their own order items"
    ON public.order_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE id = order_id AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create their own order items"
    ON public.order_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.orders
            WHERE id = order_id AND user_id = auth.uid()
        )
    );

-- Create storage bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('products', 'products', true)
ON CONFLICT (id) DO NOTHING;

-- Drop existing storage policies if they exist
DROP POLICY IF EXISTS "Public Access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload product images" ON storage.objects;
DROP POLICY IF EXISTS "Sellers can delete their own product images" ON storage.objects;

-- Create storage policies
CREATE POLICY "Public Access"
    ON storage.objects FOR SELECT
    USING (bucket_id = 'products');

CREATE POLICY "Authenticated users can upload product images"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id = 'products' AND
        auth.role() = 'authenticated' AND
        auth.jwt() ->> 'role' = 'seller'
    );

CREATE POLICY "Sellers can delete their own product images"
    ON storage.objects FOR DELETE
    USING (
        bucket_id = 'products' AND
        auth.role() = 'authenticated' AND
        auth.jwt() ->> 'role' = 'seller'
    );

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_seller_id ON public.products(seller_id);
CREATE INDEX IF NOT EXISTS idx_orders_user_id ON public.orders(user_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON public.order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product_id ON public.order_items(product_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_role ON public.users(role);

-- Create function to check if a user is a seller
CREATE OR REPLACE FUNCTION public.is_seller(user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id = user_id AND role = 'seller' AND is_approved = true
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create admin_settings table
CREATE TABLE IF NOT EXISTS public.admin_settings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    auto_approve_sellers BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Insert default settings
INSERT INTO public.admin_settings (auto_approve_sellers)
VALUES (false)
ON CONFLICT (id) DO NOTHING;

-- Create function to update timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger for admin_settings
CREATE TRIGGER update_admin_settings_updated_at
    BEFORE UPDATE ON public.admin_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- Commit the transaction
COMMIT;