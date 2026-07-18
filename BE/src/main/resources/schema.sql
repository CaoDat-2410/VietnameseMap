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

-- Staff check-in / check-out (attendance) tracking.
-- STAFF/MANAGER self-service check-in & check-out; MANAGER manages (edit/delete)
-- any employee's records; ADMIN has read-only visibility (enforced in SecurityConfig).
CREATE TABLE IF NOT EXISTS staff_attendance (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    campaign_id BIGINT REFERENCES campaigns(id) ON DELETE CASCADE,
    event_id BIGINT REFERENCES campaign_events(id) ON DELETE SET NULL,
    check_in_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out_at TIMESTAMP,
    check_in_note VARCHAR(500),
    check_out_note VARCHAR(500),
    check_in_lat DOUBLE PRECISION,
    check_in_lng DOUBLE PRECISION,
    check_out_lat DOUBLE PRECISION,
    check_out_lng DOUBLE PRECISION,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Backfills columns for tables created before campaign linkage was added.
ALTER TABLE staff_attendance
    ADD COLUMN IF NOT EXISTS campaign_id BIGINT REFERENCES campaigns(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS event_id BIGINT REFERENCES campaign_events(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_staff_attendance_employee ON staff_attendance(employee_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_checkin ON staff_attendance(check_in_at);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_campaign ON staff_attendance(campaign_id);

-- Prevents an employee from having more than one open (not-yet-checked-out) session.
CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_attendance_open_unique
    ON staff_attendance(employee_id) WHERE status = 'OPEN';
