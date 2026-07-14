# VN Map Campaign Module — Project Documentation

> Last updated: 2026-07-01 | Flutter Web + Spring Boot stack

---

## 1. Project Overview

**VN Map Campaign Module** is a full-stack application for managing outreach campaigns across Vietnam's administrative geography. It tracks schools, campaign events, staff assignments, student registrations, and interaction outcomes — visualized on an interactive Vietnam map.

| Attribute | Value |
|-----------|-------|
| **Type** | Full-stack web application (Flutter Web + Spring Boot) |
| **Domain** | Campaign management & school outreach |
| **Language** | Dart (FE) + Java 21 (BE) |
| **Location** | `D:\Project 2026\Flutter Project\PRM393\CP1_RE` |
| **Repository** | Git at `D:/Project 2026/Flutter Project/PRM393/CP1_RE` |

---

## 2. Technology Stack

### 2.1 Frontend (Flutter Web)

**Location:** `FE/`

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Flutter SDK | ≥ 3.3.0 |
| State Management | flutter_riverpod | ^2.5.1 |
| HTTP Client | dio | ^5.4.3 |
| Routing | go_router | ^14.2.7 |
| Map | flutter_map + flutter_map_marker_cluster | ^7.0 / ^1.3 |
| Charts | fl_chart | ^0.69.0 |
| Geolocation | geolocator | ^14.0.2 |
| Localization | flutter_localizations + intl | SDK / ^0.20.2 |
| Env Config | flutter_dotenv | ^5.1.0 |
| Persistence | shared_preferences | ^2.2.3 |
| Data Tables | data_table_2 | ^2.7.2 |
| Code Gen | freezed, json_serializable, riverpod_generator | ^2.5.x |

**Build & Run:**
```bash
cd FE
flutter pub get
flutter analyze
flutter run -d chrome
flutter build web --release   # outputs to FE/build/web/
```

### 2.2 Backend (Spring Boot)

**Location:** `BE/`

| Category | Technology | Version |
|----------|-----------|---------|
| Framework | Spring Boot | 3.3.2 |
| Language | Java | 21 |
| Build Tool | Maven | — |
| ORM | Hibernate Spatial + JdbcTemplate (hybrid) | — |
| Database | PostgreSQL + PostGIS | — |
| Cache | Redis | 7 |
| Auth | Custom JWT (HS256, no library) | — |
| API Docs | SpringDoc OpenAPI | 2.5.0 |
| HTTP Client | WebClient (reactive, for OWM) | — |

**Build & Run (Docker):**
```bash
cd BE
docker-compose up --build
# Backend: http://localhost:8080
# Swagger UI: http://localhost:8080/swagger-ui.html
```

---

## 3. Infrastructure

### 3.1 Docker Services

All services are defined in `BE/docker-compose.yml`:

| Service | Host Port | Internal Port | Notes |
|---------|-----------|---------------|-------|
| `vnmap_postgres` | **15432** | 5432 | PostgreSQL + PostGIS. Healthcheck enabled. |
| `vnmap_redis` | **6379** | 6379 | Redis 7, password `redis123`. |
| `backend` | **8080** | 8080 | Spring Boot. Healthcheck on `/actuator/health`. |
| `import` | — | — | Python script, loads GADM PostGIS data (runs once). |
| `campaign-import` | — | — | Python script, imports `Truong_THPT_2026_import_ready.xlsx`. |
| `sample-data` | — | — | SQL inserts for campaigns/events/interactions. |
| `sonarqube` | 9000 | 9000 | Community edition (optional). |

### 3.2 Environment Variables

**Backend** (`BE/.env` or docker-compose environment):

| Variable | Default | Description |
|----------|---------|-------------|
| `DB_HOST` | `vnmap_postgres` | PostgreSQL hostname |
| `DB_PORT` | `5432` | PostgreSQL port |
| `DB_NAME` | `vnmapdb` | Database name |
| `DB_USERNAME` | `postgres` | DB username |
| `DB_PASSWORD` | `123456` | DB password |
| `REDIS_HOST` | `localhost` | Redis hostname |
| `REDIS_PORT` | `6379` | Redis port |
| `REDIS_PASSWORD` | *(empty)* | Redis password |
| `OWM_API_KEY` | *(empty)* | OpenWeatherMap API key |
| `APP_PORT` | `8080` | Backend server port |

