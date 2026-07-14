"""
Campaign school import and dev seed
===================================

Usage:
    python import_schools_campaign.py --excel "C:/Users/docao/Downloads/Truong_THPT_2026_import_ready.xlsx"

This script repairs the campaign schema in the current Docker database, imports
the THPT school workbook, records commune mismatches in school_import_warnings,
and seeds minimal campaign data for frontend integration.
"""

import argparse
from datetime import date, datetime
from pathlib import Path

import openpyxl
import psycopg2
from psycopg2.extras import execute_values

DB_CONFIG = {
    "host": "localhost",
    "port": 5432,
    "dbname": "vnmapdb",
    "user": "postgres",
    "password": "123456",
}


def read_sql() -> str:
    return (Path(__file__).parent / "postgres" / "campaign-module.sql").read_text(
        encoding="utf-8"
    )


def ensure_schema(conn):
    with conn.cursor() as cur:
        cur.execute(read_sql())
    conn.commit()


def cell(value) -> str:
    if value is None:
        return ""
    if isinstance(value, float) and value.is_integer():
        return str(int(value))
    return str(value).strip()


def import_schools(conn, excel_path: str):
    workbook = openpyxl.load_workbook(excel_path, read_only=True, data_only=True)
    sheet = workbook.active
    rows = []

    for row in sheet.iter_rows(min_row=2, values_only=True):
        province_code = cell(row[1])
        province_name = cell(row[2])
        commune_code = cell(row[3])
        commune_name = cell(row[4])
        school_code = cell(row[5])
        school_name = cell(row[6])
        address = cell(row[7])
        area_type = cell(row[8])
        if not province_code or not school_code or not school_name:
            continue

        school_uid = f"{province_code}-{school_code}"
        rows.append(
            (
                school_uid,
                province_code,
                province_name,
                commune_code,
                commune_name,
                school_code,
                school_name,
                address,
                area_type,
            )
        )

    with conn.cursor() as cur:
        cur.execute("SELECT code FROM administrative_units WHERE kind = 'province'")
        province_codes = {code for (code,) in cur.fetchall()}
        missing_provinces = sorted({r[1] for r in rows} - province_codes)
        if missing_provinces:
            raise RuntimeError(f"Unmatched province codes: {missing_provinces}")

        cur.execute("SELECT code FROM administrative_units WHERE kind = 'commune'")
        commune_codes = {code for (code,) in cur.fetchall()}

        cur.execute("TRUNCATE school_import_warnings")
        warnings = []
        for row in rows:
            school_uid, province_code, _, commune_code, _, _, school_name, _, _ = row
            if commune_code and commune_code not in commune_codes:
                warnings.append(
                    (
                        "UNMATCHED_COMMUNE",
                        province_code,
                        commune_code,
                        school_uid,
                        f"Commune code {commune_code} not found for school {school_name}",
                    )
                )

        execute_values(
            cur,
            """
            INSERT INTO schools (
                school_uid, province_code, province_name, commune_code, commune_name,
                school_code, school_name, address, area_type
            ) VALUES %s
            ON CONFLICT (province_code, school_code) DO UPDATE SET
                school_uid = EXCLUDED.school_uid,
                province_name = EXCLUDED.province_name,
                commune_code = EXCLUDED.commune_code,
                commune_name = EXCLUDED.commune_name,
                school_name = EXCLUDED.school_name,
                address = EXCLUDED.address,
                area_type = EXCLUDED.area_type,
                updated_at = CURRENT_TIMESTAMP
            """,
            rows,
            page_size=500,
        )

        if warnings:
            execute_values(
                cur,
                """
                INSERT INTO school_import_warnings (
                    warning_type, province_code, commune_code, school_uid, message
                ) VALUES %s
                """,
                warnings,
            )

        cur.execute("SELECT COUNT(*) FROM schools")
        school_count = cur.fetchone()[0]
        cur.execute("SELECT COUNT(DISTINCT province_code) FROM schools")
        province_count = cur.fetchone()[0]
        cur.execute(
            """
            SELECT COUNT(*) FROM (
                SELECT province_code, school_code
                FROM schools
                GROUP BY province_code, school_code
                HAVING COUNT(*) > 1
            ) d
            """
        )
        duplicate_pairs = cur.fetchone()[0]

    conn.commit()
    return {
        "schools": school_count,
        "provinces": province_count,
        "duplicate_pairs": duplicate_pairs,
        "warnings": len(warnings),
    }


def fetch_school_uids(cur, limit: int):
    cur.execute(
        "SELECT school_uid FROM schools ORDER BY province_code, school_code LIMIT %s",
        (limit,),
    )
    return [uid for (uid,) in cur.fetchall()]


