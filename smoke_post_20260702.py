#!/usr/bin/env python3
"""Comprehensive smoke test of all features added since 2026-07-02."""
import io
import json
import sys
import time
import urllib.request
import urllib.error

# Force UTF-8 stdout to handle Vietnamese / Unicode in messages
if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
else:
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

BASE = "http://localhost:8080"
PASS = "[PASS]"
FAIL = "[FAIL]"
SECTION = "=== "

ADMIN_EMAIL = "admin@vnmap.local"
ADMIN_PASS = "Admin@123"
STAFF_EMAIL = "staff@vnmap.local"
STAFF_PASS = "Admin@123"
STUDENT_EMAIL = "student@vnmap.local"
STUDENT_PASS = "Admin@123"
MANAGER_EMAIL = "manager@vnmap.local"
MANAGER_PASS = "Admin@123"


def req(method, path, token=None, body=None, data=None, content_type="application/json"):
    url = BASE + path
    headers = {}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    payload = None
    if data is not None:
        payload = data
        headers["Content-Type"] = content_type
    elif body is not None:
        payload = json.dumps(body).encode()
        headers["Content-Type"] = "application/json"
    r = urllib.request.Request(url, data=payload, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=30) as resp:
            raw = resp.read() or b"{}"
            return resp.status, json.loads(raw)
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read() or b"{}")
        except Exception:
            return e.code, {"raw": str(e)}
    except urllib.error.URLError as e:
        return 0, {"error": str(e)}


results = {"pass": 0, "fail": 0, "fails": []}


def check(label, condition, detail=""):
    icon = PASS if condition else FAIL
    safe_detail = (detail or "").encode("ascii", "replace").decode("ascii")
    print(f"  {icon} {label}" + (f" -- {safe_detail}" if safe_detail else ""))
    if condition:
        results["pass"] += 1
    else:
        results["fail"] += 1
        results["fails"].append(label)
    return condition


def sec(name):
    print(f"\n{SECTION}{name} ===")


def login(email, password):
    status, body = req("POST", "/api/v1/auth/login", body={"email": email, "password": password})
    if status == 200 and "data" in body:
        # The auth response uses accessToken
        return body["data"].get("accessToken") or body["data"].get("token")
    print(f"  Login failed for {email}: {status} {body}")
    return None


sec("Pre-flight: backend health")
status, body = req("GET", "/actuator/health")
check("/actuator/health returns UP", status == 200 and body.get("status") == "UP",
      f"got {status}")

sec("Auth: login for all roles")
admin_token = login(ADMIN_EMAIL, ADMIN_PASS)
check("Admin login", bool(admin_token))
staff_token = login(STAFF_EMAIL, STAFF_PASS)
check("Staff login", bool(staff_token))
student_token = login(STUDENT_EMAIL, STUDENT_PASS)
check("Student login", bool(student_token))
manager_token = login(MANAGER_EMAIL, MANAGER_PASS)
check("Manager login", bool(manager_token))

# feat-077
sec("feat-077: Student access + register")
for path in ["/api/v1/campaigns?page=0&limit=5", "/api/v1/schools?page=0&limit=5",
             "/api/v1/schools/coordinates", "/api/v1/student-registrations/my"]:
    s, _ = req("GET", path, token=student_token)
    check(f"Student GET {path}", s == 200, f"got {s}")

# /admin/users does not exist - correct path is /api/v1/users (admin only)
s, _ = req("GET", "/api/v1/users?page=0&limit=5", token=student_token)
check("Student blocked from /users", s == 403, f"got {s}")

# Get a school uid from list to register
s, body = req("GET", "/api/v1/schools?page=0&limit=1", token=student_token)
school_uid = None
if s == 200 and isinstance(body, dict):
    items = body.get("data", {}).get("items", [])
    if items:
        school_uid = items[0].get("uid") or items[0].get("id") or items[0].get("schoolUid")

# Register (only if we have schoolUid)
if school_uid:
    s, body = req("POST", "/api/v1/campaigns/1/student-registrations",
                  token=student_token,
                  body={"password": "student123", "fullName": "Student Smoke",
                        "email": "smoke@test.com", "phone": "0900000001",
                        "grade": "12", "className": "12A1", "note": "smoke",
                        "schoolUid": school_uid})
    check("Student POST registration", s == 200 or s == 201, f"got {s}")
else:
    print("  [SKIP] Student POST registration: no school uid available")

# feat-079
sec("feat-079: Profile + avatar")
s, body = req("GET", "/api/v1/auth/me", token=student_token)
check("GET /auth/me", s == 200, f"got {s}")
has_profile_fields = bool(body.get("data", {}).get("email") or body.get("data", {}).get("username"))
check("Profile has email/username", has_profile_fields)

# Update profile (correct path is PUT /auth/me)
s, _ = req("PUT", "/api/v1/auth/me", token=student_token,
           body={"fullName": "Student Smoke Updated", "phone": "0900000099"})
check("PUT /auth/me (profile update)", s == 200, f"got {s}")

# Change password (correct path is PUT /auth/me/password)
s, _ = req("PUT", "/api/v1/auth/me/password", token=student_token,
           body={"currentPassword": "Admin@123", "newPassword": "Admin@123"})
check("PUT /auth/me/password", s == 200, f"got {s}")

s, body = req("POST", "/api/v1/storage/upload-url", token=student_token,
              body={"folder": "avatars", "fileName": "smoke-avatar.png",
                    "contentType": "image/png", "userId": "1"})