**Frontend** (`FE/.env`):

| Variable | Value | Description |
|----------|-------|-------------|
| `API_BASE_URL` | `http://localhost:8080` | Backend base URL |
| `ENV_MODE` | `development` | `development` / `production` |

---

## 4. Database Schema

### 4.1 Campaign Domain Tables (managed via `campaign-module.sql`)

| Table | Primary Key | Description |
|-------|-----------|-------------|
| `schools` | `school_uid` (UUID) | Schools participating in campaigns |
| `employees` | `id` | Staff members |
| `app_users` | `id` | Auth users (BCrypt password, FK to employee/student) |
| `refresh_tokens` | `id` | Refresh tokens (SHA-256 hashed, DB-backed) |
| `campaigns` | `id` | Campaigns (soft-delete via `status = ARCHIVED`) |
| `campaign_events` | `id` | Events within campaigns |
| `event_schools` | `(event_id, school_uid)` | Many-to-many event-school assignments |
| `event_assignments` | `(event_id, employee_id)` | Many-to-many event-staff assignments |
| `students` | `id` | Student records |
| `persons` | `id` | Generic persons (staff/contact) |
| `student_relatives` | `id` | Student family contacts |
| `interactions` | `id` | Campaign interactions (by channel/outcome) |
| `campaign_student_registrations` | `id` | Student-to-campaign registrations |
| `school_import_warnings` | `id` | Import validation warnings |

### 4.2 Geographic Tables (managed via `docker-init.sql`)

| Table | Primary Key | Description |
|-------|-----------|-------------|
| `administrative_units` | `id` | GADM Vietnam provinces + communes. `kind` = `province`/`commune`. Contains PostGIS `GEOMETRY` boundary and `Point` centroid. |
| `committee_locations` | `id` | Party committee locations by province. |

### 4.3 Key Indexes

- `idx_boundary_gist` / `idx_centroid_gist` — GIST spatial indexes on `administrative_units`
- `idx_schools_lat_lng` — partial index on `latitude, longitude WHERE NOT NULL`
- `idx_interactions_campaign/event/school/outcome` — query performance
- `idx_unit_kind`, `idx_unit_code`, `idx_unit_parent_code`, `idx_unit_macro_region`

---

## 5. API Reference

**Base URL:** `http://localhost:8080`
**Auth:** Bearer JWT in `Authorization` header (except public routes)
**Response format:** `{ "success": true, "message": "...", "data": {...}, "timestamp": "...", "traceId": "..." }`

### 5.1 Authentication — `/api/v1/auth`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/login` | Public | Login with email/password → `{ accessToken, refreshToken, user }` |
| POST | `/refresh` | Public | Refresh tokens (body: `{ refreshToken }`) |
| POST | `/logout` | Authenticated | Revoke refresh token |
| GET | `/me` | Authenticated | Get current user info |

### 5.2 Schools — `/api/v1/schools`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | Auth | List all schools (paginated) |
| GET | `/{schoolUid}` | Auth | Get school detail |
| GET | `/coordinates` | Auth | Get all schools with lat/lng |
| GET | `/{schoolUid}/coordinates` | Auth | Get single school coordinates |
| PUT | `/{schoolUid}/coordinates` | MANAGER/ADMIN | Update school lat/lng |
| POST | `/coordinates/compute` | MANAGER/ADMIN | Bulk-compute coordinates from OSM |
| POST | `/geocode` | Auth | On-demand geocode via OSM (does **not** save to DB) |

### 5.3 Employees — `/api/v1/employees`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | Auth | List employees |
| POST | `/` | ADMIN | Create employee |
| PUT | `/{id}` | ADMIN | Update employee |
| DELETE | `/{id}` | ADMIN | Delete employee |

