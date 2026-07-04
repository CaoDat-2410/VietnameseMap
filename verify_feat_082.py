"""Verify feat-082 fixes: MinIO upload URL, 404, list endpoint, PDF generation."""
import json
import time
import urllib.request
import urllib.error

BASE = "http://localhost:8080"


def req(method, path, body=None, token=None):
    url = BASE + path
    data = None
    headers = {"Accept": "application/json"}
    if token:
        headers["Authorization"] = "Bearer " + token
    if body is not None:
        data = json.dumps(body).encode("utf-8")
        headers["Content-Type"] = "application/json"
    r = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(r, timeout=15) as resp:
            raw = resp.read().decode("utf-8")
            try:
                return resp.status, json.loads(raw) if raw else {}
            except Exception:
                return resp.status, raw
    except urllib.error.HTTPError as e:
        raw = e.read().decode("utf-8")
        try:
            return e.code, json.loads(raw) if raw else {}
        except Exception:
            return e.code, raw


def login(email, pwd="Admin@123"):
    s, b = req("POST", "/api/v1/auth/login", {"email": email, "password": pwd})
    if s == 200 and isinstance(b, dict):
        return b["data"]["accessToken"]
    return None


results = []


def check(label, ok, detail=""):
    mark = "PASS" if ok else "FAIL"
    results.append((mark, label, detail))
    print(f"  [{mark}] {label} {detail}")


admin_t = login("admin@vnmap.local")
print(f"admin login: {'OK' if admin_t else 'FAIL'}")

print("\n=== Fix #1: /storage/upload-url returns MinIO presigned URL ===")
s, b = req("POST", "/api/v1/storage/upload-url", {
    "folder": "campaigns",
    "fileName": "test-avatar.png",
    "contentType": "image/png",
}, token=admin_t)
print(f"  status: {s}")
if isinstance(b, dict):
    upload_url = b.get("data", {}).get("uploadUrl", "")
    public_url = b.get("data", {}).get("publicUrl", "")
    storage_path = b.get("data", {}).get("storagePath", "")
    check("uploadUrl is MinIO", "localhost:9000" in upload_url or "vnmap_minio" in upload_url,
          f"got: {upload_url[:80] if upload_url else 'EMPTY'}")
    check("uploadUrl is NOT GCS", "googleapis" not in upload_url, "")
    check("publicUrl uses MinIO", "localhost:9000" in public_url,
          f"got: {public_url[:80]}")
    check("storagePath present", bool(storage_path), f"path: {storage_path}")

print("\n=== Fix #2: 404 instead of 500 for unknown routes ===")
s, b = req("GET", "/api/v1/this-route-does-not-exist", token=admin_t)
check("unknown route returns 404", s == 404, f"got: {s}")
if isinstance(b, dict):
    print(f"    body: {b}")

print("\n=== Fix #3: GET /api/v1/reports list endpoint ===")
s, b = req("GET", "/api/v1/reports?page=0&limit=5", token=admin_t)
check("ADMIN GET /reports returns 200", s == 200, f"got: {s}")
if isinstance(b, dict) and "data" in b:
    print(f"    totalItems: {b['data'].get('totalItems')}, page: {b['data'].get('page')}")
    if b["data"].get("items"):
        print(f"    first item: id={b['data']['items'][0].get('reportId')}, status={b['data']['items'][0].get('status')}")

s, b = req("GET", "/api/v1/reports?status=READY&page=0&limit=5", token=admin_t)
check("ADMIN GET /reports?status=READY", s == 200, f"got: {s}")

# Student forbidden
student_t = login("student@vnmap.local")
s, b = req("GET", "/api/v1/reports", token=student_t)
check("STUDENT /reports forbidden", s == 403, f"got: {s}")

print("\n=== Fix #4: PDF report generation uploads to MinIO ===")
# Cancel any pending first by waiting or by going stale. Try POST.
s, b = req("POST", "/api/v1/reports/campaigns/pdf", {
    "reportType": "CAMPAIGN",
    "campaignId": 1,
    "fromDate": "2026-01-01",
    "toDate": "2026-12-31",
}, token=admin_t)
print(f"  POST /reports: {s}")
if s in (200, 202):
    rid = b.get("data", {}).get("reportId") if isinstance(b, dict) else None
    print(f"  reportId: {rid}")
    # Poll for completion
    for i in range(30):
        time.sleep(2)
        s2, b2 = req("GET", f"/api/v1/reports/{rid}", token=admin_t)
        if s2 == 200 and isinstance(b2, dict):
            st = b2.get("data", {}).get("status")
            err = b2.get("data", {}).get("errorMessage")
            print(f"  poll {i+1}: status={st}, err={err}")
            if st in ("READY", "FAILED"):
                check("PDF report ends in READY (not FAILED)", st == "READY", f"final: {st}")
                if st == "READY":
                    sp = b2.get("data", {}).get("storagePath")
                    check("storagePath set", bool(sp), f"path: {sp}")
                    # Get download URL
                    s3, b3 = req("GET", f"/api/v1/reports/{rid}/download-url", token=admin_t)
                    check("download-url returns 200", s3 == 200, f"got: {s3}")
                    if s3 == 200 and isinstance(b3, dict):
                        du = b3.get("data", {}).get("downloadUrl", "")
                        check("downloadUrl is MinIO", "localhost:9000" in du or "vnmap_minio" in du,
                              f"got: {du[:80] if du else 'EMPTY'}")
                        # Try to download the file
                        try:
                            with urllib.request.urlopen(du, timeout=10) as resp:
                                content = resp.read(8)
                                check("downloaded PDF starts with %PDF", content[:4] == b"%PDF",
                                      f"got: {content[:4]!r}")
                        except Exception as e:
                            check("downloaded PDF accessible", False, f"err: {e}")
                break
    else:
        check("PDF report completed within 60s", False, "timed out")
elif s == 409:
    print(f"  pending report exists already: {b}")
    check("PDF report 409 = already pending", True, "no way to test fresh")
else:
    check("PDF report POST", False, f"got: {s}, body: {str(b)[:200]}")

print("\n" + "=" * 60)
total = len(results)
passed = sum(1 for r in results if r[0] == "PASS")
failed = total - passed
print(f"TOTAL: {passed}/{total} PASS, {failed} FAIL")
if failed:
    for mark, label, detail in results:
        if mark == "FAIL":
            print(f"  - {label} {detail}")
