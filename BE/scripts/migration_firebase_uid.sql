ALTER TABLE app_users ADD COLUMN IF NOT EXISTS firebase_uid VARCHAR(255);
CREATE UNIQUE INDEX IF NOT EXISTS idx_app_users_firebase_uid
ON app_users(firebase_uid)
WHERE firebase_uid IS NOT NULL;
