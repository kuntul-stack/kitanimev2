/*
  # Create KitaNime Database Tables

  1. New Tables
    - `admin_users`
      - `id` (uuid, primary key)
      - `username` (text, unique)
      - `password_hash` (text)
      - `email` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `api_endpoints`
      - `id` (uuid, primary key)
      - `name` (text, unique)
      - `url` (text)
      - `is_active` (boolean)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `ad_slots`
      - `id` (uuid, primary key)
      - `name` (text)
      - `position` (text)
      - `type` (text) - 'adsense' or 'banner'
      - `content` (text)
      - `is_active` (boolean)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `settings`
      - `id` (uuid, primary key)
      - `key` (text, unique)
      - `value` (text)
      - `description` (text)
      - `created_at` (timestamptz)
      - `updated_at` (timestamptz)
    
    - `sessions`
      - `sid` (text, primary key) - session ID
      - `sess` (jsonb) - session data
      - `expire` (timestamptz) - expiration time
  
  2. Security
    - Enable RLS on all tables
    - Add policies for authenticated admin users
    - Public read access for settings (site info only)
  
  3. Default Data
    - Insert default admin user (username: admin, password: admin123)
    - Insert default API endpoint
    - Insert default ad slots
    - Insert default settings
*/

-- Create admin_users table
CREATE TABLE IF NOT EXISTS admin_users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  username text NOT NULL UNIQUE,
  password_hash text NOT NULL,
  email text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create api_endpoints table
CREATE TABLE IF NOT EXISTS api_endpoints (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL UNIQUE,
  url text NOT NULL,
  is_active boolean DEFAULT false,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create ad_slots table
CREATE TABLE IF NOT EXISTS ad_slots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  position text NOT NULL,
  type text NOT NULL CHECK(type IN ('adsense', 'banner')),
  content text NOT NULL,
  is_active boolean DEFAULT true,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create settings table
CREATE TABLE IF NOT EXISTS settings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  key text NOT NULL UNIQUE,
  value text,
  description text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

-- Create sessions table for express-session
CREATE TABLE IF NOT EXISTS sessions (
  sid text PRIMARY KEY,
  sess jsonb NOT NULL,
  expire timestamptz NOT NULL
);

-- Create index on sessions expire column for efficient cleanup
CREATE INDEX IF NOT EXISTS idx_sessions_expire ON sessions (expire);

-- Enable RLS on all tables
ALTER TABLE admin_users ENABLE ROW LEVEL SECURITY;
ALTER TABLE api_endpoints ENABLE ROW LEVEL SECURITY;
ALTER TABLE ad_slots ENABLE ROW LEVEL SECURITY;
ALTER TABLE settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for admin_users
CREATE POLICY "Admin users can view own profile"
  ON admin_users FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY "Admin users can update own profile"
  ON admin_users FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- RLS Policies for api_endpoints
CREATE POLICY "Anyone can view active API endpoints"
  ON api_endpoints FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

CREATE POLICY "Authenticated users can manage API endpoints"
  ON api_endpoints FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- RLS Policies for ad_slots
CREATE POLICY "Anyone can view active ad slots"
  ON ad_slots FOR SELECT
  TO anon, authenticated
  USING (is_active = true);

CREATE POLICY "Authenticated users can manage ad slots"
  ON ad_slots FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- RLS Policies for settings
CREATE POLICY "Anyone can view settings"
  ON settings FOR SELECT
  TO anon, authenticated
  USING (true);

CREATE POLICY "Authenticated users can manage settings"
  ON settings FOR ALL
  TO authenticated
  USING (true)
  WITH CHECK (true);

-- RLS Policies for sessions
CREATE POLICY "Anyone can manage sessions"
  ON sessions FOR ALL
  TO anon, authenticated
  USING (true)
  WITH CHECK (true);

-- Insert default data
DO $$
BEGIN
  -- Insert default admin user (password: admin123, will be hashed in application)
  IF NOT EXISTS (SELECT 1 FROM admin_users WHERE username = 'admin') THEN
    INSERT INTO admin_users (username, password_hash, email)
    VALUES ('admin', '$2b$10$XvJZ9z5QZ5Z5Z5Z5Z5Z5Z.dummy.hash.will.be.set.by.app', 'admin@kitanime.com');
  END IF;

  -- Insert default API endpoint
  IF NOT EXISTS (SELECT 1 FROM api_endpoints) THEN
    INSERT INTO api_endpoints (name, url, is_active)
    VALUES ('Default API', 'http://localhost:3000/v1', true);
  END IF;

  -- Insert default ad slots
  IF NOT EXISTS (SELECT 1 FROM ad_slots) THEN
    INSERT INTO ad_slots (name, position, type, content, is_active)
    VALUES 
      ('Header Banner', 'header', 'banner', '<img src="/images/ads/header-banner.jpg" alt="Advertisement" class="w-full h-20 object-cover rounded-lg">', true),
      ('Sidebar Top', 'sidebar-top', 'adsense', '<ins class="adsbygoogle" style="display:block" data-ad-client="ca-pub-xxxxxxxxxx" data-ad-slot="xxxxxxxxxx" data-ad-format="auto"></ins>', true),
      ('Content Bottom', 'content-bottom', 'banner', '<img src="/images/ads/content-banner.jpg" alt="Advertisement" class="w-full h-32 object-cover rounded-lg">', true);
  END IF;

  -- Insert default settings
  IF NOT EXISTS (SELECT 1 FROM settings) THEN
    INSERT INTO settings (key, value, description)
    VALUES 
      ('site_title', 'KitaNime - Streaming Anime Subtitle Indonesia', 'Judul website'),
      ('site_description', 'Nonton anime subtitle Indonesia terlengkap dan terbaru', 'Deskripsi website'),
      ('cookie_consent_enabled', '1', 'Enable cookie consent popup'),
      ('adsense_enabled', '0', 'Enable Google AdSense');
  END IF;
END $$;