### 5.4 Campaigns — `/api/v1/campaigns`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | Public | List campaigns |
| POST | `/` | MANAGER/ADMIN | Create campaign |
| GET | `/{id}` | Auth | Get campaign detail |
| PUT | `/{id}` | MANAGER/ADMIN | Update campaign |
| DELETE | `/{id}` | MANAGER/ADMIN | Archive campaign (soft delete) |
| GET | `/{id}/dashboard` | Auth | Campaign dashboard data |

### 5.5 Events — `/api/v1/events` (also `/api/v1/campaigns/{id}/events`)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/campaigns/{id}/events` | Auth | List events for campaign |
| POST | `/campaigns/{id}/events` | MANAGER/ADMIN | Create event |
| GET | `/events/{eventId}` | Auth | Event detail |
| PUT | `/events/{eventId}` | MANAGER/ADMIN | Update event |
| DELETE | `/events/{eventId}` | MANAGER/ADMIN | Archive event |
| POST | `/events/{eventId}/schools` | MANAGER/ADMIN | Assign schools to event |
| DELETE | `/events/{eventId}/schools/{schoolUid}` | MANAGER/ADMIN | Remove school |
| GET | `/events/{eventId}/schools` | Auth | List assigned schools |
| POST | `/events/{eventId}/assignments` | MANAGER/ADMIN | Assign staff |
| DELETE | `/events/{eventId}/assignments/{employeeId}` | MANAGER/ADMIN | Remove staff |
| GET | `/events/{eventId}/assignments` | Auth | List staff assignments |

### 5.6 Interactions — `/api/v1/events/{eventId}/interactions`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | Auth | List interactions |
| POST | `/` | Auth | Create interaction |
| PUT | `/{interactionId}` | Auth | Update interaction |
| DELETE | `/{interactionId}` | Auth | Delete interaction |

### 5.7 Student Registrations — `/api/v1/campaigns/{id}/student-registrations`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/` | Public | Student self-registration |
| GET | `/` | MANAGER/ADMIN | List registrations |
| GET | `/student-registrations/my` | STUDENT | My registrations |
| PUT | `/student-registrations/{id}/status` | MANAGER/ADMIN | Update status (PENDING/APPROVED/REJECTED/CANCELLED) |

### 5.8 Users — `/api/v1/users`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | ADMIN | List users |
| POST | `/` | ADMIN | Create user |
| PUT | `/{id}` | ADMIN | Update user |
| PUT | `/{id}/role` | ADMIN | Change user role |
| PUT | `/{id}/status` | ADMIN | Enable/disable user |

### 5.9 Analytics — `/api/analytics`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/aggregate` | Auth | Aggregate KPIs (with optional `?campaignId=` / `?schoolUid=` filters) |
| GET | `/trend?days=N` | Auth | Daily interaction counts for N days |
| GET | `/channels` | Auth | Breakdown by interaction channel |
| GET | `/employees` | Auth | Top employees by interaction volume |

### 5.10 Geography — `/api/v1/geo`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/provinces` | Public | List all provinces |
| GET | `/provinces/{code}/boundary` | Public | GeoJSON boundary for province |
| GET | `/provinces-boundaries` | Public | All province boundaries at once |
| GET | `/provinces/{code}/communes` | Public | Communes in province |
| GET | `/provinces/{code}/communes-boundaries` | Public | All commune boundaries |
| GET | `/provinces/{code}/communes-paginated` | Public | Paginated communes |
| GET | `/units/{code}` | Public | Administrative unit by code |
| GET | `/units/{code}/boundary` | Public | Boundary by unit code |
| GET | `/reverse?lat=&lng=` | Public | Reverse geocode (point → unit) |
| GET | `/committees` | Public | Party committee locations |
| GET | `/committees/{provinceCode}` | Public | Committees by province |

### 5.11 Weather — `/api/v1/weather`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/` | Public | Current weather (OpenWeatherMap) |
| GET | `/unit/{unitCode}` | Public | Weather for administrative unit centroid |

---

## 6. Security & Authorization

### 6.1 Roles

