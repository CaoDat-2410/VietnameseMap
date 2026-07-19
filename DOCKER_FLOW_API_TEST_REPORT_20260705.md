# Docker Flow/API Test Report - 2026-07-05

Scope: inspection-only rerun of Docker frontend/backend plus smoke testing against `TEST_INVENTORY.md`.

Generated: 2026-07-05 08:59:53 +07:00

## Runtime

- Working directory: `D:\Project 2026\Flutter Project\PRM393\CP1_RE`
- Docker command run: `docker compose up -d --build`
- Frontend URL: `http://localhost:3000`
- Backend URL: `http://localhost:8080`
- Browser route base: `http://localhost:3000/#/...`

## Docker Result

`docker compose up -d --build` completed successfully.

Final service status:

| Service | Status | Port |
|---|---|---|
| `vnmap_backend` | Up, healthy | `8080` |
| `vnmap_frontend` | Up | `3000` |
| `vnmap_postgres` | Up, healthy | `15432` |
| `vnmap_redis` | Up, healthy | internal `6379` |
| `vnmap_minio` | Up, healthy | `9000`, `9001` |

Direct checks:

- `GET /actuator/health` -> `200`, body `{"status":"UP"}`
- `GET http://localhost:3000/` -> `200 OK`, served by nginx

Build warnings observed:

- Flutter web build completed, but reported wasm dry-run incompatibility because `profile_page.dart` imports `dart:html`.
- Flutter web build warned that `CupertinoIcons` font was referenced but not found in the built font set.

## Backend/API Tests

### Existing verifier: `verify_feat_082.py`

Result: `13/13 PASS`.

Covered:

- MinIO upload URL returns `localhost:9000`, not GCS.
- Unknown route returns `404`.
- `GET /api/v1/reports` works for admin and rejects student with `403`.
- PDF report generation reaches `READY`.
- Report download URL returns a MinIO URL.
- Downloaded report starts with `%PDF`.

### Existing smoke script: `smoke_post_20260702.py`

Result: `30/36 PASS`, `6/36 reported FAIL`.

The 6 reported failures match expected guard behavior documented in `TEST_INVENTORY.md`:

| Check | Actual | Assessment |
|---|---:|---|
| Duplicate student registration | `409` | Expected duplicate guard |
| Same-password change | `400` | Expected validation guard |
| Four back-to-back report creates | `409` | Expected one-pending-report guard |

Other smoke coverage passed:

- Login for `ADMIN`, `MANAGER`, `STAFF`, `STUDENT`.
- Student read access to campaigns, schools, coordinates, my registrations.
- Student denied from users API with `403`.
- Profile `GET /auth/me` and profile update.
- Avatar upload URL points to MinIO.
- Reports list and unknown route behavior.
- Staff registration dashboard and bulk status endpoint.
- Notifications list endpoint.
- MinIO PDF upload/download path.

### Additional direct API checks

| Endpoint | Result | Notes |
|---|---:|---|
| `GET /api/v1/geo/provinces` | `200` | OK |
| `GET /api/v1/geo/reverse?lat=21.028&lng=105.854` | `200` | OK |
| `GET /api/analytics/aggregate` | `200` | OK |
| `GET /api/v1/weather?lat=21.028&lng=105.854` | `502` | Fails because upstream OpenWeatherMap returned `401 UNAUTHORIZED`; Docker env likely missing/invalid `OWM_API_KEY` |

## Frontend/User Flow Tests

### Login redirects

Clean logout/login flow was tested through the Docker frontend.

| Role | Email | Result URL | Result |
|---|---|---|---|
| Admin | `admin@vnmap.local` | `#/home/admin` | PASS |
| Manager | `manager@vnmap.local` | `#/home/manager` | PASS |
| Staff | `staff@vnmap.local` | `#/home/staff` | PASS |
| Student | `student@vnmap.local` | `#/home/student` | PASS with console error below |

### Main route rendering

Authenticated admin direct-route smoke rendered these routes without router rejection:

- `#/home/admin`
- `#/admin/users`
- `#/campaigns`
- `#/campaigns/10/dashboard`
- `#/campaigns/10/events`
- `#/events/32`
- `#/schools`
- `#/schools/01-509`
- `#/staff/registrations`
- `#/analytics`
- `#/reports`
- `#/weather`
- `#/map`
- `#/profile`
- `#/settings`

Concrete test IDs used:

- Campaign: `10`
- Event: `32`
- School: `01-509` (`Cao dang FPT Polytechnic`)

### Tab flows

Event detail `#/events/32`:

- Overview loaded.
- `Truong tham gia` tab switched and showed assigned schools.
- `Tuong tac` tab switched and showed interactions.
- `Nhan su` tab was not conclusively verified because one coordinate click landed on the adjacent tab.

School detail `#/schools/01-509`:

- Overview loaded.
- `Hoc sinh` tab switched and showed empty student state.
- `Nguoi than` tab switched and showed empty relatives state.
- `GV/BGH` was not conclusively verified because one coordinate click landed on the adjacent tab.

## Real Issues Found

### 1. Weather API fails in Docker

Severity: Medium

Evidence:

```text
GET /api/v1/weather?lat=21.028&lng=105.854 -> 502
message: Unable to retrieve data from external service: Client error: 401 UNAUTHORIZED
```

Likely cause: `OWM_API_KEY` is empty or invalid in Docker environment.

Impact: Weather page/API cannot show live weather unless the key is configured.

### 2. Student home throws Flutter console error

Severity: Medium

Evidence after login as `student@vnmap.local`:

```text
Null check operator used on a null value
Another exception was thrown: Instance of 'minified:jS<void>'
```

Visible page still rendered `#/home/student`, but the profile card displayed `N/A` values. This should be investigated in the student home/profile data path.

### 3. Browser direct navigation to login does not clear authenticated session

Severity: Low

Observation: navigating to `#/login` while already authenticated did not reset the active admin session. Using the app's logout route/action before logging in as another role worked correctly.

Impact: Not necessarily a user bug, but automated/manual role-switch testing must logout first.

## Expected/Non-Issue Findings

These are not counted as product failures:

- Student duplicate campaign registration returns `409`.
- Same-password change returns `400`.
- Concurrent report generation returns `409`.
- `POST /api/v1/auth/firebase` with an invalid token returns `401`.

## Notes

- No source code was edited.
- This report file is the only intended workspace change from this inspection.
- Existing repo had many pre-existing modified/untracked files before this report; they were not touched.
