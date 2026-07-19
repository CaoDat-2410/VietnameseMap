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

-- School coordinates for map display
ALTER TABLE schools ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE schools ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;
ALTER TABLE schools ADD COLUMN IF NOT EXISTS geocode_status VARCHAR(20) DEFAULT 'PENDING';
ALTER TABLE schools ADD COLUMN IF NOT EXISTS geocode_note TEXT;

CREATE INDEX IF NOT EXISTS idx_schools_geocode_status ON schools(geocode_status);
CREATE INDEX IF NOT EXISTS idx_schools_lat_lng ON schools(latitude, longitude) WHERE latitude IS NOT NULL AND longitude IS NOT NULL;

CREATE TABLE IF NOT EXISTS employees (
    id BIGSERIAL PRIMARY KEY,
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS app_users (
    id BIGSERIAL PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    status VARCHAR(50) NOT NULL DEFAULT 'ACTIVE',
    employee_id BIGINT REFERENCES employees(id),
    student_id BIGINT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login_at TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_app_users_role ON app_users(role);
CREATE INDEX IF NOT EXISTS idx_app_users_employee ON app_users(employee_id);
CREATE INDEX IF NOT EXISTS idx_app_users_student ON app_users(student_id);

CREATE TABLE IF NOT EXISTS refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES app_users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL UNIQUE,
    expires_at TIMESTAMP NOT NULL,
    revoked_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_expires ON refresh_tokens(expires_at);

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

ALTER TABLE campaigns
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

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

ALTER TABLE campaign_events
    ADD COLUMN IF NOT EXISTS location_label VARCHAR(255),
    ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
    ADD COLUMN IF NOT EXISTS school_uid VARCHAR(32),
    ADD COLUMN IF NOT EXISTS province_code VARCHAR(32);

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_event_school'
          AND table_name = 'campaign_events'
    ) THEN
        ALTER TABLE campaign_events
            ADD CONSTRAINT fk_event_school
            FOREIGN KEY (school_uid) REFERENCES schools(school_uid);
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_events_campaign ON campaign_events(campaign_id);
CREATE INDEX IF NOT EXISTS idx_events_status ON campaign_events(status);
CREATE INDEX IF NOT EXISTS idx_events_school ON campaign_events(school_uid);

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
    email VARCHAR(255),
    phone VARCHAR(50),
    date_of_birth DATE,
    address TEXT,
    grade VARCHAR(20),
    class_name VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

ALTER TABLE students
    ADD COLUMN IF NOT EXISTS email VARCHAR(255),
    ADD COLUMN IF NOT EXISTS phone VARCHAR(50),
    ADD COLUMN IF NOT EXISTS date_of_birth DATE,
    ADD COLUMN IF NOT EXISTS address TEXT;

CREATE INDEX IF NOT EXISTS idx_students_school ON students(school_uid);
CREATE UNIQUE INDEX IF NOT EXISTS uq_students_email_present ON students(email) WHERE email IS NOT NULL AND email <> '';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.table_constraints
        WHERE constraint_name = 'fk_app_users_student'
          AND table_name = 'app_users'
    ) THEN
        ALTER TABLE app_users
            ADD CONSTRAINT fk_app_users_student
            FOREIGN KEY (student_id) REFERENCES students(id);
    END IF;
END $$;

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

CREATE TABLE IF NOT EXISTS campaign_student_registrations (
    id BIGSERIAL PRIMARY KEY,
    campaign_id BIGINT NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
    student_id BIGINT NOT NULL REFERENCES students(id) ON DELETE CASCADE,
    school_uid VARCHAR(32) NOT NULL REFERENCES schools(school_uid),
    status VARCHAR(50) NOT NULL DEFAULT 'PENDING',
    note TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_campaign_student_registration UNIQUE (campaign_id, student_id)
);

CREATE INDEX IF NOT EXISTS idx_campaign_registrations_campaign ON campaign_student_registrations(campaign_id);
CREATE INDEX IF NOT EXISTS idx_campaign_registrations_student ON campaign_student_registrations(student_id);
CREATE INDEX IF NOT EXISTS idx_campaign_registrations_status ON campaign_student_registrations(status);

CREATE TABLE IF NOT EXISTS school_import_warnings (
    id BIGSERIAL PRIMARY KEY,
    warning_type VARCHAR(50) NOT NULL,
    province_code VARCHAR(20),
    commune_code VARCHAR(20),
    school_uid VARCHAR(32),
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
