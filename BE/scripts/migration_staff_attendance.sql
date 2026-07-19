-- Staff check-in / check-out (attendance) tracking, tied to a campaign (and
-- optionally a specific campaign event). STAFF/MANAGER self-service check-in
-- & check-out; MANAGER and ADMIN both manage (edit/delete) any employee's
-- records (enforced in SecurityConfig).
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

ALTER TABLE staff_attendance
    ADD COLUMN IF NOT EXISTS campaign_id BIGINT REFERENCES campaigns(id) ON DELETE CASCADE,
    ADD COLUMN IF NOT EXISTS event_id BIGINT REFERENCES campaign_events(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_staff_attendance_employee ON staff_attendance(employee_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_checkin ON staff_attendance(check_in_at);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_campaign ON staff_attendance(campaign_id);

-- Prevents an employee from having more than one open (not-yet-checked-out) session.
CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_attendance_open_unique
    ON staff_attendance(employee_id) WHERE status = 'OPEN';