| Role | Description |
|------|-------------|
| `ADMIN` | Full system access, user management |
| `MANAGER` | Campaign/event CRUD, staff assignments |
| `STAFF` | View campaigns/events, log interactions |
| `STUDENT` | Self-registration, view own registrations |

### 6.2 Public Routes (no auth required)

```
/api/v1/auth/login
/api/v1/auth/refresh
/actuator/health
/swagger-ui/**
/api-docs/**
GET /api/v1/campaigns/**
POST /api/v1/campaigns/*/student-registrations
/api/v1/geo/**
/api/v1/weather/**
/api/analytics/**  (GET only)
```

### 6.3 JWT Token Details

- **Algorithm:** HS256 (custom implementation, no library)
- **Claims:** `sub` (userId), `email`, `role`, `status`, `employeeId`, `studentId`, `iat`, `exp`
- **Access token TTL:** Configurable (default: 1 hour)
- **Refresh token TTL:** Configurable (default: 7 days)
- **Storage:** Access token in Flutter `shared_preferences`; Refresh token in DB (SHA-256 hashed)
- **Rotation:** Each `/refresh` call revokes old refresh token and issues a new one

### 6.4 CORS

| Profile | Allowed Origins |
|---------|---------------|
| dev | `localhost:3000`, `localhost:8080`, `10.0.2.2:8080` |
| prod | `CORS_ALLOWED_ORIGINS` env var (default: `http://localhost:8080`) |

---

## 7. Frontend Architecture

### 7.1 Project Structure

```
FE/lib/
├── main.dart                          # App entry point, ProviderScope
├── app/
│   ├── router.dart                    # GoRouter config, _AppShell, _RoleGate
│   └── widgets/
│       ├── app_shell_scaffold.dart    # Responsive shell (sidebar/drawer)
│       └── app_sidebar.dart           # Collapsible sidebar nav
├── core/
│   ├── config/
│   │   └── app_config.dart            # baseUrl from dart-define > .env > localhost
│   ├── constants/
│   │   └── api_constants.dart         # API endpoint constants
│   ├── errors/
│   │   └── failures.dart              # Failure classes (left side of Either)
│   ├── network/
│   │   ├── api_exception.dart         # ApiException with status codes
│   │   ├── api_interceptors.dart      # LoggingInterceptor, ErrorInterceptor
│   │   ├── api_response.dart          # Generic API response wrapper
│   │   └── dio_client.dart            # Dio singleton + 4 interceptors
│   ├── providers/
│   │   ├── locale_provider.dart       # i18n locale state
│   │   └── theme_provider.dart         # light/dark/themeMode state
│   ├── theme/
│   │   ├── app_colors.dart            # Soft Minimalism palette
│   │   ├── app_shadows.dart           # Shadow definitions
│   │   ├── app_spacing.dart           # 4px base + breakpoints
│   │   ├── app_theme.dart             # Light/dark ThemeData
│   │   └── app_typography.dart        # Typography scale
│   ├── utils/
│   │   ├── failure_mapper.dart        # Failure → user-friendly message
│   │   ├── geojson_utils.dart         # GeoJSON parsing helpers
│   │   ├── performance_utils.dart     # Debounce, throttling
│   │   ├── responsive.dart             # ResponsiveBuilder, ResponsiveGrid
│   │   └── result.dart                # Result type alias
│   └── widgets/
│       ├── app_error_widget.dart      # Error display widget
│       ├── bento_card.dart            # BentoCard, BentoGrid, KpiCard, StatusChip
│       ├── card_animation.dart        # Animated card wrapper
│       ├── glass_widgets.dart         # Glassmorphism components
│       ├── loading_widget.dart        # Loading indicator
│       ├── modern_bottom_sheet.dart   # Modern bottom sheet
│       └── shimmer_loading.dart       # Skeleton loading states
└── features/
    ├── admin/                         # User management (ADMIN only)
    ├── analytics/                     # Analytics dashboard + 6 chart types
    ├── auth/                          # Login, logout, token storage
    ├── campaign/                      # Campaign CRUD, events, dashboard
    ├── home/                          # Role-specific Bento home pages
    ├── location/                      # Geolocation use cases
    ├── map/                           # Vietnam map (flutter_map)
    ├── school/                        # School list, detail
    ├── settings/                      # Settings page
    ├── student/                       # Student self-registration
    └── weather/                       # Weather display
```

