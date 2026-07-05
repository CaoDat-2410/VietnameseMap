# VN Map Campaign Module — Functions, APIs & User-Flow Test Inventory

**Base URL:** `http://localhost:8080`
**Stack:** Spring Boot 3 + Java 21 backend, Flutter 3 web frontend, PostgreSQL 16, MinIO, Redis
**Auth:** Bearer JWT (HS256) + Refresh tokens; Firebase for Google Sign-In
**Roles:** `ADMIN`, `MANAGER`, `STAFF`, `STUDENT`
**Response wrapper:** `{ success, message, data }` (`ApiResponse<T>`), paginated wrapper `PagedResponse<T>`
**Source:** generated 2026-07-05 from `d:\Project 2026\Flutter Project\PRM393\CP1_RE`

---

## How to use this document

| Section | Use case |
|---------|----------|
| §1 Backend REST endpoints | API-level tests (Postman / curl / smoke scripts) |
| §2 Backend service functions | Unit / integration test targets |
| §3 FE pages & user flows | End-to-end browser / Playwright tests |
| §4 FE repositories & viewmodels | FE-level mock / integration tests |
| §5 Quick test suites by role | Manual smoke scripts you can run now |
| §6 Cross-cutting concerns | Auth, error handling, security config |

---

## 1. Backend REST endpoints — 73 total

