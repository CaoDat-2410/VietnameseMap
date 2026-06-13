CREATE TABLE IF NOT EXISTS schools (
    id BIGSERIAL PRIMARY KEY,
    school_uid VARCHAR(32) NOT NULL UNIQUE,
    province_code VARCHAR(20) NOT NULL,
    province_name VARCHAR(255) NOT NULL,
    commune_code VARCHAR(20),
    commune_name VARCHAR(255),
    school_code VARCHAR(20) NOT NULL,
    school_name VARCHAR(255) NOT NULL,
    address TEXT,
    area_type VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_school_province_code UNIQUE (province_code, school_code)
);

CREATE INDEX IF NOT EXISTS idx_schools_province ON schools(province_code);
CREATE INDEX IF NOT EXISTS idx_schools_commune ON schools(commune_code);
CREATE INDEX IF NOT EXISTS idx_schools_area ON schools(area_type);
CREATE INDEX IF NOT EXISTS idx_schools_name ON schools(school_name);

CREATE TABLE IF NOT EXISTS employees (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS campaigns (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    status VARCHAR(50) NOT NULL,
    objective TEXT,
    start_date DATE,
    end_date DATE,
    owner_employee_id BIGINT REFERENCES employees(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_campaign_status ON campaigns(status);

CREATE TABLE IF NOT EXISTS campaign_events (
    id BIGSERIAL PRIMARY KEY,
    campaign_id BIGINT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    event_type VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL,
    starts_at TIMESTAMP,
    ends_at TIMESTAMP,
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_events_campaign ON campaign_events(campaign_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON campaign_events(status);

CREATE TABLE IF NOT EXISTS event_schools (
    event_id BIGINT NOT NULL REFERENCES campaign_events(id) ON DELETE CASCADE,
    school_uid VARCHAR(32) NOT NULL REFERENCES schools(school_uid) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, school_uid)
);

CREATE TABLE IF NOT EXISTS event_assignments (
    event_id BIGINT NOT NULL REFERENCES campaign_events(id) ON DELETE CASCADE,
    employee_id BIGINT NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (event_id, employee_id)
);

CREATE TABLE IF NOT EXISTS students (
    id BIGSERIAL PRIMARY KEY,
    school_uid VARCHAR(32) NOT NULL REFERENCES schools(school_uid) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    grade VARCHAR(20),
    class_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_students_school ON students(school_uid);

CREATE TABLE IF NOT EXISTS persons (
    id BIGSERIAL PRIMARY KEY,
    school_uid VARCHAR(32) NOT NULL REFERENCES schools(school_uid) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_persons_school ON persons(school_uid);

CREATE TABLE IF NOT EXISTS student_relatives (
    id BIGSERIAL PRIMARY KEY,
    student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    school_uid VARCHAR(32) NOT NULL REFERENCES schools(school_uid) ON DELETE CASCADE,
    full_name VARCHAR(255) NOT NULL,
    relationship VARCHAR(50),
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_relatives_student ON student_relatives(student_id);
CREATE INDEX IF NOT EXISTS idx_relatives_school ON student_relatives(school_uid);

CREATE TABLE IF NOT EXISTS interactions (
    id BIGSERIAL PRIMARY KEY,
    campaign_id BIGINT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    event_id BIGINT NOT NULL REFERENCES campaign_events(id) ON DELETE CASCADE,
    employee_id BIGINT NOT NULL REFERENCES employees(id),
    school_uid VARCHAR(32) NOT NULL REFERENCES schools(school_uid),
    participant_type VARCHAR(20) NOT NULL,
    participant_id BIGINT NOT NULL,
    channel VARCHAR(50) NOT NULL,
    outcome VARCHAR(50) NOT NULL,
    note TEXT,
    next_follow_up_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_interactions_campaign ON interactions(campaign_id);
CREATE INDEX IF NOT EXISTS idx_interactions_event ON interactions(event_id);
CREATE INDEX IF NOT EXISTS idx_interactions_school ON interactions(school_uid);
CREATE INDEX IF NOT EXISTS idx_interactions_outcome ON interactions(outcome);

CREATE TABLE IF NOT EXISTS school_import_warnings (
    id BIGSERIAL PRIMARY KEY,
    warning_type VARCHAR(50) NOT NULL,
    province_code VARCHAR(20),
    commune_code VARCHAR(20),
    school_uid VARCHAR(32),
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
