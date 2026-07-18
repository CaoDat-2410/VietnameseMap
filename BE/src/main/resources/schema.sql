CREATE TABLE IF NOT EXISTS fcm_tokens (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
  token TEXT NOT NULL UNIQUE,
  platform VARCHAR(30) NOT NULL,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_fcm_tokens_user_id ON fcm_tokens(user_id);

CREATE TABLE IF NOT EXISTS notification_audit (
  id BIGSERIAL PRIMARY KEY,
  target_user_id BIGINT REFERENCES app_users(id) ON DELETE CASCADE,
  trigger_type VARCHAR(80),
  title VARCHAR(255) NOT NULL,
  body TEXT NOT NULL,
  data_json TEXT,
  fcm_result TEXT,
  status VARCHAR(30) NOT NULL,
  read_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_notification_audit_target_created
  ON notification_audit(target_user_id, created_at DESC);