def seed_data(conn):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO employees (id, full_name, role) VALUES
                (1, 'Dev Staff', 'STAFF'),
                (2, 'Dev Manager', 'MANAGER'),
                (3, 'Dev Staff 2', 'STAFF'),
                (4, 'Dev Admin', 'ADMIN')
            ON CONFLICT (id) DO UPDATE SET
                full_name = EXCLUDED.full_name,
                role = EXCLUDED.role
            """
        )

        auth_users = [
            ("admin@vnmap.local", "$2b$10$bs3pnTXw3fRPbUoZeQ1hI..HMTKKU4nMpgk4ecEJ56yD78./JVKfe", "ADMIN", 4),
            ("manager@vnmap.local", "$2b$10$CvXtvsYTUkffzNx24P./Ye.NKJmbtHQ4mkkhm4noU/sMlGRUUtk2S", "MANAGER", 2),
            ("staff@vnmap.local", "$2b$10$RkYMrmpnI8Sc13OKvsowou3YXBNk6NMiQYhK.pP6csNrTf8f7I2Mi", "STAFF", 1),
        ]
        execute_values(
            cur,
            """
            INSERT INTO app_users (email, password_hash, role, status, employee_id)
            VALUES %s
            ON CONFLICT (email) DO UPDATE SET
                role = EXCLUDED.role,
                status = EXCLUDED.status,
                employee_id = EXCLUDED.employee_id,
                updated_at = CURRENT_TIMESTAMP
            """,
            [(email, password_hash, role, "ACTIVE", employee_id) for email, password_hash, role, employee_id in auth_users],
        )

        school_uids = fetch_school_uids(cur, 8)
        if len(school_uids) < 5:
            raise RuntimeError("Need at least 5 imported schools before seeding")

        campaigns = [
            (1, "Tư vấn tuyển sinh 2026", "ACTIVE", "Thu thập nhu cầu tuyển sinh", date(2026, 6, 1), date(2026, 7, 31), 2),
            (2, "Kết nối THPT khu vực trọng điểm", "DRAFT", "Chuẩn bị danh sách trường mục tiêu", date(2026, 8, 1), date(2026, 9, 30), 2),
        ]
        execute_values(
            cur,
            """
            INSERT INTO campaigns (
                id, name, status, objective, start_date, end_date, owner_employee_id
            ) VALUES %s
            ON CONFLICT (id) DO UPDATE SET
                name = EXCLUDED.name,
                status = EXCLUDED.status,
                objective = EXCLUDED.objective,
                start_date = EXCLUDED.start_date,
                end_date = EXCLUDED.end_date,
                owner_employee_id = EXCLUDED.owner_employee_id
            """,
            campaigns,
        )

        events = [
            (1, 1, "Tư vấn trực tiếp đợt 1", "SCHOOL_VISIT", "PLANNED", datetime(2026, 6, 20, 8), datetime(2026, 6, 20, 11), "Seed event"),
            (2, 1, "Workshop online ngành CNTT", "ONLINE_WORKSHOP", "PLANNED", datetime(2026, 6, 25, 19), datetime(2026, 6, 25, 21), "Seed event"),
            (3, 2, "Khảo sát nhu cầu trường", "SURVEY", "PLANNED", datetime(2026, 8, 5, 8), datetime(2026, 8, 5, 10), "Seed event"),
            (4, 2, "Gặp ban giám hiệu", "MEETING", "PLANNED", datetime(2026, 8, 12, 9), datetime(2026, 8, 12, 11), "Seed event"),
        ]
        execute_values(
            cur,
            """
            INSERT INTO campaign_events (
                id, campaign_id, name, event_type, status, starts_at, ends_at, note
            ) VALUES %s
            ON CONFLICT (id) DO UPDATE SET
                campaign_id = EXCLUDED.campaign_id,
                name = EXCLUDED.name,
                event_type = EXCLUDED.event_type,
                status = EXCLUDED.status,
                starts_at = EXCLUDED.starts_at,
                ends_at = EXCLUDED.ends_at,
                note = EXCLUDED.note
            """,
            events,
        )

        event_schools = []
        for event_id in range(1, 5):
            for school_uid in school_uids[:5]:
                event_schools.append((event_id, school_uid))
        execute_values(
            cur,
            "INSERT INTO event_schools (event_id, school_uid) VALUES %s ON CONFLICT DO NOTHING",
            event_schools,
        )

        assignments = [(event_id, employee_id) for event_id in range(1, 5) for employee_id in (1, 2, 3)]
        execute_values(
            cur,
            "INSERT INTO event_assignments (event_id, employee_id) VALUES %s ON CONFLICT DO NOTHING",
            assignments,
        )

        for school_uid in school_uids[:5]:
            for i in range(1, 3):
                cur.execute(
                    """
                    INSERT INTO students (school_uid, full_name, grade, class_name)
                    SELECT %s, %s, '12', %s
                    WHERE NOT EXISTS (
                        SELECT 1 FROM students WHERE school_uid = %s AND full_name = %s
                    )
                    RETURNING id
                    """,
                    (school_uid, f"Seed Student {i} {school_uid}", f"12A{i}", school_uid, f"Seed Student {i} {school_uid}"),
                )
                row = cur.fetchone()
                if row:
                    student_id = row[0]
                    cur.execute(
                        """
                        INSERT INTO student_relatives (
                            student_id, school_uid, full_name, relationship, phone
                        ) VALUES (%s, %s, %s, 'PARENT', '0900000000')
                        """,
                        (student_id, school_uid, f"Seed Parent {i} {school_uid}"),
                    )

            cur.execute(
                """
                INSERT INTO persons (school_uid, full_name, role)
                SELECT %s, %s, 'TEACHER'
                WHERE NOT EXISTS (
                    SELECT 1 FROM persons WHERE school_uid = %s AND full_name = %s
                )
                """,
                (school_uid, f"Seed Teacher {school_uid}", school_uid, f"Seed Teacher {school_uid}"),
            )

        seed_student_email = "student@vnmap.local"
        seed_student_password_hash = "$2a$10$bz1Wo4WK3gMdR5WTfjb1oOt68CG1fyiSDKNPluReRXxSud1ohWU6m"
        seed_student_school_uid = school_uids[0]
        cur.execute(
            "SELECT id FROM students WHERE LOWER(email) = LOWER(%s)",
            (seed_student_email,),
        )
        row = cur.fetchone()
        if row:
            seed_student_id = row[0]
            cur.execute(
                """
                UPDATE students
                SET school_uid = %s,
                    full_name = 'Dev Student',
                    phone = '0901234567',
                    date_of_birth = '2008-01-01',
                    address = 'Seed student address',
                    grade = '12',
                    class_name = '12A1'
                WHERE id = %s
                """,
                (seed_student_school_uid, seed_student_id),
            )
        else:
            cur.execute(
                """
                INSERT INTO students (
                    school_uid, full_name, email, phone, date_of_birth, address, grade, class_name
                ) VALUES (%s, 'Dev Student', %s, '0901234567', '2008-01-01', 'Seed student address', '12', '12A1')
                RETURNING id
                """,
                (seed_student_school_uid, seed_student_email),
            )
            seed_student_id = cur.fetchone()[0]

        cur.execute(
            """
            INSERT INTO app_users (email, password_hash, role, status, student_id)
            VALUES (%s, %s, 'STUDENT', 'ACTIVE', %s)
            ON CONFLICT (email) DO UPDATE SET
                password_hash = EXCLUDED.password_hash,
                role = EXCLUDED.role,
                status = EXCLUDED.status,
                employee_id = NULL,
                student_id = EXCLUDED.student_id,
                updated_at = CURRENT_TIMESTAMP
            """,
            (seed_student_email, seed_student_password_hash, seed_student_id),
        )

        cur.execute(
            """
            INSERT INTO campaign_student_registrations (
                campaign_id, student_id, school_uid, status, note
            ) VALUES (1, %s, %s, 'PENDING', 'Seed registration for student browser verification')
            ON CONFLICT (campaign_id, student_id) DO UPDATE SET
                school_uid = EXCLUDED.school_uid,
                status = EXCLUDED.status,
                note = EXCLUDED.note,
                updated_at = CURRENT_TIMESTAMP
            """,
            (seed_student_id, seed_student_school_uid),
        )

        cur.execute("SELECT id, school_uid FROM students ORDER BY id LIMIT 3")
        students = cur.fetchall()
        interaction_rows = []
        for student_id, school_uid in students:
            interaction_rows.append(
                (
                    1,
                    1,
                    1,
                    school_uid,
                    "STUDENT",
                    student_id,
                    "MEETING",
                    "INTERESTED",
                    "Seed interaction for dashboard fixture",
                    datetime(2026, 6, 25, 9),
                )
            )

        cur.execute(
            "DELETE FROM interactions WHERE note = 'Seed interaction for dashboard fixture'"
        )
        execute_values(
            cur,
            """
            INSERT INTO interactions (
                campaign_id, event_id, employee_id, school_uid, participant_type,
                participant_id, channel, outcome, note, next_follow_up_at
            ) VALUES %s
            """,
            interaction_rows,
        )

        for sequence in (
            "employees_id_seq",
            "campaigns_id_seq",
            "campaign_events_id_seq",
        ):
            cur.execute(
                f"SELECT setval('{sequence}', COALESCE((SELECT MAX(id) FROM {sequence.replace('_id_seq', '')}), 1), true)"
            )

    conn.commit()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--excel",
        default="C:/Users/docao/Downloads/Truong_THPT_2026_import_ready.xlsx",
        help="Path to Truong_THPT_2026_import_ready.xlsx",
    )
    parser.add_argument("--host", default=DB_CONFIG["host"])
    args = parser.parse_args()

    config = {**DB_CONFIG, "host": args.host}
    conn = psycopg2.connect(**config)
    try:
        ensure_schema(conn)
        result = import_schools(conn, args.excel)
        seed_data(conn)
        print("Campaign schema/import/seed complete")
        print(result)
    finally:
        conn.close()


if __name__ == "__main__":
    main()