### 7.2 Design System

**Style:** Soft Minimalism + Bento Cards

**Color Palette:**
- Primary: Indigo `#6366F1`
- Secondary: Slate Gray `#64748B`
- Tertiary: Teal `#14B8A6`
- Surfaces: Muted warm grays (light) / Near-black (dark)
- Status: Success (green), Warning (amber), Error (red), Info (blue)

**Spacing:** 4px base unit
- Breakpoints: Mobile `<600`, Tablet `600–899`, Desktop `≥900`

**Components:** BentoCard, KpiCard, StatusChip, BentoGrid, glassmorphism overlays, shimmer skeletons

### 7.3 Routing

All routes use GoRouter with:
- **Shell route** (`ShellRoute`) for persistent sidebar navigation
- **Slide+fade transitions** (300ms, slide from right)
- **`_RoleGate`** widget for server-enforced role-based access
- **Auth guard** — redirects unauthenticated users to `/login`
- **Token auto-read** from `shared_preferences` at startup

| Route | Page | Access |
|-------|------|--------|
| `/login` | LoginPage | Public |
| `/student/register/:campaignId` | StudentRegisterPage | Public |
| `/map` | MapPage | Authenticated |
| `/weather` | WeatherPage | Authenticated |
| `/campaigns` | CampaignListPage | STAFF, MANAGER, ADMIN |
| `/campaigns/:campaignId/dashboard` | CampaignDashboardPage | STAFF, MANAGER, ADMIN |
| `/campaigns/:campaignId/events` | CampaignEventsPage | STAFF, MANAGER, ADMIN |
| `/events/:eventId` | EventDetailPage | STAFF, MANAGER, ADMIN |
| `/analytics` | AnalyticsPage | STAFF, MANAGER, ADMIN |
| `/schools` | SchoolListPage | STAFF, MANAGER, ADMIN |
| `/schools/:schoolUid` | SchoolDetailPage | STAFF, MANAGER, ADMIN |
| `/student/my-registrations` | MyRegistrationsPage | STUDENT |
| `/admin/users` | AdminUsersPage | ADMIN |
| `/home/manager` | ManagerHomePage | MANAGER, ADMIN |
| `/home/staff` | StaffHomePage | STAFF, MANAGER, ADMIN |
| `/home/student` | StudentHomePage | STUDENT |
| `/home/admin` | AdminHomePage | ADMIN |
| `/settings` | SettingsPage | Authenticated |
| `/logout` | LogoutPage | Public |

### 7.4 Network Layer (Dio Interceptors)

1. **`AuthTokenInterceptor`** — Adds `Bearer <token>` to all requests; auto-refreshes on 401
2. **`LoggingInterceptor`** — Logs request/response in debug mode
3. **`RetryInterceptor`** — Retries once on 5xx server errors
4. **`ErrorInterceptor`** — Converts Dio errors to `ApiException`

---

## 8. Feature Modules

### 8.1 Map (`/map`)

- **Vietnam base map** using OpenStreetMap tiles (flutter_map)
- **Province boundaries** rendered as GeoJSON polygons (PostGIS → GeoJSON)
- **Commune boundaries** loaded on demand per province
- **School markers** — color-coded by geocode status (exact/approximate/pending)
- **Marker clustering** via flutter_map_marker_cluster
- **SchoolInfoSheet** — bottom sheet with school details + "Show on Map" navigation
- **Light/dark tile switching** — CartoDB light/dark
- **Performance:** Bulk API (single call for all province boundaries), tile caching, progressive loading

### 8.2 Analytics (`/analytics`)

- **KPI cards** — total campaigns, events, schools, employees, interactions
- **Trend line chart** — daily interaction counts (configurable days)
- **Outcome donut chart** — interactions by outcome
- **Channel donut chart** — interactions by channel (PHONE/EMAIL/ZALO/VISIT/EVENT/MEETING)
- **Province bar chart** — top N provinces by interaction volume
- **Employee bar chart** — top N employees ranked by interactions
- **Collapsible sidebar** (280px expanded / 72px collapsed) — persisted in SharedPreferences
- **Filters:** Campaign selector + paginated school picker (50/page, search support)