### 1.1 Public, no auth required

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/v1/auth/login` | Email/password login to JWT pair |
| POST | `/api/v1/auth/refresh` | Exchange refresh token |
| POST | `/api/v1/auth/register` | **Declared public but no controller — returns 404** |
| POST | `/api/v1/auth/google` | Google ID token exchange |
| GET | `/api/v1/geo/provinces` | List 34 provinces |
| GET | `/api/v1/geo/provinces/{code}/boundary` | Province GeoJSON |
| GET | `/api/v1/geo/provinces-boundaries` | All province GeoJSON FeatureCollection |
| GET | `/api/v1/geo/provinces/{code}/communes` | Communes in province |
| GET | `/api/v1/geo/provinces/{code}/communes-boundaries` | Commune GeoJSON for province |
| GET | `/api/v1/geo/provinces/{code}/communes-paginated` | Paginated communes |
| GET | `/api/v1/geo/macro-regions/{name}/communes` | Communes in macro-region |
| GET | `/api/v1/geo/units/{code}` | Unit detail |
| GET | `/api/v1/geo/units/{code}/boundary` | Unit boundary |
| GET | `/api/v1/geo/reverse` | Reverse geocode by lat/lng |
| POST | `/api/v1/geo/admin/calculate-centroids` | Recompute centroids (open!) |
| GET | `/api/v1/geo/committees` | All People's Committee locations |
| GET | `/api/v1/geo/committees/{provinceCode}` | Committees per province |
| GET | `/api/v1/weather` (or `/current`) | Current weather for coordinates (Redis-cached, 30 min TTL) |
| GET | `/api/v1/weather/unit/{unitCode}` | Weather for admin unit centroid |
| GET | `/api/v1/weather/cache` | Cache check only |
| GET | `/api/analytics/aggregate` | Global / scoped dashboard aggregate |
| GET | `/api/analytics/trend` | Daily interaction trend |
| GET | `/api/analytics/channels` | Interactions by channel |
| GET | `/api/analytics/employees` | Top N employees |
| GET | `/actuator/health` | Health probe |
| GET | `/swagger-ui/**`, `/api-docs/**` | OpenAPI docs |

### 1.2 Authenticated — `POST /api/v1/auth/logout`
Body: optional `{ refreshToken }`. Returns 200.

### 1.3 Profile (`AuthController`) — any role

| Method | Path | Body | Returns |
|--------|------|------|---------|
| GET | `/api/v1/auth/me` | — | `AuthUserDto` (id, email, role, status, employeeId, studentId, avatarObjectKey, fullName, phone, firebaseUser) |
| PUT | `/api/v1/auth/me` | `UpdateProfileRequest { avatarObjectKey?, fullName?, phone? }` (all optional) | `AuthUserDto`. **Routing:** fullName -> `employees` or `students` based on role; phone -> `students` only (employees have no phone column); auto-loads `phone` from `students.phone` on GET |
| PUT | `/api/v1/auth/me/password` | `{ currentPassword, newPassword (min 8) }` | —. 400 if new = current; 401 if current wrong; 400 if Firebase account |

### 1.4 Schools — STAFF, MANAGER, ADMIN, STUDENT

| Method | Path | Role-restricted |
|--------|------|-----------------|
| GET | `/api/v1/schools?page&limit&provinceCode&communeCode&area&q` | — |
| GET | `/api/v1/schools/{schoolUid}` | — |
| GET | `/api/v1/schools/coordinates?provinceCode&communeCode` | — |
| GET | `/api/v1/schools/{schoolUid}/coordinates` | — |
| PUT | `/api/v1/schools/{schoolUid}/coordinates` | MANAGER, ADMIN |
| POST | `/api/v1/schools/coordinates/compute` | MANAGER, ADMIN |
| POST | `/api/v1/schools/geocode` (body: `[uids]`) | MANAGER, ADMIN |

### 1.5 Campaigns

| Method | Path | Roles |
|--------|------|-------|
| GET | `/api/v1/campaigns?includeArchived` | STAFF, MANAGER, ADMIN, STUDENT |
| POST | `/api/v1/campaigns` | MANAGER, ADMIN |
| GET | `/api/v1/campaigns/{id}` | STAFF, MANAGER, ADMIN, STUDENT |
| PUT | `/api/v1/campaigns/{id}` | MANAGER, ADMIN |
| DELETE | `/api/v1/campaigns/{id}` (archive) | MANAGER, ADMIN |
| GET | `/api/v1/campaigns/{id}/dashboard` | STAFF, MANAGER, ADMIN |
| GET | `/api/v1/campaigns/{id}/events?includeArchived` | STAFF, MANAGER, ADMIN, STUDENT |
| POST | `/api/v1/campaigns/{id}/events` | MANAGER, ADMIN |

### 1.6 Events (nested under campaigns)

| Method | Path | Roles |
|--------|------|-------|
| GET | `/api/v1/events/{eventId}` | STAFF, MANAGER, ADMIN, STUDENT |
| PUT | `/api/v1/events/{eventId}` | MANAGER, ADMIN |
| DELETE | `/api/v1/events/{eventId}` (archive) | MANAGER, ADMIN |
| POST | `/api/v1/events/{eventId}/schools` `{schoolUid}` | MANAGER, ADMIN |
| DELETE | `/api/v1/events/{eventId}/schools/{schoolUid}` | MANAGER, ADMIN |
| GET | `/api/v1/events/{eventId}/schools` | STAFF, MANAGER, ADMIN |
| POST | `/api/v1/events/{eventId}/assignments` `{employeeId}` | MANAGER, ADMIN |
| DELETE | `/api/v1/events/{eventId}/assignments/{employeeId}` | MANAGER, ADMIN |
| GET | `/api/v1/events/{eventId}/assignments` | STAFF, MANAGER, ADMIN |
| GET | `/api/v1/events/{eventId}/interactions` | STAFF, MANAGER, ADMIN |
| POST | `/api/v1/events/{eventId}/interactions` | STAFF, MANAGER, ADMIN |
| PUT | `/api/v1/events/{eventId}/interactions/{interactionId}` | STAFF, MANAGER, ADMIN |
| DELETE | `/api/v1/events/{eventId}/interactions/{interactionId}` | STAFF, MANAGER, ADMIN |

### 1.7 Student registrations

| Method | Path | Roles |
|--------|------|-------|
| POST | `/api/v1/campaigns/{campaignId}/student-registrations` (self-register) | STAFF, MANAGER, ADMIN, STUDENT |
| GET | `/api/v1/campaigns/{campaignId}/student-registrations` | STAFF, MANAGER, ADMIN |
| GET | `/api/v1/student-registrations/my` | STAFF, MANAGER, ADMIN, STUDENT |
| PUT | `/api/v1/student-registrations/{id}/status` `{status}` | STAFF, MANAGER, ADMIN |
| GET | `/api/v1/staff/student-registrations?campaignId&schoolUid&status&q&page&limit` | STAFF, MANAGER, ADMIN |
| POST | `/api/v1/student-registrations/bulk-status` `{ids[], status}` | STAFF, MANAGER, ADMIN |

`StudentRegistrationRequest`: `schoolUid, fullName, email, phone, password (min 8), grade, className, dateOfBirth?, address?, note?`.
`StudentRegistrationDto`: `id, campaignId, studentId, schoolUid, status, note, createdAt, updatedAt, student, school`.
`BulkRegistrationStatusRequest`: `ids (1-200), status`.

### 1.8 Employees, students, persons, relatives

| Method | Path | Roles |
|--------|------|-------|
| GET | `/api/v1/employees` | STAFF, MANAGER, ADMIN |
| POST | `/api/v1/employees` | ADMIN |
| PUT | `/api/v1/employees/{id}` | ADMIN |
| DELETE | `/api/v1/employees/{id}` | ADMIN |
| GET | `/api/v1/students?page&limit&schoolUid&q` | MANAGER, ADMIN |
| POST | `/api/v1/students` | MANAGER, ADMIN |
| PUT | `/api/v1/students/{id}` | MANAGER, ADMIN |
| DELETE | `/api/v1/students/{id}` | MANAGER, ADMIN |
| GET | `/api/v1/persons?schoolUid` | MANAGER, ADMIN |
| POST | `/api/v1/persons` | MANAGER, ADMIN |
| PUT | `/api/v1/persons/{id}` | MANAGER, ADMIN |
| DELETE | `/api/v1/persons/{id}` | MANAGER, ADMIN |
| GET | `/api/v1/student-relatives?schoolUid&studentId` | MANAGER, ADMIN |
| POST | `/api/v1/student-relatives` | MANAGER, ADMIN |
| PUT | `/api/v1/student-relatives/{id}` | MANAGER, ADMIN |
| DELETE | `/api/v1/student-relatives/{id}` | MANAGER, ADMIN |

### 1.9 Users — ADMIN only

| Method | Path | Notes |
|--------|------|-------|
| GET | `/api/v1/users` | List all users |
| POST | `/api/v1/users` | Returns 409 on email duplicate |
| PUT | `/api/v1/users/{id}` | |
| DELETE | `/api/v1/users/{id}` | |
| PUT | `/api/v1/users/{id}/role` `{role}` | |
| PUT | `/api/v1/users/{id}/status` `{status}` | Triggers `accountDeactivated` notification on DISABLED |

### 1.10 Notifications — any role reads; MANAGER, ADMIN send

| Method | Path | Notes |
|--------|------|-------|
| POST | `/api/v1/notifications/token` `{token, platform}` | Upserts FCM token (WEB/ANDROID/IOS) |
| DELETE | `/api/v1/notifications/token?token=` | Removes FCM token |
| POST | `/api/v1/notifications/send` `{targetUserId?, title, body, data?}` | Broadcast if no `targetUserId`; FCM + audit row |
| GET | `/api/v1/notifications?limit` | Caller's notifications, newest first |
| GET | `/api/v1/notifications/unread-count` | Returns `{count: N}` |
| PUT | `/api/v1/notifications/{id}/read` | 404 if not owner's |
| POST | `/api/v1/notifications/read-all` | Returns `{updated: N}` |

### 1.11 Storage + Reports — MinIO-backed

| Method | Path | Roles |
|--------|------|-------|
| POST | `/api/v1/storage/upload-url` `{fileName, contentType, folder, userId}` | Auth |
| POST | `/api/v1/reports/campaigns/pdf` | MANAGER, ADMIN |
| GET | `/api/v1/reports?page&limit&status&reportType` | MANAGER, ADMIN |
| GET | `/api/v1/reports/{reportId}` | MANAGER, ADMIN |
| GET | `/api/v1/reports/{reportId}/download-url` | MANAGER, ADMIN |

`UploadUrlResponse`: `uploadUrl, publicUrl, storagePath, expiresAtSeconds`.
`CampaignReportRequest`: `reportType (CAMPAIGN/EVENT/SCHOOL/REGION, default CAMPAIGN), campaignId?, eventId?, fromDate?, toDate?, eventStatus?, eventType?, provinceCode?, schoolUid?, employeeId?, registrationStatus?, interactionOutcome?, includeArchived?, sections?, chartImages?`. Generates `reportId`, status PENDING then background worker reads/writes via MinIO bucket `vnmap-campaign-reports`. `validateRange` allows max 6 months for non-ADMIN. Concurrency guard: one PENDING per user.

---

## 2. Backend service functions (key signatures)

### AuthService — `app_users, refresh_tokens, employees, students`
- `login(email, password)` — bcrypt + `last_login_at` + issue tokens
- `refresh(refreshToken)` — SHA-256 hashed lookup; rotates
- `logout(refreshToken)` — revokes token in DB
- `me(user)` — joins app_users + employees + students
- `updateProfile(user, request)` — routes fullName/phone to correct table; validates
- `changePassword(user, request)` — rejects same password; rejects Firebase accounts

### GoogleAuthService — `app_users`
- `authenticateWithGoogle(idToken)` — auto-provisions STUDENT first-time
- `verifyAndDecode(idToken)` — hits `https://oauth2.googleapis.com/tokeninfo`

### JwtService — pure
- `createAccessToken(user)` — HS256 with sub/email/role/status/employeeId/studentId/iat/exp
- `parseAccessToken(token)` — validates signature + expiry

### CampaignService — covers schools/campaigns/events/assignments/interactions/persons/relatives/students/employees/users
- `registerStudent` — upserts students + app_users (when needed) + INSERT campaign_student_registrations; triggers `NotificationTriggerService`
- `listRegistrationsForStaff` — STAFF scoped to their assigned events/schools; MANAGER scoped to own created events; ADMIN sees all
- `bulkUpdateRegistrationStatus` — batch update

### AnalyticsService — aggregate dashboard, trend, channel, top employees

### OsmGeocodingService — `schools, administrative_units`
- Hits Nominatim `nominatim.openstreetmap.org/search?q=...&countrycodes=vn` per school; falls back to commune centroid via PostGIS `ST_X/ST_Y`

### NotificationService — `fcm_tokens, notification_audit, app_users`
- `saveToken` — UPSERT ON CONFLICT (token) for rotation
- `sendToUser` / `sendBroadcast` — FCM send + audit insert
- `listForUser`, `unreadCount`, `markRead`, `markAllRead`

### NotificationTriggerService — scheduled jobs
- `@Scheduled dailyEventReminders()` (default 7 AM Asia/Saigon)
- `campaignCreated`, `eventCreated`, `staffAssigned`, `accountDeactivated`

### CampaignReportService — `report_exports + all related`
- `createCampaignReport` — guard one PENDING per user; background `generateReport`
- `generateReport` -> `PdfReportRenderer.render` -> `StorageService.uploadGeneratedObject` (paths under `reports/` route to `vnmap-campaign-reports` bucket)
- `@Scheduled cleanupReports` — 10-min PENDING -> FAILED; 90-day READY -> deleted from MinIO + DB

### PdfReportRenderer — pure
- `render(title, subtitle, kpis, sections, chartImagesBySection)` — title page with 4-col KPI grid; one section page per section (label + optional Base64 PNG chart + auto-detected-column data table)

### StorageService — MinIO only
- `generateUploadUrl(folder, fileName, contentType, userId)` — pre-signed PUT (15-min) via `SigV4Presigner`
- `uploadGeneratedObject(path, bytes, contentType)` — routes `reports/*` to `reportsBucket`
- `generateDownloadUrl(path, ttl)`, `deleteObject(path)`, `sanitizeFileName`

### WeatherServiceImpl — Redis + OpenWeatherMap
- `getCurrentWeather(lat, lng)` — Redis cache 30-min TTL; live fetch via `WeatherClient`
- `getWeatherByUnitCode(unitCode)` — centroid via `GeoService` -> `getCurrentWeather`

### GeoServiceImpl — `administrative_units, committee_locations`
- All read methods use Spring `@Cacheable("geo")`. `calculateCentroids` writes `ST_Centroid(boundary)`. `findUnitByCoordinate` uses PostGIS `ST_Contains`.

---

## 3. Flutter pages & user flows

### 3.1 Routes registered in GoRouter — 27 total

| Path | Page | File | Roles |
|------|------|------|-------|
| `/login` | `LoginPage` | `auth/pages/login_page.dart` | public |
| `/logout` | `LogoutPage` | `auth/pages/logout_page.dart` | public |
| `/student/register/:campaignId` | `StudentRegisterPage` | `student/pages/student_register_page.dart` | public |
| `/home/admin` | `AdminHomePage` | `home/pages/admin_home_page.dart` | ADMIN |
| `/home/manager` | `ManagerHomePage` | `home/pages/manager_home_page.dart` | MANAGER, ADMIN |
| `/home/staff` | `StaffHomePage` | `home/pages/staff_home_page.dart` | STAFF, MANAGER, ADMIN |
| `/home/student` | `StudentHomePage` | `home/pages/student_home_page.dart` | STUDENT |
| `/map` | `MapPage` | `map/pages/map_page.dart` | all |
| `/weather` | `WeatherPage` | `weather/pages/weather_page.dart` | all |
| `/campaigns` | `CampaignListPage` | `campaign/dashboard/pages/campaign_list_page.dart` | STAFF, MANAGER, ADMIN, STUDENT |
| `/campaigns/:id/dashboard` | `CampaignDashboardPage` | `campaign/dashboard/pages/campaign_dashboard_page.dart` | STAFF, MANAGER, ADMIN |
| `/campaigns/:id/events` | `CampaignEventsPage` | `campaign/events/pages/campaign_events_page.dart` | STAFF, MANAGER, ADMIN, STUDENT |
| `/events/:eventId` | `EventDetailPage` | `campaign/events/pages/event_detail_page.dart` | STAFF, MANAGER, ADMIN, STUDENT |
| `/schools` | `SchoolListPage` | `school/pages/school_list_page.dart` | STAFF, MANAGER, ADMIN, STUDENT |
| `/schools/:uid` | `SchoolDetailPage` | `school/pages/school_detail_page.dart` | STAFF, MANAGER, ADMIN, STUDENT |
| `/student/register-event/:campaignId` | `EventRegistrationPage` | `student/pages/event_registration_page.dart` | STUDENT |
| `/student/my-registrations` | `MyRegistrationsPage` | `student/pages/my_registrations_page.dart` | STUDENT |
| `/staff/registrations` | `StaffRegistrationsPage` | `staff/pages/staff_registrations_page.dart` | STAFF, MANAGER, ADMIN |
| `/admin/users` | `AdminUsersPage` | `admin/pages/admin_users_page.dart` | ADMIN |
| `/analytics` | `AnalyticsPage` | `analytics/pages/analytics_page.dart` | STAFF, MANAGER, ADMIN |
| `/reports` | `ReportsLandingPage` | `reports/pages/reports_landing_page.dart` | MANAGER, ADMIN |
| `/reports/campaign` | `CampaignReportTypePage` | `reports/pages/campaign_report_type_page.dart` | MANAGER, ADMIN |
| `/reports/event` | `EventReportTypePage` | `reports/pages/event_report_type_page.dart` | MANAGER, ADMIN |
| `/reports/school` | `SchoolReportTypePage` | `reports/pages/school_report_type_page.dart` | MANAGER, ADMIN |
| `/reports/region` | `RegionReportTypePage` | `reports/pages/region_report_type_page.dart` | MANAGER, ADMIN |
| `/profile` | `ProfilePage` | `auth/pages/profile_page.dart` | all |
| `/settings` | `SettingsPage` | `settings/pages/settings_page.dart` | all |

Reachable but not in router: `NotificationPreviewModal` (bell bottom sheet), `NotificationCenterPage` (`/notifications` deep-link).

### 3.2 End-to-end user flows

#### A. Admin flow
1. Login as `admin@vnmap.local` / `Admin@123` -> goes to `/home/admin`
2. KPI dashboard: users / campaigns / events / schools / interactions / pending activations
3. Sidebar -> Người dùng (`/admin/users`) -> FAB + Thêm -> fill `UserFormDialog` (email, role, status, password) -> POST `/api/v1/users`. Edit/Disable/Delete rows
4. Sidebar -> Tạo campaign -> fill `CampaignFormDialog` -> POST `/api/v1/campaigns` -> `NotificationTriggerService.campaignCreated` fires
5. Detail campaign -> Tạo event (`EventFormDialog`) -> assign school (Gán) + assign employee
6. Student self-register via `/student/register/:campaignId` -> registration lands in staff dashboard
7. Manage notifications (audit, FCM token test, broadcast)
8. Generate PDF: Báo cáo -> Campaign/Event/School/Region -> fill form -> PDF appears in `/reports` history

#### B. Manager flow
Same as Admin except no `/admin/users`. Owns reports list and broadcast notifications.

#### C. Staff flow
1. Login -> `/home/staff` shows KPI of events/interactions/schools visited
2. Sidebar -> Duyệt đơn (`/staff/registrations`) — paged list with text search, status filter, multi-select. Per-row actions: phone/email (clipboard on web), Approve/Reject. Bulk approve/reject up to 200 IDs
3. Campaign -> Event -> Trường tab — search school, gán/bỏ gán (read-only assignment list, manager-only mutators)
4. Notifications tab — view interactions; create new interaction (STAFF allowed)
5. Mark own avatar via /profile

#### D. Student flow (new in feat-077 / feat-077 Part2)
1. Login `student@vnmap.local` / `Admin@123` -> `/home/student` (KPI: my registrations, approved count)
2. Sidebar -> Tổng quan + Đăng ký của tôi
3. Campaigns -> Đăng ký per card -> navigates to `/student/register-event/:campaignId`
4. Form: họ tên (from email prefix), email disabled, phone, school dropdown (school picker), grade/class, note -> submit -> invalidates `myRegistrationsProvider` -> goes to `/student/my-registrations`
5. `/student/my-registrations` shows status chips (PENDING / APPROVED / REJECTED)
6. School picker has its own search filter; school list also reachable from /map
7. Profile: edit họ tên + số điện thoại; same avatar+password flow as everyone else

#### E. Cross-cutting — Notifications
1. `messaging_service.dart` registers token to `/api/v1/notifications/token` on app start (after permission prompt)
2. Server `NotificationTriggerService.dailyEventReminders` fires at 7 AM Asia/Saigon
3. In-app `NotificationBellButton` polls `notificationUnreadCountProvider`; bell opens preview modal; row tap deep-links via `triggerType + data.eventId/campaignId`
4. `markRead` / `read-all` audited against the caller

### 3.3 Form fields summary

| Page | Fields |
|------|--------|
| Login | email + password |
| Student self-register | schoolUid, fullName, email, phone, password (min 8), grade, className, note |
| Event registration (student) | fullName, email (disabled), phone, school dropdown, grade, className, note |
| Profile: edit info | fullName (required, max 255), phone (regex, only students) |
| Profile: change password | currentPassword, newPassword (min 8), confirm |
| Profile: avatar (web only) | file input -> bytes -> MinIO |
| Campaign form | name, status, objective, startDate, endDate, ownerEmployeeId |
| Event form | name, eventType, status, startsAt, endsAt, locationLabel, latitude (8.0-23.5), longitude (102.0-109.5), schoolUid, provinceCode, note |
| User form | email, password, role, status, employeeId, studentId |
| Reports: Campaign | campaignId, fromDate, toDate |
| Reports: Event | campaignId, eventType, employeeId |
| Reports: School | schoolUid, provinceCode |
| Reports: Region | provinceCode, fromDate, toDate |

---

## 4. Flutter repositories & viewmodels

### 4.1 Repositories

| Class | Provider | Methods -> Endpoint |
|-------|----------|---------------------|
| `AuthRepository` | `authRepositoryProvider` | login /me logout googleSignIn hasAccessToken updateProfile changePassword registerWithPassword |
| `CampaignRepository` | `campaignRepositoryProvider` | 31 methods covering `/campaigns`, `/events`, `/employees`, `/student-registrations`, `/users` |
| `NotificationRepository` | `notificationRepositoryProvider` | listMy, unreadCount, markRead, markAllRead |
| `ReportRepository` | `reportRepositoryProvider` | createCampaignPdf, getReport, getDownloadUrl, getCampaigns, getSchools, getEmployees |
| `StorageRepository` | `storageRepositoryProvider` | generateUploadUrl + direct PUT to MinIO |
| `SchoolsRepository` | `schoolsRepositoryProvider` | searchSchools, getSchool, getSchoolCoordinates, getSchoolCoordinate, updateSchoolCoordinates |
| `WeatherRepository(Impl)` | `weatherRepositoryProvider` | getCurrentWeather, getWeatherByUnit |
| `AnalyticsRepository` | `analyticsRepositoryProvider` | getAggregateDashboard, getInteractionsTrend, getChannelBreakdown, getTopEmployees, getCampaignDashboard, getCampaigns, getSchools |
| `GeoRepository(Impl)` | `geoRepositoryProvider` | provinces / boundaries / communes / reverse-geocode / committees |
| `OsmGeocodingRepository` | `osmGeocodingRepositoryProvider` | geocodeSchools (`POST /schools/geocode`) |
| `LocationRepository(Impl)` | `locationRepositoryProvider` | device GPS only |

### 4.2 ViewModels

| Class | State type | Notable methods | Provider |
|-------|-----------|-----------------|----------|
| `AuthViewModel` | sealed `AuthViewState` | loginWithPassword, loginWithGoogle, registerWithPassword, logout | `authViewModelProvider` |
| `ProfileViewModel` | `ProfileState` (`isUploading`, `isUpdatingPassword`, `isUpdatingInfo`) | uploadAvatarBytes, changePassword, updateInfo, clearMessages | `profileProvider` |
| `CampaignReportViewModel` | `AsyncValue<ReportExport?>` | export + 2-second polling; downloadUrl | `campaignReportViewModelProvider` |
| `MapOptimizationProvider` | `MapOptimizationState` | setProgressiveLoading, setMarkerClustering, setTileCacheSize, setSimplifiedGeometry, setZoomLevel | `mapOptimizationProvider` |
| `ThemeModeNotifier` | `ThemeMode` | toggleTheme, setTheme | `themeModeProvider` |
| `LocaleNotifier` | `Locale` | setLocale, toggleLocale | `localeProvider` |
| `RemoteConfigNotifier` | `RemoteConfigSnapshot` | refresh | `remoteConfigProvider` |
| `AnalyticsConsentNotifier` | `bool` | setConsent | `analyticsConsentProvider` |

Pure `FutureProvider` / `StateProvider` no-notifier classes:
- `campaignsProvider`, `campaignDashboardProvider(int)`, `campaignEventsProvider(int)`, `eventDetailProvider(int)`, `eventInteractionsProvider(int)`, `eventSchoolsProvider(int)`, `eventAssignmentsProvider(int)`, `campaignRegistrationsProvider(int)`, `myRegistrationsProvider`, `employeesProvider`, `usersProvider`
- `schoolsSearchProvider(params)`, `schoolDetailProvider(uid)`
- `aggregateDashboardProvider(filter)`, `trendProvider(filter)`, `channelProvider(filter)`, `employeeProvider(filter)`
- `staffRegistrationsFilterProvider`, `staffRegistrationsProvider` (both autoDispose)
- `notificationUnreadCountProvider`, `recentNotificationsProvider`
- `adminHomeProvider`, `managerHomeProvider`, `staffHomeProvider`, `studentHomeProvider`, `availableCampaignsProvider`
- `weatherByCoordinatesProvider(coords)`, `selectedWeatherLocationProvider`, `activeWeatherLocationProvider`, `selectedWeatherProvider`
- `reportCampaignsProvider`, `reportEmployeesProvider`, `reportSchoolsProvider(provinceCode)`

---

## 5. Quick test suites by role (run now)

### 5.1 Prerequisites

All services up: `vnmap_backend` healthy. From `AGENTS.md`:

```
docker ps | grep vnmap_backend
# Should be "Up X minutes (healthy)"
```

### 5.2 Seed users (passwords from `migration_firebase_uid.sql` etc.)

| Email | Role | Password |
|-------|------|----------|
| `admin@vnmap.local` | ADMIN | `Admin@123` |
| `manager@vnmap.local` | MANAGER | `Admin@123` |
| `staff@vnmap.local` | STAFF | `Admin@123` |
| `student@vnmap.local` | STUDENT | `Admin@123` |
| `siesta.6107@gmail.com` | STUDENT | (Firebase) |
| `student1@vnmap.local` | STUDENT | `Admin@123` |

### 5.3 Existing smoke script

`smoke_post_20260702.py` at repo root — runs 33 end-to-end checks across all 4 roles. Run with `py -3 smoke_post_20260702.py`. Currently 27/33 pass; the 6 "failures" are all expected behaviors (duplicate guards / same-password rejection / concurrent report guard).

### 5.4 Hand-written cURL matrix (copy-pasteable)

Auth + profile:

```bash
# Login
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@vnmap.local","password":"Admin@123"}'
# Capture .data.accessToken into $TOK

# Me
curl http://localhost:8080/api/v1/auth/me -H "Authorization: Bearer $TOK"

# Update profile (fullName + phone)
curl -X PUT http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer $TOK" \
  -H "Content-Type: application/json" \
  -d '{"fullName":"Updated Name","phone":"0900000099"}'

# Change password (must differ from current)
curl -X PUT http://localhost:8080/api/v1/auth/me/password \
  -H "Authorization: Bearer $TOK" \
  -H "Content-Type: application/json" \
  -d '{"currentPassword":"Admin@123","newPassword":"NewStrong123"}'
```

Permissions:

```bash
# Anonymous should get 401
curl -o /dev/null -w '%{http_code}\n' http://localhost:8080/api/v1/auth/me
# Expected: 401

# Student should be denied 403 on /users
TOK_STUDENT=$(curl -s -X POST .../auth/login \
   -d '{"email":"student@vnmap.local","password":"Admin@123"}' | jq -r .data.accessToken)
curl -o /dev/null -w '%{http_code}\n' http://localhost:8080/api/v1/users \
   -H "Authorization: Bearer $TOK_STUDENT"
# Expected: 403

# Unknown route should be 404
curl -o /dev/null -w '%{http_code}\n' \
   -H "Authorization: Bearer $TOK" http://localhost:8080/api/v1/this-route-does-not-exist
# Expected: 404
```

Reports end-to-end:

```bash
TOK_ADMIN=$(curl -s -X POST .../auth/login -d '{"email":"admin@vnmap.local","password":"Admin@123"}' | jq -r .data.accessToken)
RID=$(curl -s -X POST http://localhost:8080/api/v1/reports/campaigns/pdf \
  -H "Authorization: Bearer $TOK_ADMIN" -H "Content-Type: application/json" \
  -d '{"reportType":"CAMPAIGN","campaignId":1,"fromDate":"2026-01-01","toDate":"2026-12-31"}' \
  | jq -r .data.reportId)

# Poll
for i in $(seq 1 30); do
  STATUS=$(curl -s http://localhost:8080/api/v1/reports/$RID \
    -H "Authorization: Bearer $TOK_ADMIN" | jq -r .data.status)
  echo "$i $STATUS"
  [ "$STATUS" = "READY" ] && break
  sleep 2
done

# Download
URL=$(curl -s http://localhost:8080/api/v1/reports/$RID/download-url \
  -H "Authorization: Bearer $TOK_ADMIN" | jq -r .data.downloadUrl)
curl -s "$URL" -o /tmp/r.pdf
file /tmp/r.pdf
# Expected: "PDF document, version 1.5" or similar
```

Staff registration approval:

```bash
TOK_STAFF=$(... staff login ...)
curl 'http://localhost:8080/api/v1/staff/student-registrations?page=0&limit=10' \
  -H "Authorization: Bearer $TOK_STAFF"

# Bulk approve 3 IDs
curl -X POST http://localhost:8080/api/v1/student-registrations/bulk-status \
  -H "Authorization: Bearer $TOK_STAFF" -H "Content-Type: application/json" \
  -d '{"ids":[1,2,3],"status":"APPROVED"}'
```

Notifications:

```bash
curl -X POST http://localhost:8080/api/v1/notifications/token \
  -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" \
  -d '{"token":"fake-fcm-token-for-test","platform":"WEB"}'

curl http://localhost:8080/api/v1/notifications/unread-count \
  -H "Authorization: Bearer $TOK"

curl -X POST http://localhost:8080/api/v1/notifications/read-all \
  -H "Authorization: Bearer $TOK"
```

Schools + map:

```bash
curl "http://localhost:8080/api/v1/schools?page=0&limit=20&q=Bach%20Khoa" \
  -H "Authorization: Bearer $TOK"

curl http://localhost:8080/api/v1/schools/coordinates \
  -H "Authorization: Bearer $TOK"

curl http://localhost:8080/api/v1/schools/01-001 -H "Authorization: Bearer $TOK"

# Public endpoints
curl http://localhost:8080/api/v1/geo/provinces
curl "http://localhost:8080/api/v1/geo/reverse?lat=21.028&lng=105.854"
curl "http://localhost:8080/api/v1/weather?lat=21.028&lng=105.854"
```

Storage MinIO upload:

```bash
URL_INFO=$(curl -s -X POST http://localhost:8080/api/v1/storage/upload-url \
  -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" \
  -d '{"folder":"avatars","fileName":"test.png","contentType":"image/png","userId":"1"}')
UPLOAD_URL=$(echo $URL_INFO | jq -r .data.uploadUrl)

# PUT directly to MinIO
curl -X PUT "$UPLOAD_URL" -H "Content-Type: image/png" --data-binary @/path/to/file.png

# Save on user
curl -X PUT http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer $TOK" -H "Content-Type: application/json" \
  -d "$(echo $URL_INFO | jq '.data | {avatarObjectKey: .storagePath}')"
```

### 5.5 Playwright / browser checklist

Frontend (web): `http://localhost:8081` (assuming front container)

1. **Login** as each role -> lands at correct `/home/<role>`
2. **Sidebar** items match role (use `_navItemsFor(role)` helper)
3. **Profile** edit họ tên -> save -> reload `/auth/me` shows new value
4. **Profile** change password -> backend enforces new != current
5. **Profile** avatar (web only) -> MinIO URL works in Network tab
6. **Staff page** search by name/phone -> result filters; bulk approve 3 rows
7. **Reports page** fill campaign form -> PENDING -> READY -> download PDF
8. **Student self-register** via public `/student/register/:id` -> lands in staff dashboard
9. **Notifications bell** badge updates after broadcast

---

## 6. Cross-cutting concerns (worth testing)

### 6.1 Auth filter chain (`SecurityConfig`)
- Public paths: `/api/v1/auth/login|refresh|register|google`, `/api/v1/geo/**`, `/api/v1/weather/**`, `/api/analytics/**`, `/actuator/health`, swagger
- Authenticated read: `/auth/me`, `/notifications/**`, `/storage/**`, `/schools/{coord...}` list-only paths, `/student-registrations/my`, `/campaigns` (read), `/events` (read)
- MANAGER/ADMIN write: campaigns, events, students, persons, relatives, users (write), reports, school coordinates, school geocode
- STAFF/MANAGER/ADMIN: events interactions (read+write), assignments (read), staff/student-registrations, analytics page FE
- STUDENT: read-only on campaigns/events/schools, self-register

### 6.2 Error mapping (`GlobalExceptionHandler`)

| Exception | Status |
|-----------|--------|
| `ResourceNotFoundException` | 404 |
| `MethodArgumentNotValidException` | 400 with validationErrors{} map |
| `MissingServletRequestParameterException` | 400 |
| `MethodArgumentTypeMismatchException` | 400 |
| `IllegalArgumentException` | 400 |
| `ConstraintViolationException` | 400 |
| `ResponseStatusException` | propagates |
| `NoResourceFoundException` | 404 (route mismatch for GET) |
| `ExternalApiException` | 502 (weather/geocode upstream fail) |
| Anything else | 500 with generic message |

Note: Spring's `HttpRequestMethodNotSupportedException` (wrong-method) is NOT explicitly handled; falls through to the generic `Exception.class` handler and returns 500. If you want to assert 405 vs 500, write a test.

### 6.3 Background jobs
- `NotificationTriggerService.dailyEventReminders` — runs at 7 AM Asia/Saigon
- `CampaignReportService.cleanupReports` — PENDING -> FAILED after 10 min; READY deleted after 90 days
- Cache TTLs: weather 30 min, MinIO presigned URLs 15 min

### 6.4 Multi-tenant scoping
- `AuthService` issues one user per email (case-insensitive lookup)
- `listRegistrationsForStaff` scopes by STAFF assigned events/schools; MANAGER sees own created; ADMIN sees all
- `listReports` — MANAGER sees own only; ADMIN sees all
- `sendBroadcast` mirrors `notification_audit` row per ACTIVE user

### 6.5 Concurrency guards (test by hitting twice)
- `createCampaignReport` — one PENDING per user -> second call returns 409
- Student registration — duplicate per `(campaignId, studentId)` -> 409
- `updateUser` (email change) — duplicate email -> 409

### 6.6 Known smoke-test quirks (not bugs)
- 400 "must be a well-formed email address" if you POST login with `username` field (DTO only accepts `email`)
- 400 "New password must be different" if `currentPassword == newPassword`
- 409 on duplicate report / duplicate registration / concurrent report per user
- `PUT /auth/me` with empty `fullName` (whitespace) -> 400 (validation works, just trim)

---

## Appendix A — Test scripts and reports in repo
- `smoke_post_20260702.py` — comprehensive automated smoke (root of repo)
- `verify_feat_082.py` — MinIO migration verifier (root)
- `docs/MVVM_CONVENTION.md` — FE architecture convention
- `docs/PROJECT_CONTEXT.md` — overall architecture
- `AGENTS.md` — agent workflow, services list, evidence format
- `feature_list.json` — feature state tracker (feats 077-083 completed)
- `progress.md` — session log including today's feat-083 entry

## Appendix B — What is NOT in scope today (intentionally)
- `POST /api/v1/auth/register` declared permitAll in SecurityConfig but has no controller — returns 404
- `POST /api/v1/geo/admin/calculate-centroids` is permitAll but mutates data (should likely require MANAGER)
- `RegisterPage` exists but is not registered in router
- `ProvinceDetailPage` exists but is not registered in router
- `CampaignsTempPage`, `SchoolsTempPage` debug pages not in router
- "Auto-grading" from earlier notes (low-pri `knownIssue`) — never implemented
- Email and SMS reminders beyond FCM (out of scope)