check("Avatar upload-url returns 200", s == 200, f"got {s}")
upload_url = body.get("data", {}).get("uploadUrl") if isinstance(body, dict) else None
check("Avatar uploadUrl is MinIO (not GCS)", upload_url and "localhost:9000" in upload_url,
      f"got {upload_url}")

# feat-080
sec("feat-080: Multi-form PDF reports")
for rt in ["CAMPAIGN", "EVENT", "SCHOOL", "REGION"]:
    s, body = req("POST", "/api/v1/reports/campaigns/pdf", token=admin_token,
                  body={"reportType": rt, "campaignId": 1,
                        "fromDate": "2026-01-01", "toDate": "2026-12-31"})
    ok = s == 200 and isinstance(body, dict) and body.get("data", {}).get("reportId")
    check(f"POST /reports/campaigns/pdf type={rt}", ok, f"got {s} body={body}")

# feat-082
sec("feat-082: Reports list + 404 + MinIO")
s, body = req("GET", "/api/v1/reports?page=0&limit=5", token=admin_token)
check("GET /api/v1/reports (admin)", s == 200 and "data" in body, f"got {s}")
items = body.get("data", {}).get("items", []) if isinstance(body, dict) else []
check("Reports list contains items", len(items) > 0, f"got {len(items)} items")

s, body = req("GET", "/api/v1/reports?status=FAILED&page=0&limit=5", token=admin_token)
check("GET /reports?status=FAILED (admin)", s == 200, f"got {s}")

s, _ = req("GET", "/api/v1/reports?page=0&limit=5", token=student_token)
check("GET /reports (student) forbidden", s == 403, f"got {s}")

s, body = req("GET", "/api/v1/this-route-does-not-exist-xyz", token=admin_token)
check("Unknown route returns 404", s == 404, f"got {s}")

# feat-081
sec("feat-081: Staff approval dashboard")
s, body = req("GET", "/api/v1/staff/student-registrations?page=0&limit=5", token=staff_token)
check("GET /staff/student-registrations (staff)", s == 200, f"got {s}")

s, _ = req("GET", "/api/v1/staff/student-registrations?page=0&limit=5", token=manager_token)
check("GET /staff/student-registrations (manager)", s == 200, f"got {s}")

s, body = req("GET", "/api/v1/staff/student-registrations?page=0&limit=1", token=staff_token)
items = body.get("data", {}).get("items", []) if isinstance(body, dict) else []
if items:
    ids = [items[0]["id"]]
    s, body = req("POST", "/api/v1/student-registrations/bulk-status", token=staff_token,
                  body={"ids": ids, "status": "APPROVED"})
    check(f"POST /student-registrations/bulk-status ({ids})", s == 200,
          f"got {s}")
else:
    print("  [SKIP] bulk-status: no registrations available")

# feat-078
sec("feat-078: Notifications")
s, body = req("GET", "/api/v1/notifications?page=0&limit=5", token=student_token)
check("GET /notifications (student)", s == 200, f"got {s}")
has_notifs = isinstance(body, dict) and "data" in body
check("Notifications response shape", has_notifs)

# Firebase auth endpoint
sec("Firebase auth (smoke check)")
s, body = req("POST", "/api/v1/auth/firebase",
              body={"idToken": "invalid-token-just-checking-endpoint"})
check("POST /auth/firebase endpoint reachable",
      s == 400 or s == 401 or s == 403 or s == 200,
      f"got {s}")

# MinIO end-to-end
sec("MinIO end-to-end: PDF report upload + download")
s, body = req("POST", "/api/v1/reports/campaigns/pdf", token=admin_token,
              body={"reportType": "CAMPAIGN", "campaignId": 1,
                    "fromDate": "2026-01-01", "toDate": "2026-12-31"})
check("POST /reports/campaigns/pdf (CAMPAIGN)", s == 200, f"got {s}")
if s == 200 and isinstance(body, dict) and body.get("data"):
    rid = body["data"].get("reportId") or body["data"].get("id")
    final_status = "PENDING"
    for _ in range(20):
        time.sleep(1)
        s2, b2 = req("GET", f"/api/v1/reports/{rid}", token=admin_token)
        if s2 == 200:
            final_status = b2.get("data", {}).get("status", "PENDING")
            if final_status == "READY":
                break
    check(f"Report #{rid} reached READY", final_status == "READY",
          f"final status: {final_status}")
    s3, b3 = req("GET", f"/api/v1/reports/{rid}/download-url", token=admin_token)
    check(f"GET /reports/{rid}/download-url", s3 == 200, f"got {s3}")
    download_url = b3.get("data", {}).get("downloadUrl") if isinstance(b3, dict) else None
    if download_url:
        try:
            with urllib.request.urlopen(download_url, timeout=15) as r:
                pdf_bytes = r.read()
                check("Downloaded PDF is valid", pdf_bytes[:4] == b"%PDF",
                      f"first bytes: {pdf_bytes[:8]!r}")
        except Exception as e:
            check("Download PDF succeeded", False, str(e))

print(f"\n{SECTION}SUMMARY ===")
total = results["pass"] + results["fail"]
print(f"  Total: {total} | Passed: {results['pass']} | Failed: {results['fail']}")
if results["fail"]:
    print(f"\n{FAIL} Failed checks:")
    for f in results["fails"]:
        print(f"  - {f}")
    sys.exit(1)
else:
    print(f"\n{PASS} ALL CHECKS PASSED")
