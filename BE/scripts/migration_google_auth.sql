-- Migration: Add google_subject column for Google Sign-In
-- Run: psql -h localhost -U postgres -d vnmapdb -f scripts/migration_google_auth.sql
-- Or: docker exec -i vnmap_postgres psql -U postgres -d vnmapdb < scripts/migration_google_auth.sql

-- Add google_subject column to link app_users to Google accounts
ALTER TABLE app_users ADD COLUMN IF NOT EXISTS google_subject VARCHAR(255) UNIQUE;

-- Index for fast lookup during Google Sign-In verification
CREATE INDEX IF NOT EXISTS idx_app_users_google_subject ON app_users(google_subject);

-- Note: Existing users have google_subject = NULL (password-based login)
-- New Google-provisioned users will have google_subject populated
