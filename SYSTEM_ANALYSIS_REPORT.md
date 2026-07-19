# System Analysis Report

## Document Information

| Item | Value |
| --- | --- |
| Project | VN Map Campaign Module / Bản đồ Việt Nam |
| Repository | `D:/Project 2026/Flutter Project/PRM393/CP1_RE` |
| Analysis date | 2026-07-17 |
| Runtime environment | Docker Compose; Flutter Web served by Nginx; Spring Boot backend |
| Scope | Source structure, routes, security configuration, controllers, and observable localhost UI |
| Limitations | Runtime screenshots cover Admin, Manager, Staff and Student flows at desktop viewport. Destructive mutations were not performed. Some Vietnamese place and school names lose diacritics in the current generated PDF rendering; the screenshots preserve that observed output. |

## Revision History

| Version | Date | Description |
| --- | --- | --- |
| 1.0 | 2026-07-15 | Initial current-state documentation. |
| 1.1 | 2026-07-17 | Added illustrated user-manual flows for Manager, Staff and Student, plus verified Campaign, Event, School and Region PDF evidence. |

## Table of Contents

- [1. Executive Overview](#1-executive-overview)
- [2. System Purpose](#2-system-purpose)
- [3. User Groups and Roles](#3-user-groups-and-roles)
- [4. Technology Stack](#4-technology-stack)
- [5. Repository Structure](#5-repository-structure)
- [6. Architecture, Authentication and Authorization](#6-architecture-authentication-and-authorization)
- [7. Navigation Sitemap and Screen Inventory](#7-navigation-sitemap-and-screen-inventory)
- [8. Detailed Screen Documentation](#8-detailed-screen-documentation)
- [9. User and Business Flows](#9-user-and-business-flows)
- [10. Data Model and API Inventory](#10-data-model-and-api-inventory)
- [11. UI, Form and Responsive Inventory](#11-ui-form-and-responsive-inventory)
- [12. Runtime Observations](#12-runtime-observations)
- [13. Source Reference Index](#13-source-reference-index)
- [14. Unverified Areas and Limitations](#14-unverified-areas-and-limitations)
- [20. Illustrated User Manual and PDF Export Evidence](#20-illustrated-user-manual-and-pdf-export-evidence)

# 1. Executive Overview

VN Map Campaign Module is a web application for campaign, school, event, student-registration, interaction, geography, weather, analytics, notification, and report operations. The running local stack exposes the web client at `http://localhost:3000`, the backend at `http://localhost:8080`, the OpenAPI UI at `http://localhost:8080/swagger-ui/index.html`, and MinIO at ports `9001` and `9002`.

The route configuration contains public login and campaign self-registration routes, then a shell-protected route tree. Source evidence identifies four application roles: `ADMIN`, `MANAGER`, `STAFF`, and `STUDENT`.

# 2. System Purpose

The project documentation describes a campaign-management system visualized on a Vietnam administrative map. It handles school outreach campaigns, events, staff assignments, student registrations, interactions, administrative units, reports, and user administration.

Core modules observed in source are Map and geographic data, Weather, Campaigns and Events, School directory, Analytics, Student registration, Staff registration review, Reports, Notifications, Profile, Settings, and Admin users.

# 3. User Groups and Roles

| Role | Default route | Available modules from route/sidebar source | Main actions | Runtime verified |
| --- | --- | --- | --- | --- |
| ADMIN | `/home/admin` | Map, profile, campaigns, analytics, registration review, schools, reports, users, settings | User administration; campaign/event CRUD; employee administration; reports | Yes |
| MANAGER | `/home/manager` | Map, profile, campaigns, analytics, registration review, schools, reports, settings | Campaign/event management, assignments, reports | Yes |
| STAFF | `/home/staff` | Map, profile, campaigns, analytics, registration review, schools, settings | Event interactions and registration-status operations | Yes |
| STUDENT | `/home/student` | Map, profile, campaigns, schools, own registrations, settings | Student event registration and own-registration viewing | Yes |

## Permission Matrix

| Function | Admin | Manager | Staff | Student |
| --- | ---: | ---: | ---: | ---: |
| Read campaigns, events, schools | Yes | Yes | Yes | Yes |
| Campaign dashboard | Yes | Yes | No | No |
| Create/update/delete campaigns and events | Yes | Yes | No | No |
| Record event interactions | Yes | Yes | Yes | No |
| Review registrations | Yes | Yes | Yes | No |
| Reports | Yes | Yes | No | No |
| User administration | Yes | No | No | No |
| Own registrations | Not verified | Not verified | Not verified | Yes |

# 4. Technology Stack

| Layer | Technology | Location in Repository | Responsibility |
| --- | --- | --- | --- |
| Frontend | Flutter Web, Dart, Riverpod, GoRouter, Dio | `FE/lib` | UI, state, routing, API access |
| Backend | Java 21, Spring Boot 3.3.2, Spring Security | `BE/src/main/java` | REST API, domain services, authorization |
| Database | PostgreSQL/PostGIS | Docker `postgres`; `BE/postgres` | Relational and geographic data |
| Cache | Redis 7 | Docker `redis`; backend config | Cache management |
| Storage | MinIO, custom SigV4 presigning | `BE/.../storage`, `BE/.../MinioConfig.java` | Avatar/report object paths and signed URLs |
| Authentication | JWT HS256; optional Google/Firebase path | `auth`, `common/security` | Login, refresh, current user, route/API authorization |
| Mapping | flutter_map; Geo API | `FE/lib/features/map`, `BE/.../geo` | Administrative boundaries and map data |
| Weather | OpenWeatherMap via backend service | `weather` | Current and unit weather data |
| Notifications | Firebase messaging and notification API | `notification`, Firebase config | Token registration, read state, sending |
| Containerization | Docker Compose, Nginx frontend image | `docker-compose.yml`, `FE/Dockerfile`, `BE/Dockerfile` | Local multi-service runtime |

# 5. Repository Structure

```text
CP1_RE/
├── FE/                         Flutter Web client
│   └── lib/features/            Feature-first UI, repositories, providers and pages
├── BE/                         Spring Boot application
│   ├── src/main/java/com/vnmap/ Controllers, services, DTOs, security and entities
│   ├── scripts/                Migration and seed SQL
│   └── postgres/               PostgreSQL image configuration
├── docs/                       MVVM convention and project documentation
├── docker-compose.yml          Root runtime orchestration
├── feature_list.json           Feature-state tracker
└── system-analysis-assets/     Report screenshots
```

| Path | Responsibility | Main contents | Related module |
| --- | --- | --- | --- |
| `FE/lib/app/router.dart` | Navigation and route guarding | GoRouter routes, shell, role gates | All client screens |
| `FE/lib/features` | Feature UI and state | Pages, widgets, repositories, providers | Product modules |
| `BE/.../campaign` | Campaign domain | Controller, DTOs, services | Campaigns, events, schools, registrations |
| `BE/.../auth` | Identity endpoints | Login, refresh, logout, profile | Authentication |
| `BE/.../common/config/SecurityConfig.java` | API authorization | Role matchers and JWT filter chain | Authorization |
| `docker-compose.yml` | Service wiring | Postgres, Redis, MinIO, backend, frontend | Runtime |

# 6. Architecture, Authentication and Authorization

```text
Flutter Web pages/providers
  → repositories/Dio HTTP client
  → Spring Boot controllers/services
  → PostgreSQL/PostGIS, Redis, MinIO, Firebase, OpenWeatherMap
```

The client reads an access token through `TokenStorage`; GoRouter redirects protected routes without a token to `/login`. The login flow posts to `/api/v1/auth/login`; the backend is stateless and places role, user identifier, employee identifier, and student identifier claims into a JWT. `SecurityConfig` applies API-level `hasRole` and `hasAnyRole` matchers. Source contains login, refresh, logout, current-user, profile update, password-change, and Google authentication operations.

Environment names observed include `API_BASE_URL`, `ENV_MODE`, Firebase configuration names, database names, Redis names, MinIO names, `OWM_BASE_URL`, `OWM_API_KEY`, and `FIREBASE_SERVICE_ACCOUNT_JSON`/`FIREBASE_SERVICE_ACCOUNT_FILE`. Values are intentionally excluded.

# 7. Navigation Sitemap and Screen Inventory

```text
Public
├── /login
└── /student/register/:campaignId
Authenticated shell
├── /home/admin | /home/manager | /home/staff | /home/student
├── /map and /weather
├── /campaigns
│   ├── /campaigns/:campaignId/dashboard
│   └── /campaigns/:campaignId/events → /events/:eventId
├── /schools → /schools/:schoolUid
├── /analytics
├── /staff/registrations
├── /student/register-event/:campaignId and /student/my-registrations
├── /reports, /reports/campaign, /reports/event, /reports/school, /reports/region
├── /admin/users
├── /profile and /settings
└── /logout
```

| ID | Screen | Route | Role | Module | Runtime verified |
| --- | --- | --- | --- | --- | --- |
| SCR-001 | Login | `/login` | Public | Authentication | Yes |
| SCR-002 | Student self-registration | `/student/register/:campaignId` | Public | Student | No |
| SCR-003–006 | Role home pages | `/home/{admin,manager,staff,student}` | Corresponding role | Home | No |
| SCR-007 | Map | `/map` | Authenticated | Map | No |
| SCR-008 | Weather | `/weather` | Authenticated | Weather | No |
| SCR-009 | Campaign list | `/campaigns` | All roles | Campaign | No |
| SCR-010 | Campaign dashboard | `/campaigns/:campaignId/dashboard` | Manager/Admin | Campaign | No |
| SCR-011 | Campaign events | `/campaigns/:campaignId/events` | All roles | Event | No |
| SCR-012 | Event detail | `/events/:eventId` | All roles | Event | No |
| SCR-013–014 | School list/detail | `/schools`, `/schools/:schoolUid` | All roles | School | No |
| SCR-015 | Analytics | `/analytics` | Staff/Manager/Admin | Analytics | No |
| SCR-016 | Registration review | `/staff/registrations` | Staff/Manager/Admin | Staff | No |
| SCR-017–018 | Student registration/my registrations | `/student/register-event/:campaignId`, `/student/my-registrations` | Student | Student | No |
| SCR-019–023 | Reports landing and four report types | `/reports/*` | Manager/Admin | Reports | No |
| SCR-024 | Admin users | `/admin/users` | Admin | Administration | No |
| SCR-025–027 | Profile, Settings, Logout | `/profile`, `/settings`, `/logout` | Authenticated | Auth/Settings | No |

# 8. Detailed Screen Documentation

## SCR-001 — Login

**Route:** `/login`. **Entry point:** initial route and protected-route redirect. **Runtime status:** rendered at desktop and mobile viewport before form submission.

The page contains an application mark, title “Bản đồ Việt Nam”, explanatory text, Email and Password fields, a “Đăng nhập” button, separator, and a Google login action. `LoginPage` delegates authentication to the auth view model/repository and redirects with `landingPathForRole` after success.

| Component | Type | Purpose | Data source | Interaction |
| --- | --- | --- | --- | --- |
| Email | text field | Login identifier | Form state | User entry |
| Password | obscured field | Login credential | Form state | User entry |
| Đăng nhập | primary button | Submit login | `/api/v1/auth/login` | Authentication attempt |
| Đăng nhập với Google | outlined button | Google authentication path | `/api/v1/auth/google` | External auth handoff |

![Login desktop](system-analysis-assets/screenshots/01-login-desktop.jpg)

**Figure 1.** Login screen at the default desktop browser viewport.

![Login mobile](system-analysis-assets/screenshots/02-login-mobile.jpg)

**Figure 2.** Login screen at 390 × 844 viewport. The rendered card/content extends beyond the captured horizontal viewport.

**Source reference:** `FE/lib/features/auth/presentation/pages/login_page.dart`, `FE/lib/features/auth/presentation/providers/auth_viewmodel.dart`, `FE/lib/features/auth/shared/repositories/auth_repository.dart`, `BE/.../auth/controller/AuthController.java`.

## SCR-002 — Student self-registration

**Route:** `/student/register/:campaignId`. **Role:** public route. **Purpose inferred from route and page name:** submit a student registration associated with a campaign. The backend operation is `POST /api/v1/campaigns/{campaignId}/student-registrations`. Runtime access was not reached in this run.

## SCR-003–006 — Role home pages

**Routes:** `/home/admin`, `/home/manager`, `/home/staff`, `/home/student`. Each route is protected by `_RoleGate`. The page files are `admin_home_page.dart`, `manager_home_page.dart`, `staff_home_page.dart`, and `student_home_page.dart`; their associated providers are in `features/home/data/providers`. Runtime content was not reached.

## SCR-007–008 — Map and Weather

**Routes:** `/map`, `/weather`. Map accepts optional latitude, longitude, event label, and school UID query parameters; it uses geographic repositories/providers and Geo endpoints for provinces, boundaries, communes, units, reverse geocoding, and committees. Weather has current and unit-specific backend operations. These screens use the authenticated shell; runtime UI was not reached.

## SCR-009–012 — Campaign, dashboard and event screens

**Routes:** `/campaigns`, `/campaigns/:campaignId/dashboard`, `/campaigns/:campaignId/events`, `/events/:eventId`. The campaign list supports student event-registration entry and conditionally exposes management based on role. Dashboard is gated to Manager/Admin at the client route. Event detail source includes school assignment, employee assignment and interaction-related UI. The controller provides campaign, event, assignment, school, and interaction operations. Runtime UI was not reached.

## SCR-013–016 — Schools, analytics and registration review

**Routes:** `/schools`, `/schools/:schoolUid`, `/analytics`, `/staff/registrations`. Schools are available to all defined roles; analytics and registration review are gated to Staff/Manager/Admin. Source references include `schools_provider.dart`, `analytics_provider.dart`, and `staff_registrations_provider.dart`. The matching backend endpoints include school listing/detail, aggregate analytics/trend/channel/employee operations, and staff registration listing/status operations.

## SCR-017–018 — Student event registration and own registrations

**Routes:** `/student/register-event/:campaignId`, `/student/my-registrations`. Both routes are client-gated to Student. The controller has create-registration and current-user-registration operations. Runtime UI was not reached.

## SCR-019–023 — Report screens

**Routes:** `/reports`, `/reports/campaign`, `/reports/event`, `/reports/school`, `/reports/region`. These screens are client-gated to Manager/Admin and use report view-model and filter providers. Backend report operations include campaign PDF export, report listing, report detail, and download URL retrieval. Report generation was not invoked because it may create an artifact.

## SCR-024 — Admin users

**Route:** `/admin/users`. **Role:** Admin. The page uses `UserAdminTable`; source contains role/status filtering and user create/edit/delete/role/status actions. Backend access to `/api/v1/users/**` is Admin-only. Runtime UI was not reached.

## SCR-025–027 — Profile, Settings and Logout

**Routes:** `/profile`, `/settings`, `/logout`. Profile source exposes user identity/role data and profile editing; current backend operations include `GET/PUT /api/v1/auth/me` and password update. Settings is routed without a client role gate. Logout is always publicly routable and uses the logout page. Runtime UI was not reached.

# 9. User and Business Flows

## FLOW-001 — Login

1. User opens `/login`.
2. User enters email and password or selects the Google action.
3. Client invokes authentication repository.
4. Backend validates and returns an authentication response containing user context and tokens.
5. Client stores access token and routes to the home route selected from the user role.

Failure presentation after an empty submit could not be documented because the observed runtime displayed a white page after the action.

## FLOW-002 — Student campaign registration

1. Student opens a campaign or self-registration route.
2. Student enters registration data.
3. Client posts to the campaign student-registration endpoint.
4. Backend validates role, campaign state, and date window before accepting registration.
5. Student can use the own-registration route to retrieve their registrations.

## FLOW-003 — Campaign event operations

1. Manager/Admin opens a campaign.
2. Campaign data and events are loaded.
3. Manager/Admin can create or modify campaigns/events and create school/employee assignments.
4. Staff/Manager/Admin can create, update, or delete event interactions.

## FLOW-004 — Report export

1. Manager/Admin opens the reports landing screen and chooses a report type.
2. Filter providers load campaign, event, school, region, or employee data as required by the selected form.
3. A campaign PDF operation can create a report job.
4. Report listing/detail/download URL operations expose report status and retrieval information.

## Business Flow — Campaign lifecycle

```text
Campaign created → events configured → schools/employees assigned
→ student registrations and event interactions recorded → analytics/report operations read campaign data
```

Campaign, campaign event, school, employee, student registration, and interaction DTOs/controllers provide the observable domain transitions. Exact status transition values were not exhaustively verified in runtime.

# 10. Data Model and API Inventory

| Entity/DTO area | Purpose | Related screens | Source |
| --- | --- | --- | --- |
| User/AuthUser | Identity, role, employee/student links and profile | Login, Profile, Admin Users | `auth/dto`, `auth/service` |
| Campaign/CampaignEvent | Campaign and event data | Campaign list/dashboard/events | `campaign/dto` |
| School/SchoolDetail | School directory and coordinates | Schools, Map, Campaigns | `campaign/dto` |
| StudentRegistration | Student campaign registration/status | Student and staff registration screens | `campaign/dto` |
| Interaction | Event outcome/interaction entry | Event detail, analytics | `campaign/dto` |
| AdministrativeUnit/CommitteeLocation | Vietnamese administrative map data | Map, Weather | `geo/entity`, `geo/dto` |
| Report export | Generated-report metadata and download URL | Reports | `report/dto` |
| Notification | FCM token and notification read state | Notification center/provider | `notification/dto` |

| API area | Operations observed | Authentication |
| --- | --- | --- |
| Auth | login, refresh, logout, me, profile update, password update, Google | login/refresh/Google public; remainder authenticated |
| Campaign | schools, employees, campaigns, events, assignments, interactions, registrations, users | Role matcher dependent |
| Geo/Weather | administrative units/boundaries/reverse/committees; weather | Geo/weather reads public in `SecurityConfig` |
| Analytics | aggregate, trend, channels, employees | Staff/Manager/Admin |
| Reports | campaign PDF, list, detail, download URL | Manager/Admin |
| Notifications | token, send, list, unread/read actions | Authenticated or Manager/Admin send |
| Storage | upload URL | Authenticated |

```mermaid
erDiagram
  CAMPAIGN ||--o{ CAMPAIGN_EVENT : contains
  CAMPAIGN ||--o{ STUDENT_REGISTRATION : receives
  CAMPAIGN_EVENT ||--o{ INTERACTION : records
  CAMPAIGN_EVENT }o--o{ SCHOOL : associates
  CAMPAIGN_EVENT }o--o{ EMPLOYEE : assigns
  APP_USER ||--o| STUDENT : links
  APP_USER ||--o| EMPLOYEE : links
```

# 11. UI, Form and Responsive Inventory

| Screen family | Components observed from source | Form/validation evidence | Responsive evidence |
| --- | --- | --- | --- |
| Login | Brand mark, fields, primary/outlined actions | Email and password fields; runtime error state not captured | Desktop and 390 × 844 captured |
| Application shell | Sidebar, selected navigation item, shell body | N/A | Route shell decides map behavior by screen width; exact breakpoints not verified |
| Campaign/Event | Lists, dashboard, event detail tabs, assignment/interaction views | Campaign/event request DTOs and page form code | Not runtime verified |
| Schools/Map | Lists, details, map/provider data | Coordinate and geocoding request DTOs | Not runtime verified |
| Reports | Landing, type selection, filters | Report filter providers and export request DTO | Not runtime verified |
| Admin users | User table and role/status filters | User request and role/status DTOs | Not runtime verified |

# 12. Runtime Observations

| Item | Observation |
| --- | --- |
| Startup method | Existing root Docker Compose stack was already running; no Docker configuration changed. |
| Docker services used | PostgreSQL, Redis, MinIO, MinIO init, backend, frontend; historical import/seed jobs had completed. |
| Health | Backend, PostgreSQL, Redis, and MinIO were healthy; frontend was running. |
| URLs tested | Frontend `/`, backend actuator health, Swagger UI, MinIO live health and console returned HTTP 200. |
| Browser used | Codex In-app Browser. |
| Login UI | Login screen rendered at desktop and mobile viewport. |
| Runtime blocker | After empty login submission, UI rendered white; reload restored login. Browser console reported a 404 for `assets/.env`. |
| Login verification | A seed administrator account defined by the repository authenticated successfully through the local API and browser. Credential values are not recorded. |
| Roles accessed | Admin. |

# 13. Source Reference Index

- Routing and shell: `FE/lib/app/router.dart`
- Login/profile/auth client: `FE/lib/features/auth/`
- Home pages/providers: `FE/lib/features/home/`
- Campaign/event/school/student UI: `FE/lib/features/campaign/`, `school/`, `student/`, `staff/`
- Map/weather/analytics/reports/admin UI: corresponding folders under `FE/lib/features/`
- Backend auth: `BE/src/main/java/com/vnmap/auth/`
- Backend authorization: `BE/src/main/java/com/vnmap/common/config/SecurityConfig.java`
- Backend domain APIs: `BE/src/main/java/com/vnmap/{campaign,geo,weather,report,notification,storage}/`
- Runtime orchestration: `docker-compose.yml`
- Architecture and conventions: `PROJECT_CONTEXT.md`, `docs/MVVM_CONVENTION.md`

# 14. Unverified Areas and Limitations

- Admin navigation and the captured Admin screens were verified at desktop viewport. Detail pages, modal/form states, and all non-Admin role sessions remain unverified.
- Credentials were not printed, stored, or added to the report. The report therefore does not identify accounts by email or password.
- The login submit runtime behavior and the `assets/.env` warning are recorded as observed runtime facts; their causal relationship is not asserted.
- No report-generation, notification-send, upload, delete, or other data-changing operation was invoked.

## Appendix A — Route List

The route list is recorded in [Navigation Sitemap and Screen Inventory](#7-navigation-sitemap-and-screen-inventory) from `FE/lib/app/router.dart`.

## Appendix B — Environment Variable Names

`API_BASE_URL`, `ENV_MODE`, Firebase configuration names, `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USERNAME`, `DB_PASSWORD`, `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`, `MINIO_ENDPOINT`, `MINIO_PUBLIC_ENDPOINT`, `MINIO_BUCKET`, `MINIO_REPORTS_BUCKET`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_REGION`, `OWM_BASE_URL`, `OWM_API_KEY`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `FIREBASE_SERVICE_ACCOUNT_FILE`.

## Appendix C — Screenshot File List

| Figure | File |
| --- | --- |
| 1 | `system-analysis-assets/screenshots/01-login-desktop.jpg` |
| 2 | `system-analysis-assets/screenshots/02-login-mobile.jpg` |

## Appendix D — Glossary

| Term | Meaning in this system |
| --- | --- |
| Campaign | Outreach campaign domain record. |
| Event | Campaign-associated activity/event. |
| Interaction | Recorded event participant/outcome interaction. |
| Student registration | Student association with a campaign/event workflow. |
| Administrative unit | Province/commune geographic data used by Map and Weather. |

# 15. Admin Runtime Verification Extension

A seed administrator account supplied by the repository was used for this local-only browser session. No credential, access token, email address, or other account identifier is retained in this document or in included screenshots.

| Screen | Runtime route | Observed desktop content | Screenshot |
| --- | --- | --- | --- |
| Admin home | `/home/admin` | Application shell with sidebar and role-specific overview content | `03-admin-dashboard-desktop.png` |
| Map | `/map` | Map module rendered within the authenticated shell | `04-map-desktop.png` |
| Campaign list | `/campaigns` | Search field, status selector, campaign cards, status badges, edit/download controls and event entry actions | `05-campaign-list-desktop.png` |
| School list | `/schools` | School module rendered in the authenticated shell | `06-school-list-desktop.png` |
| Analytics | `/analytics` | Analytics module rendered in the authenticated shell | `07-analytics-desktop.png` |
| Reports | `/reports` | Report landing module rendered in the authenticated shell | `08-reports-desktop.png` |

The Admin sidebar observed at runtime contains Overview, Map, Profile, Campaigns, Analytics, Registration Review, Schools, Reports, Users, Settings, and Logout. The Users and Profile routes were reached during the session but their captures were excluded from this report because the visible runtime tables/profile contain account-identifying data.

## Additional Screenshot Catalogue

| Figure | Screen | Viewport | State | File |
| --- | --- | --- | --- | --- |
| 3 | Admin overview | Desktop | Loaded Admin session | `system-analysis-assets/screenshots/03-admin-dashboard-desktop.jpg` |
| 4 | Map | Desktop | Loaded Admin session | `system-analysis-assets/screenshots/04-map-desktop.jpg` |
| 5 | Campaign list | Desktop | Loaded Admin session | `system-analysis-assets/screenshots/05-campaign-list-desktop.jpg` |
| 6 | School list | Desktop | Loaded Admin session | `system-analysis-assets/screenshots/06-school-list-desktop.jpg` |
| 7 | Analytics | Desktop | Loaded Admin session | `system-analysis-assets/screenshots/07-analytics-desktop.jpg` |
| 8 | Reports | Desktop | Loaded Admin session | `system-analysis-assets/screenshots/08-reports-desktop.jpg` |

![Admin campaign list desktop](system-analysis-assets/screenshots/05-campaign-list-desktop.jpg)

**Figure 5.** Campaign list loaded in an authenticated Admin session.

## Responsive Observation Extension

After changing the authenticated browser viewport to 390 × 844 and navigating to campaign/map pages, the Flutter Web client displayed a blank white page in the captured state. Resetting to desktop and navigation to the same authenticated route restored the desktop UI. The report records this as an observed runtime state; the source of that behavior was not established in this analysis.
# 16. Multi-Role Runtime Evidence

Each role below was authenticated using a seed account defined or referenced by the repository. Credential values were used only for the local test session and are excluded from this report.

| Role | Landing route observed | Sidebar/module evidence observed | Screenshot |
| --- | --- | --- | --- |
| Admin | `/home/admin` | Overview, Map, Profile, Campaigns, Analytics, Registration Review, Schools, Reports, Users, Settings, Logout | `03-admin-dashboard-desktop.png` |
| Manager | `/home/manager` | Manager landing page opened after authentication; source sidebar additionally contains Reports and omits Users | `09-manager-dashboard-desktop.png` |
| Staff | `/home/staff` | Staff landing page opened after authentication; source sidebar includes Analytics and Registration Review | `10-staff-dashboard-desktop.png` |
| Student | `/home/student` | Student landing page opened after authentication; source sidebar includes Campaigns, Schools, Own Registrations, Settings and Logout | `11-student-dashboard-desktop.png` |

![Manager overview desktop](system-analysis-assets/screenshots/09-manager-dashboard-desktop.jpg)

**Figure 9.** Manager landing page after seed-account authentication.

![Staff overview desktop](system-analysis-assets/screenshots/10-staff-dashboard-desktop.jpg)

**Figure 10.** Staff landing page after seed-account authentication.

![Student overview desktop](system-analysis-assets/screenshots/11-student-dashboard-desktop.jpg)

**Figure 11.** Student landing page after seed-account authentication.
# 17. Full Screen-by-Screen Documentation

This section expands the screen inventory into one source-traceable subsection per routed screen. “Runtime status” only means that route/page was reached in the current local session; it does not imply that every control or data-changing workflow was executed.

## SCR-001 — Đăng nhập

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-001 Đăng nhập /login Public Authentication login_page.dart AuthController: POST /api/v1/auth/login; GoogleAuthController: POST /api/v1/auth/google Yes[2]) |
| Module | Authentication |
| Allowed role(s) | Public |
| Page source | FE/lib/features/.../login_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Authentication function represented by **Đăng nhập**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | AuthController: POST /api/v1/auth/login; GoogleAuthController: POST /api/v1/auth/google |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** AuthController: POST /api/v1/auth/login; GoogleAuthController: POST /api/v1/auth/google.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../login_page.dart
- Integration: AuthController: POST /api/v1/auth/login; GoogleAuthController: POST /api/v1/auth/google
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-002 — Đăng ký học sinh theo chiến dịch

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-002 Đăng ký học sinh theo chiến dịch /student/register/:campaignId Public Student student_register_page.dart CampaignController: POST /api/v1/campaigns/{campaignId}/student-registrations No[2]) |
| Module | Student |
| Allowed role(s) | Public |
| Page source | FE/lib/features/.../student_register_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Student function represented by **Đăng ký học sinh theo chiến dịch**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | CampaignController: POST /api/v1/campaigns/{campaignId}/student-registrations |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** CampaignController: POST /api/v1/campaigns/{campaignId}/student-registrations.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../student_register_page.dart
- Integration: CampaignController: POST /api/v1/campaigns/{campaignId}/student-registrations
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-003 — Tổng quan quản trị

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-003 Tổng quan quản trị /home/admin ADMIN Home admin_home_page.dart AdminHomeProvider; aggregate campaign/user data Yes[2]) |
| Module | Home |
| Allowed role(s) | ADMIN |
| Page source | FE/lib/features/.../admin_home_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Home function represented by **Tổng quan quản trị**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | AdminHomeProvider; aggregate campaign/user data |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** AdminHomeProvider; aggregate campaign/user data.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../admin_home_page.dart
- Integration: AdminHomeProvider; aggregate campaign/user data
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-004 — Tổng quan quản lý

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-004 Tổng quan quản lý /home/manager MANAGER, ADMIN Home manager_home_page.dart ManagerHomeProvider; campaign and event aggregates Yes[2]) |
| Module | Home |
| Allowed role(s) | MANAGER, ADMIN |
| Page source | FE/lib/features/.../manager_home_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Home function represented by **Tổng quan quản lý**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | ManagerHomeProvider; campaign and event aggregates |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** ManagerHomeProvider; campaign and event aggregates.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../manager_home_page.dart
- Integration: ManagerHomeProvider; campaign and event aggregates
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-005 — Tổng quan nhân viên

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-005 Tổng quan nhân viên /home/staff STAFF, MANAGER, ADMIN Home staff_home_page.dart StaffHomeProvider; assignments and registrations Yes[2]) |
| Module | Home |
| Allowed role(s) | STAFF, MANAGER, ADMIN |
| Page source | FE/lib/features/.../staff_home_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Home function represented by **Tổng quan nhân viên**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | StaffHomeProvider; assignments and registrations |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** StaffHomeProvider; assignments and registrations.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../staff_home_page.dart
- Integration: StaffHomeProvider; assignments and registrations
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-006 — Tổng quan học sinh

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-006 Tổng quan học sinh /home/student STUDENT Home student_home_page.dart StudentHomeProvider; own registrations Yes[2]) |
| Module | Home |
| Allowed role(s) | STUDENT |
| Page source | FE/lib/features/.../student_home_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Home function represented by **Tổng quan học sinh**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | StudentHomeProvider; own registrations |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** StudentHomeProvider; own registrations.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../student_home_page.dart
- Integration: StudentHomeProvider; own registrations
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-007 — Bản đồ

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-007 Bản đồ /map Authenticated Map map_page.dart GeoRepository; /api/v1/geo/provinces, boundaries, communes, units, reverse Yes[2]) |
| Module | Map |
| Allowed role(s) | Authenticated |
| Page source | FE/lib/features/.../map_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Map function represented by **Bản đồ**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GeoRepository; /api/v1/geo/provinces, boundaries, communes, units, reverse |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GeoRepository; /api/v1/geo/provinces, boundaries, communes, units, reverse.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../map_page.dart
- Integration: GeoRepository; /api/v1/geo/provinces, boundaries, communes, units, reverse
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-008 — Thời tiết

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-008 Thời tiết /weather Authenticated Weather weather_page.dart WeatherRepository; /api/v1/weather/current and /unit/{unitCode} No[2]) |
| Module | Weather |
| Allowed role(s) | Authenticated |
| Page source | FE/lib/features/.../weather_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Weather function represented by **Thời tiết**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | WeatherRepository; /api/v1/weather/current and /unit/{unitCode} |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** WeatherRepository; /api/v1/weather/current and /unit/{unitCode}.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../weather_page.dart
- Integration: WeatherRepository; /api/v1/weather/current and /unit/{unitCode}
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-009 — Danh sách chiến dịch

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-009 Danh sách chiến dịch /campaigns ADMIN, MANAGER, STAFF, STUDENT Campaign campaign_list_page.dart CampaignRepository; GET /api/v1/campaigns Yes[2]) |
| Module | Campaign |
| Allowed role(s) | ADMIN, MANAGER, STAFF, STUDENT |
| Page source | FE/lib/features/.../campaign_list_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Campaign function represented by **Danh sách chiến dịch**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | CampaignRepository; GET /api/v1/campaigns |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** CampaignRepository; GET /api/v1/campaigns.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../campaign_list_page.dart
- Integration: CampaignRepository; GET /api/v1/campaigns
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-010 — Dashboard chiến dịch

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-010 Dashboard chiến dịch /campaigns/:campaignId/dashboard ADMIN, MANAGER Campaign campaign_dashboard_page.dart GET /api/v1/campaigns/{id}/dashboard No[2]) |
| Module | Campaign |
| Allowed role(s) | ADMIN, MANAGER |
| Page source | FE/lib/features/.../campaign_dashboard_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Campaign function represented by **Dashboard chiến dịch**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GET /api/v1/campaigns/{id}/dashboard |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GET /api/v1/campaigns/{id}/dashboard.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../campaign_dashboard_page.dart
- Integration: GET /api/v1/campaigns/{id}/dashboard
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-011 — Sự kiện chiến dịch

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-011 Sự kiện chiến dịch /campaigns/:campaignId/events ADMIN, MANAGER, STAFF, STUDENT Event campaign_events_page.dart GET/POST /api/v1/campaigns/{id}/events No[2]) |
| Module | Event |
| Allowed role(s) | ADMIN, MANAGER, STAFF, STUDENT |
| Page source | FE/lib/features/.../campaign_events_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Event function represented by **Sự kiện chiến dịch**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GET/POST /api/v1/campaigns/{id}/events |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GET/POST /api/v1/campaigns/{id}/events.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../campaign_events_page.dart
- Integration: GET/POST /api/v1/campaigns/{id}/events
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-012 — Chi tiết sự kiện

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-012 Chi tiết sự kiện /events/:eventId ADMIN, MANAGER, STAFF, STUDENT Event event_detail_page.dart GET/PUT/DELETE /api/v1/events/{id}; assignments and interactions No[2]) |
| Module | Event |
| Allowed role(s) | ADMIN, MANAGER, STAFF, STUDENT |
| Page source | FE/lib/features/.../event_detail_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Event function represented by **Chi tiết sự kiện**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GET/PUT/DELETE /api/v1/events/{id}; assignments and interactions |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GET/PUT/DELETE /api/v1/events/{id}; assignments and interactions.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../event_detail_page.dart
- Integration: GET/PUT/DELETE /api/v1/events/{id}; assignments and interactions
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-013 — Danh sách trường học

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-013 Danh sách trường học /schools ADMIN, MANAGER, STAFF, STUDENT School school_list_page.dart SchoolsRepository; GET /api/v1/schools Yes[2]) |
| Module | School |
| Allowed role(s) | ADMIN, MANAGER, STAFF, STUDENT |
| Page source | FE/lib/features/.../school_list_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the School function represented by **Danh sách trường học**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | SchoolsRepository; GET /api/v1/schools |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** SchoolsRepository; GET /api/v1/schools.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../school_list_page.dart
- Integration: SchoolsRepository; GET /api/v1/schools
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-014 — Chi tiết trường học

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-014 Chi tiết trường học /schools/:schoolUid ADMIN, MANAGER, STAFF, STUDENT School school_detail_page.dart GET /api/v1/schools/{schoolUid} No[2]) |
| Module | School |
| Allowed role(s) | ADMIN, MANAGER, STAFF, STUDENT |
| Page source | FE/lib/features/.../school_detail_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the School function represented by **Chi tiết trường học**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GET /api/v1/schools/{schoolUid} |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GET /api/v1/schools/{schoolUid}.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../school_detail_page.dart
- Integration: GET /api/v1/schools/{schoolUid}
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-015 — Analytics

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-015 Analytics /analytics ADMIN, MANAGER, STAFF Analytics analytics_page.dart AnalyticsRepository; /api/analytics/aggregate, trend, channels, employees Yes[2]) |
| Module | Analytics |
| Allowed role(s) | ADMIN, MANAGER, STAFF |
| Page source | FE/lib/features/.../analytics_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Analytics function represented by **Analytics**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | AnalyticsRepository; /api/analytics/aggregate, trend, channels, employees |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** AnalyticsRepository; /api/analytics/aggregate, trend, channels, employees.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../analytics_page.dart
- Integration: AnalyticsRepository; /api/analytics/aggregate, trend, channels, employees
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-016 — Duyệt đơn

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-016 Duyệt đơn /staff/registrations ADMIN, MANAGER, STAFF Staff staff_registrations_page.dart GET /api/v1/staff/student-registrations; registration status endpoints Yes[2]) |
| Module | Staff |
| Allowed role(s) | ADMIN, MANAGER, STAFF |
| Page source | FE/lib/features/.../staff_registrations_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Staff function represented by **Duyệt đơn**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GET /api/v1/staff/student-registrations; registration status endpoints |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GET /api/v1/staff/student-registrations; registration status endpoints.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../staff_registrations_page.dart
- Integration: GET /api/v1/staff/student-registrations; registration status endpoints
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-017 — Đăng ký sự kiện

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-017 Đăng ký sự kiện /student/register-event/:campaignId STUDENT Student event_registration_page.dart POST /api/v1/campaigns/{id}/student-registrations No[2]) |
| Module | Student |
| Allowed role(s) | STUDENT |
| Page source | FE/lib/features/.../event_registration_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Student function represented by **Đăng ký sự kiện**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | POST /api/v1/campaigns/{id}/student-registrations |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** POST /api/v1/campaigns/{id}/student-registrations.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../event_registration_page.dart
- Integration: POST /api/v1/campaigns/{id}/student-registrations
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-018 — Đăng ký của tôi

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-018 Đăng ký của tôi /student/my-registrations STUDENT Student my_registrations_page.dart GET /api/v1/student-registrations/my No[2]) |
| Module | Student |
| Allowed role(s) | STUDENT |
| Page source | FE/lib/features/.../my_registrations_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Student function represented by **Đăng ký của tôi**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GET /api/v1/student-registrations/my |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GET /api/v1/student-registrations/my.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../my_registrations_page.dart
- Integration: GET /api/v1/student-registrations/my
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-019 — Trang báo cáo

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-019 Trang báo cáo /reports ADMIN, MANAGER Reports reports_landing_page.dart ReportViewModel and report repository Yes[2]) |
| Module | Reports |
| Allowed role(s) | ADMIN, MANAGER |
| Page source | FE/lib/features/.../reports_landing_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Reports function represented by **Trang báo cáo**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | ReportViewModel and report repository |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** ReportViewModel and report repository.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../reports_landing_page.dart
- Integration: ReportViewModel and report repository
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-020 — Báo cáo chiến dịch

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-020 Báo cáo chiến dịch /reports/campaign ADMIN, MANAGER Reports campaign_report_type_page.dart POST /api/v1/reports/campaigns/pdf No[2]) |
| Module | Reports |
| Allowed role(s) | ADMIN, MANAGER |
| Page source | FE/lib/features/.../campaign_report_type_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Reports function represented by **Báo cáo chiến dịch**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | POST /api/v1/reports/campaigns/pdf |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** POST /api/v1/reports/campaigns/pdf.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../campaign_report_type_page.dart
- Integration: POST /api/v1/reports/campaigns/pdf
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-021 — Báo cáo sự kiện

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-021 Báo cáo sự kiện /reports/event ADMIN, MANAGER Reports event_report_type_page.dart ReportFilterProviders and ReportRepository No[2]) |
| Module | Reports |
| Allowed role(s) | ADMIN, MANAGER |
| Page source | FE/lib/features/.../event_report_type_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Reports function represented by **Báo cáo sự kiện**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | ReportFilterProviders and ReportRepository |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** ReportFilterProviders and ReportRepository.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../event_report_type_page.dart
- Integration: ReportFilterProviders and ReportRepository
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-022 — Báo cáo trường học

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-022 Báo cáo trường học /reports/school ADMIN, MANAGER Reports school_report_type_page.dart ReportFilterProviders and ReportRepository No[2]) |
| Module | Reports |
| Allowed role(s) | ADMIN, MANAGER |
| Page source | FE/lib/features/.../school_report_type_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Reports function represented by **Báo cáo trường học**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | ReportFilterProviders and ReportRepository |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** ReportFilterProviders and ReportRepository.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../school_report_type_page.dart
- Integration: ReportFilterProviders and ReportRepository
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-023 — Báo cáo vùng

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-023 Báo cáo vùng /reports/region ADMIN, MANAGER Reports region_report_type_page.dart ReportFilterProviders and ReportRepository No[2]) |
| Module | Reports |
| Allowed role(s) | ADMIN, MANAGER |
| Page source | FE/lib/features/.../region_report_type_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Reports function represented by **Báo cáo vùng**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | ReportFilterProviders and ReportRepository |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** ReportFilterProviders and ReportRepository.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../region_report_type_page.dart
- Integration: ReportFilterProviders and ReportRepository
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-024 — Quản lý người dùng

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-024 Quản lý người dùng /admin/users ADMIN Administration admin_users_page.dart GET/POST/PUT/DELETE /api/v1/users; role/status update Yes[2]) |
| Module | Administration |
| Allowed role(s) | ADMIN |
| Page source | FE/lib/features/.../admin_users_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Administration function represented by **Quản lý người dùng**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GET/POST/PUT/DELETE /api/v1/users; role/status update |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GET/POST/PUT/DELETE /api/v1/users; role/status update.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../admin_users_page.dart
- Integration: GET/POST/PUT/DELETE /api/v1/users; role/status update
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-025 — Hồ sơ

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-025 Hồ sơ /profile Authenticated Authentication profile_page.dart GET/PUT /api/v1/auth/me; PUT /me/password Yes[2]) |
| Module | Authentication |
| Allowed role(s) | Authenticated |
| Page source | FE/lib/features/.../profile_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Authentication function represented by **Hồ sơ**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | GET/PUT /api/v1/auth/me; PUT /me/password |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** GET/PUT /api/v1/auth/me; PUT /me/password.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../profile_page.dart
- Integration: GET/PUT /api/v1/auth/me; PUT /me/password
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-026 — Cài đặt

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-026 Cài đặt /settings Authenticated Settings settings_page.dart Locale/theme/analytics-consent/remote-config providers No[2]) |
| Module | Settings |
| Allowed role(s) | Authenticated |
| Page source | FE/lib/features/.../settings_page.dart |
| Runtime status | No |

### 2. Purpose

This route presents the Settings function represented by **Cài đặt**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | Locale/theme/analytics-consent/remote-config providers |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** Locale/theme/analytics-consent/remote-config providers.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../settings_page.dart
- Integration: Locale/theme/analytics-consent/remote-config providers
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java


## SCR-027 — Đăng xuất

### 1. Basic information

| Field | Value |
| --- | --- |
| Route | $(SCR-027 Đăng xuất /logout Public route Authentication logout_page.dart POST /api/v1/auth/logout; TokenStorage clear Yes[2]) |
| Module | Authentication |
| Allowed role(s) | Public route |
| Page source | FE/lib/features/.../logout_page.dart |
| Runtime status | Yes |

### 2. Purpose

This route presents the Authentication function represented by **Đăng xuất**. The purpose and access boundary are derived from the router, page class and backend authorization configuration.

### 3. Layout and navigation

Authenticated routes render inside the application shell, with the sidebar selecting the matching navigation group. The public login and student self-registration routes are outside that shell. Detail routes use route parameters; the map additionally accepts focus/query arguments described in
outer.dart.

### 4. Components and actions

| Component category | Observed responsibility | Data/action link |
| --- | --- | --- |
| Page content | Renders the module-specific page state and records | POST /api/v1/auth/logout; TokenStorage clear |
| Application shell | Sidebar, active navigation state and page body | AppShellScaffold, AppSidebar |
| Async state | Provider/repository result drives loading, data or error rendering where implemented | Riverpod provider/view-model conventions |

### 5. Data and integration

**Verified source integration:** POST /api/v1/auth/logout; TokenStorage clear.

The frontend routes through its repository/provider layer; backend controllers apply the configured JWT role matcher before protected operations. Response field-level mapping is documented only where the DTO/page source explicitly defines it.

### 6. Form and validation

This screen may contain forms, filters or dialogs according to its page/widget implementation. The full control-level validation state was not executed unless shown in the runtime evidence table. Backend request validation is represented by the request DTOs and the API error envelope.

### 7. UI states

| State | Trigger | Evidence |
| --- | --- | --- |
| Initial/loading | Route/provider starts | Page/provider source convention |
| Loaded | Repository result available | Runtime status above or source path |
| Unauthorized/forbidden | Missing token or role mismatch | GoRouter redirect and Spring Security matchers |
| Empty/error | API result or exception | Source-defined async/error handling; not exhaustively runtime-triggered |

### 8. Responsive behavior

The shared shell and page widgets determine layout at available width. Desktop screenshots were retained for runtime-safe pages. At the 390 × 844 test viewport, authenticated navigation to map/campaign pages produced a blank white rendered state; no cause is asserted here.

### 9. Source reference

- Route: FE/lib/app/router.dart
- Page: FE/lib/features/.../logout_page.dart
- Integration: POST /api/v1/auth/logout; TokenStorage clear
- Authorization: BE/src/main/java/com/vnmap/common/config/SecurityConfig.java

# 18. Expanded API and Service Inventory

| Domain | Controller / repository evidence | Operations documented in source | Access boundary |
| --- | --- | --- | --- |
| Authentication | AuthController, GoogleAuthController, AuthRepository | login, refresh, logout, current user, profile update, password update, Google auth | Public login/refresh/Google; authenticated remainder |
| Campaign and events | CampaignController, CampaignRepository | campaign CRUD, event CRUD, schools, assignments, interactions | Read all roles; management Manager/Admin; interactions Staff/Manager/Admin |
| Student registration | CampaignController, staff/student providers | create registration, my registrations, review, individual/bulk status | Student creation/read own; staff/manager/admin review |
| Schools and employees | CampaignController, SchoolsRepository | school list/detail/coordinates/geocode; employee CRUD | School read all; employee mutations Admin |
| Geographic data | GeoController, GeoRepository | province/commune/unit boundaries, reverse lookup, committees | Public API matcher |
| Analytics | AnalyticsController, AnalyticsRepository | aggregate, trend, channels, employees | Staff/Manager/Admin |
| Reports | ReportController, ReportRepository | campaign PDF, list, detail, download URL | Manager/Admin |
| Notifications | NotificationController, NotificationRepository | token, list, unread count, read, read-all, send | Authenticated; send Manager/Admin |
| Storage | StorageController, StorageRepository | presigned upload URL | Authenticated |

# 19. Detailed Runtime and Screenshot Catalogue

| Figure | Route/module | Viewport | Captured state | File |
| --- | --- | --- | --- | --- |
| 1 | Login | Desktop | Initial | `01-login-desktop.png` |
| 2 | Login | 390 × 844 | Initial responsive render | `02-login-mobile.png` |
| 3 | Admin home | Desktop | Loaded | `03-admin-dashboard-desktop.png` |
| 4 | Map | Desktop | Loaded Admin route | `04-map-desktop.png` |
| 5 | Campaign list | Desktop | Loaded with search/filter/card controls | `05-campaign-list-desktop.png` |
| 6 | School list | Desktop | Loaded Admin route | `06-school-list-desktop.png` |
| 7 | Analytics | Desktop | Loaded Admin route | `07-analytics-desktop.png` |
| 8 | Reports | Desktop | Loaded Admin route | `08-reports-desktop.png` |
| 9 | Manager home | Desktop | Loaded | `09-manager-dashboard-desktop.png` |
| 10 | Staff home | Desktop | Loaded | `10-staff-dashboard-desktop.png` |
| 11 | Student home | Desktop | Loaded | `11-student-dashboard-desktop.png` |


# 20. Illustrated User Manual and PDF Export Evidence

This section records executable user journeys observed on the running Docker stack at `http://localhost:3000`. Screenshots use the 1440 x 900 desktop viewport unless a crop is explicitly stated. Role accounts were loaded from repository seed/runtime configuration; email addresses, passwords, access tokens and download URLs are not recorded in this document.

## 20.1 Runtime roles used for the manual

| Role | Landing route | Manual coverage | Credential notation |
| --- | --- | --- | --- |
| Admin | `/home/admin` | System overview, campaign/event operations, analytics, report forms | Loaded from seed configuration |
| Manager | `/home/manager` | Campaign dashboard, events, analytics, registration review, PDF reports | Loaded from seed configuration |
| Staff | `/home/staff` | Assigned events, event detail, registration review, analytics | Loaded from seed configuration |
| Student | `/home/student` | Campaign discovery, registration form, own registrations | Loaded from seed configuration |

## 20.2 FLOW-001 - Login and role landing

### User steps

1. Open `/login`.
2. Enter the role account supplied by the runtime configuration.
3. Select **Dang nhap**.
4. The client stores the authenticated session and redirects to the landing route derived from the role.
5. Confirm the sidebar modules and role-specific dashboard content.

![Login entry](system-analysis-assets/screenshots/01-login-desktop.jpg)

**Figure 1.** Login entry screen. Credential values are intentionally absent from the stored screenshot.

![Admin landing](system-analysis-assets/screenshots/03-admin-dashboard-desktop.jpg)

**Figure 3.** Admin landing page after successful authentication.

![Manager landing](system-analysis-assets/screenshots/29-manager-home-user-manual.jpg)

**Figure 29.** Manager landing page with campaign, analytics and map entry actions.

![Staff landing](system-analysis-assets/screenshots/35-staff-home-user-manual.jpg)

**Figure 35.** Staff landing page with assigned events, personal trend and interaction outcome data.

![Student landing](system-analysis-assets/screenshots/42-student-home-user-manual.jpg)

**Figure 42.** Student landing page with registration summary and navigation to available campaigns and own registrations.

### Result and integration

| Step | Frontend route/action | Backend integration | Visible result |
| --- | --- | --- | --- |
| Submit login | `/login` | `POST /api/v1/auth/login` | Authenticated session and role context |
| Resolve landing | `landingPathForRole` | Role returned in auth response | `/home/admin`, `/home/manager`, `/home/staff` or `/home/student` |
| Load dashboard | Role home provider | Campaign, event, interaction and registration reads | Role-specific KPI cards and activity content |

### Admin operational continuation

After role landing, the Admin journey continues through the shared campaign workspace. The runtime sequence below records the list, campaign dashboard, campaign events, event detail and aggregate analytics without performing a destructive mutation.

![Admin campaign list](system-analysis-assets/screenshots/23-flow-campaign-list.jpg)

**Figure 23.** Admin campaign list with search, status filtering and campaign action menus.

![Admin campaign dashboard](system-analysis-assets/screenshots/24-flow-campaign-dashboard.jpg)

**Figure 24.** Admin campaign dashboard with campaign-specific KPI cards and visual summaries.

![Admin campaign events](system-analysis-assets/screenshots/25-flow-campaign-events.jpg)

**Figure 25.** Event list reached from the selected campaign.

![Admin event detail](system-analysis-assets/screenshots/26-flow-event-detail.jpg)

**Figure 26.** Event detail information state and its schools, personnel and interactions tabs.

![Admin analytics result](system-analysis-assets/screenshots/28-flow-analytics-result.jpg)

**Figure 28.** Aggregate analytics result available to Admin after the operational drill-down.

## 20.3 FLOW-002 - Student event registration and tracking

### User steps

1. From the Student dashboard, select **Dang ky su kien** or open **Chien dich**.
2. Review campaign cards and identify a campaign whose status is `ACTIVE`.
3. Open `/student/register-event/:campaignId`.
4. Complete the student and school fields. Required fields are marked by an asterisk.
5. Submit the registration. The backend validates the campaign status and date window.
6. Open **Cua toi** to view the student's registration records and current statuses.

![Student dashboard registration entry](system-analysis-assets/screenshots/42-student-home-user-manual.jpg)

**Figure 42.** Student dashboard entry points for event registration and registration history.

![Student campaign selection](system-analysis-assets/screenshots/43-student-campaign-list.jpg)

**Figure 43.** Campaign list visible to the Student role; campaign status is shown on each card.

![Student registration form](system-analysis-assets/screenshots/44-student-registration-form.jpg)

**Figure 44.** Registration form for an active campaign. The screenshot stops before any submission and does not contain personal contact values.

![Student registration history](system-analysis-assets/screenshots/45-student-my-registrations.jpg)

**Figure 45.** Student-owned registration list reached from the **Cua toi** navigation item.

### Flow contract

| Stage | Preconditions | Request/read operation | Runtime evidence |
| --- | --- | --- | --- |
| Campaign selection | Authenticated Student | Campaign list read | Figure 43 |
| Form entry | Campaign route parameter available | School list and campaign detail reads | Figure 44 |
| Submit | Required student/school fields valid; campaign active and inside date window | `POST /api/v1/campaigns/{campaignId}/student-registrations` | Submission intentionally not repeated during documentation |
| Track | Authenticated Student linked to student record | Current-user registrations read | Figure 45 |

## 20.4 FLOW-003 - Manager campaign and event operations

### User steps

1. Sign in as Manager and use the dashboard actions to open campaign management.
2. Open **Chien dich** to search or filter the campaign list.
3. Select a campaign dashboard to view event, school, employee and interaction metrics.
4. Open the campaign's event list.
5. Select an event to view its information, participating schools, personnel and interactions tabs.
6. Open **Analytics** for the aggregate and trend view.
7. Open **Duyet don** to search/filter registration requests and expose approve/reject actions.
8. Open **Bao cao** to choose one of the four PDF report types.

![Manager dashboard](system-analysis-assets/screenshots/29-manager-home-user-manual.jpg)

**Figure 29.** Manager dashboard and primary campaign actions.

![Manager campaign list](system-analysis-assets/screenshots/30-manager-campaign-list.jpg)

**Figure 30.** Manager campaign search, status filter and campaign cards.

![Manager campaign dashboard](system-analysis-assets/screenshots/31-manager-campaign-dashboard.jpg)

**Figure 31.** Campaign dashboard with campaign-specific KPI and chart data.

![Manager campaign events](system-analysis-assets/screenshots/56-manager-campaign-events.jpg)

**Figure 56.** Events belonging to the selected campaign.

![Manager event detail](system-analysis-assets/screenshots/57-manager-event-detail.jpg)

**Figure 57.** Event detail information state with the schools, personnel and interactions tabs visible.

![Manager analytics](system-analysis-assets/screenshots/32-manager-analytics.jpg)

**Figure 32.** Manager analytics dashboard with filters and trend data.

![Manager registration review](system-analysis-assets/screenshots/33-manager-registration-review.jpg)

**Figure 33.** Privacy-safe crop of the Manager registration review header, filters, bulk actions and table columns. Runtime rows containing contact fields are excluded.

![Manager reports](system-analysis-assets/screenshots/34-manager-reports.jpg)

**Figure 34.** Report type selection available to Manager.

### Manager action map

| Screen | Main actions observed | Access boundary |
| --- | --- | --- |
| Manager home | Create campaign, open analytics, open map | Manager |
| Campaign list/dashboard | Search/filter; open events and aggregated campaign information | Manager/Admin |
| Event detail | Read event; navigate schools, personnel and interaction states | Manager/Admin; interaction operations also available to Staff |
| Registration review | Search, status filter, row selection, bulk approve/reject | Staff/Manager/Admin with backend scoping |
| Reports | Select Campaign/Event/School/Region and request PDF | Manager/Admin |

## 20.5 FLOW-004 - Staff assigned-event and registration operations

### User steps

1. Sign in as Staff and review the assigned-event summary on `/home/staff`.
2. Open **Chien dich** and navigate to the events of an accessible campaign.
3. Open an event. The detail screen exposes information, participating schools, personnel and interactions tabs.
4. Use the interactions area for event interaction records according to the assigned scope.
5. Open **Duyet don** to search/filter registrations and expose approval/rejection actions.
6. Open **Analytics** to view aggregate KPIs and the interaction trend available to Staff.

![Staff dashboard](system-analysis-assets/screenshots/35-staff-home-user-manual.jpg)

**Figure 35.** Staff dashboard with assigned events and personal interaction data.

![Staff campaign list](system-analysis-assets/screenshots/36-staff-campaign-list.jpg)

**Figure 36.** Campaign list in the Staff session. Report and user administration navigation items are absent.

![Staff campaign events](system-analysis-assets/screenshots/37-staff-campaign-events.jpg)

**Figure 37.** Campaign event list reached by Staff.

![Staff event detail](system-analysis-assets/screenshots/38-staff-event-detail.jpg)

**Figure 38.** Event detail with the interactions tab visible as part of the Staff workflow.

![Staff registration review](system-analysis-assets/screenshots/40-staff-registration-review.jpg)

**Figure 40.** Privacy-safe crop of Staff registration review controls and columns. Contact-value rows are excluded.

![Staff analytics](system-analysis-assets/screenshots/41-staff-analytics.jpg)

**Figure 41.** Analytics screen under the Staff session.

### Staff action map

| Activity | Runtime route | Data/action boundary |
| --- | --- | --- |
| Review assignments | `/home/staff` | Assigned events and personal interaction summaries |
| Open campaign events | `/campaigns/:campaignId/events` | Campaign/event reads permitted to authenticated roles |
| Work with event detail | `/events/:eventId` | Assigned schools, personnel and interactions |
| Review registrations | `/staff/registrations` | Staff-scoped registration query and status operations |
| Read analytics | `/analytics` | Staff/Manager/Admin analytics endpoints |

## 20.6 FLOW-005 - Settings, language, Remote Config and Crashlytics demo

### User steps

1. Open `/settings` from an authenticated session.
2. Select Vietnamese or English; visible labels change with the active locale.
3. Toggle analytics consent if the setting is available.
4. Select **Lam moi Remote Config** to fetch the current feature flags.
5. Review the Remote Config summary rendered by the Firebase demo panel.
6. Select the Crashlytics non-fatal demo action. On Flutter Web, the UI records the platform availability/result without stopping the application.

![Firebase settings overview](system-analysis-assets/screenshots/12-firebase-demo-settings-desktop.jpg)

**Figure 12.** Settings page containing locale, analytics consent and Firebase demo sections.

![Firebase demo controls](system-analysis-assets/screenshots/13-firebase-demo-controls.jpg)

**Figure 13.** Remote Config and Crashlytics demo controls.

![Remote Config refresh](system-analysis-assets/screenshots/14-remote-config-refresh.jpg)

**Figure 14.** Runtime state after a Remote Config refresh.

![Crashlytics web state](system-analysis-assets/screenshots/15-crashlytics-demo-web-status.jpg)

**Figure 15.** Crashlytics demo status on the web runtime.

![English settings](system-analysis-assets/screenshots/16-settings-english-localized.jpg)

**Figure 16.** Settings and navigation rendered in English.

![Vietnamese settings](system-analysis-assets/screenshots/17-settings-vietnamese-localized.jpg)

**Figure 17.** Settings and navigation rendered in Vietnamese.

## 20.7 FLOW-006 - End-to-end PDF report export

### Step 1 - Choose a report type

Open `/reports` and select Campaign, Event, School or Region.

![Report type selection](system-analysis-assets/screenshots/22-flow-report-type-selection.jpg)

**Figure 22.** Report landing page with the four report-type cards.

### Step 2 - Configure the type-specific form

Each report form contains its own filters, chart preview area and **Xuat PDF** action.

![Campaign report form](system-analysis-assets/screenshots/18-flow-report-campaign-form.jpg)

**Figure 18.** Campaign report filters, chart previews and export action.

![Event report form](system-analysis-assets/screenshots/19-flow-report-event-form.jpg)

**Figure 19.** Event report filters and export action.

![School report form](system-analysis-assets/screenshots/20-flow-report-school-form.jpg)

**Figure 20.** School report filters and export action.

![Region report form](system-analysis-assets/screenshots/21-flow-report-region-form.jpg)

**Figure 21.** Region report filters and export action.

### Step 3 - Submit and wait for generation

The form disables its action while the job is `PENDING`, displays the report identifier, and automatically refreshes the status.

![Report generation pending](system-analysis-assets/screenshots/54-flow-report-export-requested.jpg)

**Figure 54.** Report #55 in the in-progress UI state.

![Report generation ready](system-analysis-assets/screenshots/55-flow-report-ready.jpg)

**Figure 55.** Report #55 in the `READY` state with the download action and generated filename.

### Step 4 - Download and verify each generated PDF

Four runtime jobs were generated and downloaded through their authenticated, time-limited download URLs. The temporary PDF files were used only for visual verification; the documentation stores PNG renders in the screenshot folder.

| Report type | Runtime report ID | Status | PDF bytes | Pages | Evidence |
| --- | ---: | --- | ---: | ---: | --- |
| Campaign | 51 | READY | 177,791 | 60 | Figures 46-47 |
| Event | 52 | READY | 70,172 | 16 | Figures 48-49 |
| School | 53 | READY | 433,444 | 144 | Figures 50-51 |
| Region | 54 | READY | 55,217 | 15 | Figures 52-53 |

#### Campaign PDF

![Campaign PDF cover](system-analysis-assets/screenshots/46-pdf-campaign-cover.png)

**Figure 46.** Campaign PDF cover with executive KPI summary.

![Campaign PDF chart](system-analysis-assets/screenshots/47-pdf-campaign-chart.png)

**Figure 47.** Campaign status distribution chart and its matching data table.

#### Event PDF

![Event PDF cover](system-analysis-assets/screenshots/48-pdf-event-cover.png)

**Figure 48.** Event PDF cover with executive KPI summary.

![Event PDF chart](system-analysis-assets/screenshots/49-pdf-event-chart.png)

**Figure 49.** Registration-status chart and matching table in the Event PDF.

#### School PDF

![School PDF cover](system-analysis-assets/screenshots/50-pdf-school-cover.png)

**Figure 50.** School PDF cover with executive KPI summary.

![School PDF chart](system-analysis-assets/screenshots/51-pdf-school-chart.png)

**Figure 51.** School-activity chart and matching table in the School PDF.

#### Region PDF

![Region PDF cover](system-analysis-assets/screenshots/52-pdf-region-cover.png)

**Figure 52.** Region PDF cover with executive KPI summary.

![Region PDF chart](system-analysis-assets/screenshots/53-pdf-region-chart.png)

**Figure 53.** Province interaction chart and matching table in the Region PDF.

### PDF structure observed

| Element | Current generated output |
| --- | --- |
| Cover | Report type, report identifier, generation timestamp and four KPI values |
| Chart count | Four selected, data-derived charts for each report type |
| Chart page | Title, description, unit, period, data source, insight, chart and value table |
| Remaining pages | Type-specific record tables derived from the selected sections |
| Observed text rendering | Latin text and numeric/chart labels render. Some Vietnamese school/province labels lose diacritics in the current PDF output; Figures 51 and 53 preserve that observed state. |

## 20.8 Screenshot catalogue for the illustrated flows

| Figure/file | Role or report type | Route/state | Purpose |
| --- | --- | --- | --- |
| `18-flow-report-campaign-form.png` | Manager/Admin | `/reports/campaign` | Campaign report configuration |
| `19-flow-report-event-form.png` | Manager/Admin | `/reports/event` | Event report configuration |
| `20-flow-report-school-form.png` | Manager/Admin | `/reports/school` | School report configuration |
| `21-flow-report-region-form.png` | Manager/Admin | `/reports/region` | Region report configuration |
| `22-flow-report-type-selection.png` | Manager/Admin | `/reports` | Report type selection |
| `23-flow-campaign-list.png` | Admin | `/campaigns` | Campaign flow entry |
| `24-flow-campaign-dashboard.png` | Admin | `/campaigns/10/dashboard` | Campaign KPI/chart state |
| `25-flow-campaign-events.png` | Admin | `/campaigns/10/events` | Event list |
| `26-flow-event-detail.png` | Admin | `/events/32` | Event information and tabs |
| `28-flow-analytics-result.png` | Admin | `/analytics` | Aggregate analytics result |
| `29-manager-home-user-manual.png` | Manager | `/home/manager` | Manager landing |
| `30-manager-campaign-list.png` | Manager | `/campaigns` | Manager campaign list |
| `31-manager-campaign-dashboard.png` | Manager | `/campaigns/10/dashboard` | Manager campaign dashboard |
| `32-manager-analytics.png` | Manager | `/analytics` | Manager analytics |
| `33-manager-registration-review.png` | Manager | `/staff/registrations` | Privacy-safe review controls |
| `34-manager-reports.png` | Manager | `/reports` | Manager report selection |
| `35-staff-home-user-manual.png` | Staff | `/home/staff` | Staff landing |
| `36-staff-campaign-list.png` | Staff | `/campaigns` | Staff campaign list |
| `37-staff-campaign-events.png` | Staff | `/campaigns/10/events` | Staff event list |
| `38-staff-event-detail.png` | Staff | `/events/32` | Staff event detail |
| `40-staff-registration-review.png` | Staff | `/staff/registrations` | Privacy-safe review controls |
| `41-staff-analytics.png` | Staff | `/analytics` | Staff analytics |
| `42-student-home-user-manual.png` | Student | `/home/student` | Student landing |
| `43-student-campaign-list.png` | Student | `/campaigns` | Student campaign discovery |
| `44-student-registration-form.png` | Student | `/student/register-event/8` | Registration form |
| `45-student-my-registrations.png` | Student | `/student/my-registrations` | Registration history |
| `46-53-pdf-*-*.png` | Four PDF types | Rendered pages 1 and 2 | Cover and chart evidence |
| `54-flow-report-export-requested.png` | Manager | Campaign report `PENDING` | Job submission state |
| `55-flow-report-ready.png` | Manager | Campaign report `READY` | Download-ready state |
| `56-manager-campaign-events.png` | Manager | `/campaigns/10/events` | Manager event list |
| `57-manager-event-detail.png` | Manager | `/events/32` | Manager event detail |

## 20.9 Manual verification boundaries

- No campaign, event, registration status, interaction, user or profile record was mutated for the screenshots.
- The report export action was executed because PDF generation and evidence were explicitly requested.
- Registration review screenshots exclude runtime rows containing email addresses and phone numbers.
- Stored screenshots do not contain passwords, tokens, signed download URLs, cookies or environment-variable values.
- The report describes the current UI and generated documents; it does not score, redesign or recommend changes.
