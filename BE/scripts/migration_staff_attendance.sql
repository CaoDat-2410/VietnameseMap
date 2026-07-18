-- Staff check-in / check-out (attendance) tracking.
-- STAFF/MANAGER self-service check-in & check-out; MANAGER manages (edit/delete)
-- any employee's records; ADMIN has read-only visibility (enforced in SecurityConfig).
CREATE TABLE IF NOT EXISTS staff_attendance (
    id BIGSERIAL PRIMARY KEY,
    employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
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

CREATE INDEX IF NOT EXISTS idx_staff_attendance_employee ON staff_attendance(employee_id);
CREATE INDEX IF NOT EXISTS idx_staff_attendance_checkin ON staff_attendance(check_in_at);

-- Prevents an employee from having more than one open (not-yet-checked-out) session.
CREATE UNIQUE INDEX IF NOT EXISTS idx_staff_attendance_open_unique
    ON staff_attendance(employee_id) WHERE status = 'OPEN';
