-- Add avatar_object_key column to app_users for the user profile feature.
ALTER TABLE app_users
    ADD COLUMN IF NOT EXISTS avatar_object_key VARCHAR(255);

COMMENT ON COLUMN app_users.avatar_object_key IS
    'Object key in the campaign bucket (MinIO/S3) for the user avatar; null = use initials fallback.';