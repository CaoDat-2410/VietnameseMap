# Attendance (Check-in / Check-out) — FE TODO

**Backend status:** done and merged into `Loc` (see `BE/src/main/java/com/vnmap/attendance/`).
**Base URL:** `http://localhost:8080/api/v1/attendance`
**Auth:** same Bearer JWT as the rest of the app. The backend resolves the caller's `employeeId` from the token — FE never sends it explicitly for self-service calls.

---

## 1. Role matrix

| Role | Can do |
|---|---|
| STAFF | Check themselves in/out. View their own history. |
| MANAGER | Everything STAFF can do, **plus**: list/view any employee's records, correct (edit) a record, delete a record. |
| ADMIN | **Read-only**: list/view any employee's records. Cannot edit or delete. |
| STUDENT | No access. |

A user with no linked employee record (`employeeId == null` in the JWT/profile) gets `400 Bad Request` on check-in/check-out — surface this as "Tài khoản của bạn chưa được liên kết với hồ sơ nhân viên."

---

## 2. Endpoints

| Method | Path | Roles | Body / Query | Notes |
|---|---|---|---|---|
| POST | `/attendance/check-in` | STAFF, MANAGER | `{ note?, lat?, lng? }` | 409 if the caller already has an open (not checked-out) session. |
| POST | `/attendance/check-out` | STAFF, MANAGER | `{ note?, lat?, lng? }` | 409 if no open session exists. |
| GET | `/attendance/me` | STAFF, MANAGER | `?page=0&limit=20` | Caller's own history, paginated, newest first. |
| GET | `/attendance` | MANAGER, ADMIN | `?employeeId=&status=&from=&to=&page=&limit=` | `status` is `OPEN` or `CLOSED`. `from`/`to` are ISO `LocalDateTime` (e.g. `2026-07-01T00:00:00`). |
| GET | `/attendance/{id}` | MANAGER, ADMIN | — | Single record detail. |
| PUT | `/attendance/{id}` | MANAGER only | `{ checkInAt?, checkOutAt?, checkInNote?, checkOutNote? }` | Manual correction. Any omitted field is left unchanged. Setting `checkOutAt` closes the record. |
| DELETE | `/attendance/{id}` | MANAGER only | — | Removes a bad/duplicate record. |

All responses are wrapped in the standard `ApiResponse<T>` envelope (`success`, `message`, `data`, `timestamp`).

### `AttendanceDto` shape

```json
{
  "id": 10,
  "employeeId": 5,
  "employeeName": "Nguyen Van A",
  "checkInAt": "2026-07-18T08:00:00",
  "checkOutAt": "2026-07-18T17:00:00",
  "checkInNote": "string or null",
  "checkOutNote": "string or null",
  "checkInLat": 10.77,
  "checkInLng": 106.7,
  "checkOutLat": 10.77,
  "checkOutLng": 106.7,
  "status": "OPEN | CLOSED",
  "workedMinutes": 540
}
```

`workedMinutes` is `null` while the session is still `OPEN`.

### List response shape (`PagedResponse<AttendanceDto>`)

```json
{ "items": [ /* AttendanceDto[] */ ], "page": 0, "limit": 20, "totalItems": 42, "totalPages": 3 }
```

---

## 3. Suggested FE work (Clean Architecture, matching `features/staff/`, `features/reports/`)

- [ ] `features/attendance/data/models/attendance_dto.dart` + `data/repositories/attendance_repository.dart` (Dio calls to the 7 endpoints above).
- [ ] `features/attendance/presentation/providers/attendance_viewmodel.dart` (Riverpod) — separate state for "my attendance" (staff self-service) vs "team attendance" (manager/admin list+filters).
- [ ] **Staff/Manager home or a new tab**: a check-in/check-out card — shows current open-session status, a big "Check in" / "Check out" button (mutually exclusive based on latest `/attendance/me` entry), optional note field, and recent history list.
- [ ] **Manager screen** `attendance_management_page.dart`: paginated table (reuse `data_table_2`, same pattern as `staff_registrations_page.dart`) with filters (employee, status, date range), row actions to edit (opens a dialog calling `PUT`) or delete (`DELETE`).
- [ ] **Admin view**: same list/table UI as manager's screen but hide the edit/delete actions — gate on `authViewmodel` role, same pattern already used elsewhere (e.g. `admin_notification_composer.dart` is only shown for ADMIN).
- [ ] Add a sidebar/drawer nav entry ("Chấm công" / "Attendance") visible to STAFF, MANAGER, ADMIN — reuse `AppNavItem` in `app/router.dart` + `app_sidebar.dart`.
- [ ] Add routes in `app/router.dart`: `/attendance/me` (staff self-service) and `/attendance` (manager/admin management), following the existing `GoRoute` + role guard pattern already used for `/reports`, `/staff/registrations`.
- [ ] l10n strings (`app_en.arb` / `app_vi.arb`): check-in, check-out, open session, worked hours, correction note, etc.
- [ ] Error handling: map `409 CONFLICT` ("already checked in" / "no open session") and `400` (no linked employee) to friendly snackbars — same `Result`/API-error pattern already used by `auth_repository.dart`.

## 4. Out of scope for now (confirm with team before building)

- Firebase Analytics events for check-in/out are **not** in the Lab3 requirement list — skip unless requested.
- No geofencing/validation of `lat`/`lng` against school/office location is implemented server-side; if needed, it's a future BE change, not a workaround to build client-side.