### 8.3 Home Pages

Four role-specific Bento Grid dashboards:

**Admin** (`/home/admin`): 6 KPI cards, user role donut, campaign status breakdown, recent users list, system health, pending activations.

**Manager** (`/home/manager`): KPIs, trend line, activity feed, outcome donut, province bar, top schools, recent registrations.

**Staff** (`/home/staff`): KPIs, assigned events, personal trend bars, campaign breakdown, outcome donut.

**Student** (`/home/student`): KPIs, registration list, profile card, available campaigns.

### 8.4 Campaigns

- Campaign list with status filters
- Campaign dashboard with charts (outcome donut, province bar, top schools)
- Event management (CRUD, school assignment, staff assignment)
- Event detail with tabs: Info, Schools, Assignments, Interactions

### 8.5 Schools

- School list with search and pagination
- School detail with overview, events, interactions tabs
- Geocode status: EXACT / APPROXIMATE / PENDING
- "Show on Map" navigation with query params

### 8.6 Weather

- Current weather from OpenWeatherMap
- Weather by administrative unit (centroid lookup)
- 10-minute Redis cache

### 8.7 Auth

- Email/password login
- JWT access + refresh token
- Auto token refresh on 401
- Role-based route access (`_RoleGate`)

---

## 9. Completed Features (feature_list.json)

All 61 implemented features (feat-001 through feat-061) are **completed**. Key highlights:

| Feature | Description |
|---------|-------------|
| feat-027–033 | Design system foundation (Soft Minimalism + Bento Cards) |
| feat-034–041 | Testing infrastructure (pending: feat-034–041) |
| feat-042 | On-demand OSM geocoding (no DB write) |
| feat-043 | Aggregate analytics endpoint |
| feat-049 | 3 new analytics endpoints + chart types |
| feat-050 | Chart modernization (palette, tooltips, animations) |
| feat-051 | Collapsible analytics sidebar layout |
| feat-053 | Responsive sidebar navigation (desktop ≥900px) |
| feat-055 | Dark mode sweep across all UI |
| feat-056 | PaginatedDataTable2 for admin user management |
| feat-057 | Role-based Bento home pages |
| feat-061 | Paginated school picker for analytics filter |

---

## 10. Project Artifacts

| File | Purpose |
|------|---------|
| `feature_list.json` | Feature state tracker — source of truth for implementation status |
| `progress.md` | Session continuity log — current state, recent fixes |
| `UI_UX_AUDIT_REPORT.md` | UI/UX audit findings with priority levels |
| `AGENTS.md` | Agent harness — workflow, verification commands, escalation |
| `FE/build/web/` | Production Flutter web build output |
| `BE/docker-compose.yml` | Full backend stack definition |

---

## 11. Known Issues (from UI_UX_AUDIT_REPORT.md)

| Priority | Issue | Status |
|----------|-------|--------|
| High | Tab switching bug in event_detail_page, school_detail_page | Fixed (feat-008, feat-009) |
| Medium | Corrupted Vietnamese text in weather_page | Fixed (feat-010) |
| Medium | Hardcoded campaign create in campaign_list_page | Fixed (feat-014) |
| Medium | Missing archive UI for events/campaigns | Fixed (feat-014) |
| Low | No page transitions | Fixed (feat-004, feat-053) |
| Low | Raw date/time display in event form | Fixed (feat-022) |
| High | RenderFlex unbounded-height errors in home pages | **Fixed** (2026-06-30) |

---

## 12. Quick Reference

```bash
# Backend health
curl http://localhost:8080/actuator/health

# Flutter analyze
cd FE && flutter analyze

# Flutter web build
cd FE && flutter build web --release

# View web build
cd FE/build/web && python -m http.server 3000

# Run Flutter dev server
cd FE && flutter run -d chrome

# Commit all changes
git add . && git commit -m "message"
```
