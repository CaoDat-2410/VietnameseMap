-- Staff check-in / check-out (attendance) tracking.
-- STAFF/MANAGER self-service check-in & check-out; MANAGER manages (edit/delete)
-- any employee's records; ADMIN has the same attendance oversight permissions.
CREATE TABLE IF NOT EXISTS staff_attendance (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE RESTRICT,
    campaign_id BIGINT REFERENCES campaigns(id) ON DELETE SET NULL,
    event_id BIGINT REFERENCES campaign_events(id) ON DELETE SET NULL,
    check_in_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    check_out_at TIMESTAMPTZ,
    check_in_note VARCHAR(500),
    check_out_note VARCHAR(500),
    check_in_lat DOUBLE PRECISION,
    check_in_lng DOUBLE PRECISION,
    check_out_lat DOUBLE PRECISION,
    check_out_lng DOUBLE PRECISION,
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'CLOSED')),
    check_in_request_id VARCHAR(100),
    check_out_request_id VARCHAR(100),
    updated_by_user_id BIGINT REFERENCES app_users(id) ON DELETE SET NULL,
    deleted_at TIMESTAMPTZ,
    deleted_by_user_id BIGINT REFERENCES app_users(id) ON DELETE SET NULL,
    delete_reason VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Backfills columns for tables created before campaign linkage was added.
ALTER TABLE staff_attendance
    ADD COLUMN IF NOT EXISTS campaign_id BIGINT REFERENCES campaigns(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS event_id BIGINT REFERENCES campaign_events(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS check_in_request_id VARCHAR(100),
    ADD COLUMN IF NOT EXISTS check_out_request_id VARCHAR(100),
    ADD COLUMN IF NOT EXISTS updated_by_user_id BIGINT REFERENCES app_users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS deleted_by_user_id BIGINT REFERENCES app_users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS delete_reason VARCHAR(500);

CREATE INDEX IF NOT EXISTS idx_staff_attendance_employee ON staff_attendance(employee_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_checkin ON staff_attendance(check_in_at);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_campaign ON staff_attendance(campaign_id);

-- Prevents an employee from having more than one open (not-yet-checked-out) session.
CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_attendance_open_unique
    ON staff_attendance(employee_id) WHERE status = 'OPEN';

-- Attendance production hardening for existing databases.
-- The connection timezone preserves historical local timestamps during the
-- one-time timestamp -> timestamptz conversion and is harmless on later runs.
SET TIME ZONE 'Asia/Ho_Chi_Minh';
ALTER TABLE staff_attendance
    ALTER COLUMN check_in_at TYPE TIMESTAMPTZ USING check_in_at,
    ALTER COLUMN check_out_at TYPE TIMESTAMPTZ USING check_out_at,
    ALTER COLUMN created_at TYPE TIMESTAMPTZ USING created_at,
    ALTER COLUMN updated_at TYPE TIMESTAMPTZ USING updated_at;

ALTER TABLE staff_attendance
    DROP CONSTRAINT IF EXISTS staff_attendance_employee_id_fkey;
ALTER TABLE staff_attendance
    ADD CONSTRAINT staff_attendance_employee_id_fkey
    FOREIGN KEY (employee_id) REFERENCES employees(id) ON DELETE RESTRICT;
ALTER TABLE staff_attendance
    DROP CONSTRAINT IF EXISTS staff_attendance_campaign_id_fkey;
ALTER TABLE staff_attendance
    ADD CONSTRAINT staff_attendance_campaign_id_fkey
    FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE SET NULL;

ALTER TABLE staff_attendance
    DROP CONSTRAINT IF EXISTS chk_staff_attendance_time_order;
ALTER TABLE staff_attendance
    ADD CONSTRAINT chk_staff_attendance_time_order
    CHECK (check_out_at IS NULL OR check_out_at >= check_in_at);
ALTER TABLE staff_attendance
    DROP CONSTRAINT IF EXISTS chk_staff_attendance_status_time;
ALTER TABLE staff_attendance
    ADD CONSTRAINT chk_staff_attendance_status_time
    CHECK ((status = 'OPEN' AND check_out_at IS NULL)
        OR (status = 'CLOSED' AND check_out_at IS NOT NULL));
ALTER TABLE staff_attendance
    DROP CONSTRAINT IF EXISTS chk_staff_attendance_gps;
ALTER TABLE staff_attendance
    ADD CONSTRAINT chk_staff_attendance_gps CHECK (
        (check_in_lat IS NULL) = (check_in_lng IS NULL)
        AND (check_out_lat IS NULL) = (check_out_lng IS NULL)
        AND (check_in_lat IS NULL OR check_in_lat BETWEEN -90 AND 90)
        AND (check_in_lng IS NULL OR check_in_lng BETWEEN -180 AND 180)
        AND (check_out_lat IS NULL OR check_out_lat BETWEEN -90 AND 90)
        AND (check_out_lng IS NULL OR check_out_lng BETWEEN -180 AND 180)
    );

CREATE UNIQUE INDEX IF NOT EXISTS uq_campaign_events_id_campaign
    ON campaign_events(id, campaign_id);

ALTER TABLE staff_attendance
    DROP CONSTRAINT IF EXISTS fk_staff_attendance_event_campaign;
ALTER TABLE staff_attendance
    ADD CONSTRAINT fk_staff_attendance_event_campaign
    FOREIGN KEY (event_id, campaign_id)
    REFERENCES campaign_events(id, campaign_id);

CREATE TABLE IF NOT EXISTS staff_attendance_audit (
    id BIGSERIAL PRIMARY KEY,
    attendance_id BIGINT NOT NULL REFERENCES staff_attendance(id) ON DELETE RESTRICT,
    action VARCHAR(20) NOT NULL CHECK (action IN ('CREATE', 'UPDATE', 'DELETE')),
    actor_user_id BIGINT REFERENCES app_users(id) ON DELETE SET NULL,
    reason VARCHAR(500) NOT NULL,
    before_data JSONB,
    after_data JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_staff_attendance_audit_record
    ON staff_attendance_audit(attendance_id, created_at DESC);

DROP INDEX IF EXISTS idx_staff_attendance_open_unique;
CREATE UNIQUE INDEX idx_staff_attendance_open_unique
    ON staff_attendance(employee_id) WHERE status = 'OPEN' AND deleted_at IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_attendance_checkin_request_unique
    ON staff_attendance(employee_id, check_in_request_id)
    WHERE check_in_request_id IS NOT NULL;
CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_attendance_checkout_request_unique
    ON staff_attendance(employee_id, check_out_request_id)
    WHERE check_out_request_id IS NOT NULL;
