CREATE TABLE IF NOT EXISTS report_exports (
  id BIGSERIAL PRIMARY KEY,
  created_by_user_id BIGINT NOT NULL REFERENCES app_users(id),
  report_type VARCHAR(50) NOT NULL,
  status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
  file_name VARCHAR(255),
  storage_path TEXT,
  filters_json TEXT NOT NULL,
  sections_json TEXT NOT NULL,
  error_message TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  completed_at TIMESTAMP
);
