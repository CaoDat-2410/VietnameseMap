# Session Progress Log

## Current State

**Last Updated:** 2026-06-24 23:51
**Session ID:** session-20260624-marker-sidebar-analytics-dark-admin
**Active Feature:** feat-056 (admin table) completed — ALL 5 PLAN STEPS DONE

## Status: PLAN IMPLEMENTED — feat-047 … feat-051 DONE

### Completed in this session

- **feat-047 — Map: auto-zoom + SchoolInfoSheet query fix + AppShell props**
  - `FE/lib/app/router.dart`: introduced `parseMapArgs(Uri)` helper used by both the
    `/map` route and the wide-screen `_AppShell`, so the embedded map receives
    the same `schoolUids` / `focusLat` / `focusLng` / `focusLabel` from the URL
    as the standalone map page.
  - `FE/lib/features/map/presentation/widgets/vietnam_map_view.dart`:
    - Added a `_mapReady` flag + `Completer<void>` gated on the first
      `onPositionChanged` callback. The `_geocodeAndShowSchools` call now
      waits for the map to be ready before running.
    - `_zoomToGeocoded` now no-ops until `_mapReady` is true and retries up
      to 3 times if the controller throws (covers the rare case where
      tiles haven't finished loading).
  - `FE/lib/features/map/presentation/widgets/school_info_sheet.dart` and
    `FE/lib/features/school/presentation/pages/school_detail_page.dart`:
    switched the `/map?school=…` (singular, broken) URL to `/map?schools=…`
    (plural, matches `parseMapArgs`).

- **feat-048 — Analytics: filter bug fix + backend filter params**
  - `BE/src/main/java/com/vnmap/campaign/controller/AnalyticsController.java`:
    added `@RequestParam` `campaignId` and `schoolUid` on
    `GET /api/analytics/aggregate`.
  - `BE/src/main/java/com/vnmap/campaign/service/AnalyticsService.java`:
    `getAggregateDashboard(Long, String)` now applies the same WHERE clause
    to every count and grouping query so totals + outcomes + province +
    top-schools are all consistent with the filter.
  - `FE/lib/features/analytics/data/repositories/analytics_repository.dart`:
    `getAggregateDashboard({campaignId, schoolUid})` builds the
    query-parameter map and posts to `/api/analytics/aggregate`.
  - `FE/lib/features/analytics/presentation/providers/analytics_provider.dart`:
    introduced `AnalyticsFilter` record + `analyticsFilterProvider`, and
    converted `aggregateDashboardProvider` into
    `FutureProvider.family<…, AnalyticsFilter>` so any consumer re-fetches
    automatically when the filter changes.
  - `FE/lib/features/analytics/presentation/pages/analytics_page.dart`:
    replaced the global `aggregateDashboardProvider` watch with
    `aggregateDashboardProvider(ref.watch(analyticsFilterProvider))`.
  - Verified:
    - `?schoolUid=79-224` → 1 school, 222 interactions (all at HCM).
    - `?campaignId=1` → 1 campaign, 8 events, 41 interactions.

- **feat-049 — Charts: 3 new types (trend line, channel donut, employee bar)**
  - New BE: `TrendPointDto`, `ChannelBreakdownDto`, `EmployeeRankingDto`,
    `AnalyticsService.getInteractionsTrend / getChannelBreakdown /
    getTopEmployees`, and 3 new endpoints on `AnalyticsController`
    (`/trend`, `/channels`, `/employees`).
  - New FE models: `TrendPointModel`, `ChannelBreakdownModel`,
    `EmployeeRankingModel` in `analytics_models.dart`.
  - New FE repository methods + 3 `FutureProvider.family` providers
    keyed by `AnalyticsFilter`.
  - New widgets: `trend_line_chart.dart`, `channel_donut_chart.dart`,
    `employee_bar_chart.dart`.
  - `charts_section.dart` rewired as a `ConsumerWidget`; now displays 4
    sections (trend, outcome+channel, province+top schools, top employees)
    with shimmer loading and Vietnamese error states.
  - Verified all 3 BE endpoints return data; FE compiles cleanly.

- **feat-050 — Charts: modernize all 6 visuals (palette, tooltips, animations)**
  - `outcome_donut_chart.dart`, `province_bar_chart.dart`,
    `top_schools_bar_chart.dart` all rewritten to use `AppColors.chartColors`,
    `tooltipRoundedRadius: 8`, dividerColor grid lines, and Vietnamese
    empty-state widgets (icon + message).
  - New `base_chart_card.dart` provides `BaseChartCard` (600ms fade+slide
    entrance animation) and `ChartEmptyState` for reuse across all charts.
  - The 3 new charts from feat-049 already used the modern palette and
    tooltips so they're included in the unified look.

- **feat-051 — Analytics: collapsible sidebar layout replacing bottom bar**
  - New `analytics_sidebar.dart`:
    - `AnalyticsSidebar` widget renders either the full filter (280px) or
      an icon strip (72px).
    - `SidebarExpandedNotifier` (StateNotifier) persists the toggle to
      `SharedPreferences` under `analytics.sidebar.expanded` so the user's
      preferred layout survives restarts.
  - New `responsive_sidebar_layout.dart`:
    - `ResponsiveSidebarLayout` switches between the inline sidebar (>=900px)
      and a `Drawer` on mobile, with a hamburger button to open it.
  - `analytics_page.dart`: removed the bottom `FilterSection` Sliver and
    wrapped the page body in `ResponsiveSidebarLayout`. Charts now flow
    to the right of the sidebar on desktop.

### Verification

- `flutter analyze lib/`: **0 errors** (84 info hints only — all pre-existing
  `prefer_const_*`, `avoid_redundant_argument_values`, `deprecated_member_use`).
- `cd FE && flutter analyze lib/features/analytics/`: **0 errors** (17 info hints).
- `cd BE && docker-compose build backend`: **BUILD SUCCESS** (rebuilt twice —
  after feat-048 and after feat-049).
- Backend endpoints all return 200 OK with valid data; full table below.

| Endpoint | Sample request | Sample response |
|----------|---------------|-----------------|
| `GET /api/analytics/aggregate` | – | 22 campaigns, 127 events, 124 schools, 593 interactions |
| `GET /api/analytics/aggregate?schoolUid=79-224` | – | 1 school, 222 interactions, 1 province |
| `GET /api/analytics/aggregate?campaignId=1` | – | 1 campaign, 8 events, 41 interactions |
| `GET /api/analytics/trend?days=7` | – | 7 points; peak 485 on 2026-06-24 |
| `GET /api/analytics/channels` | – | EMAIL 139, ZALO 136, VISIT 133, EVENT 96, PHONE 86, MEETING 3 |
| `GET /api/analytics/employees` | – | 9 employees ranked (top: Dev Staff 147) |

### Files Changed

**Backend (3 files):**
- `BE/src/main/java/com/vnmap/campaign/controller/AnalyticsController.java`
- `BE/src/main/java/com/vnmap/campaign/service/AnalyticsService.java`
- 3 new DTOs: `TrendPointDto`, `ChannelBreakdownDto`, `EmployeeRankingDto`

**Frontend (15 files):**
- `FE/lib/app/router.dart` (parseMapArgs + AppShell props)
- `FE/lib/features/map/presentation/widgets/vietnam_map_view.dart` (_mapReady)
- `FE/lib/features/map/presentation/widgets/school_info_sheet.dart` (school→schools)
- `FE/lib/features/school/presentation/pages/school_detail_page.dart` (school→schools)
- `FE/lib/features/analytics/data/repositories/analytics_repository.dart` (filter params + 3 new methods)
- `FE/lib/features/analytics/presentation/providers/analytics_provider.dart` (AnalyticsFilter + family providers)
- `FE/lib/features/analytics/domain/models/analytics_models.dart` (3 new models)
- `FE/lib/features/analytics/presentation/pages/analytics_page.dart` (sidebar layout)
- `FE/lib/features/analytics/presentation/widgets/analytics_sidebar.dart` (NEW)
- `FE/lib/features/analytics/presentation/widgets/responsive_sidebar_layout.dart` (NEW)
- `FE/lib/features/analytics/presentation/widgets/base_chart_card.dart` (NEW)
- `FE/lib/features/analytics/presentation/widgets/trend_line_chart.dart` (NEW)
- `FE/lib/features/analytics/presentation/widgets/channel_donut_chart.dart` (NEW)
- `FE/lib/features/analytics/presentation/widgets/employee_bar_chart.dart` (NEW)
- `FE/lib/features/analytics/presentation/widgets/charts_section.dart` (rewired)
- `FE/lib/features/campaign/dashboard/widgets/outcome_donut_chart.dart` (palette + empty state)
- `FE/lib/features/campaign/dashboard/widgets/province_bar_chart.dart` (palette + tooltip)
- `FE/lib/features/campaign/dashboard/widgets/top_schools_bar_chart.dart` (palette + tooltip)
- `FE/lib/features/analytics/presentation/widgets/filter_section.dart` (cleanup unused import)

### Notes for Next Session

- feat-052 completed; feat-053 (sidebar nav) is next.
- Repository is ready for feat-053.
- Default user: `admin@vnmap.local` / `admin123`.

---

## feat-052 — Map Marker Fix (2026-06-24)

### Root Cause
`_mapReadyCompleter` in `vietnam_map_view.dart` only resolved inside `onPositionChanged` (user gesture), so `_geocodeAndShowSchools` never fired on direct navigation. Errors were silently swallowed via `debugPrint`.

### Changes Made

1. **`initState`**: Replaced `Completer` pattern with `WidgetsBinding.instance.addPostFrameCallback` — fires immediately on mount regardless of user gesture.
2. **`_geocodeAndShowSchools`**: Removed `!_mapReady` guard — fetch doesn't need MapController.
3. **`catch` block**: Replaced `debugPrint` with user-facing `SnackBar` + "Thử lại" action.

### Verification
- `flutter analyze lib/features/map/presentation/widgets/vietnam_map_view.dart`: **0 errors** (1 warning pre-existing, 7 info hints pre-existing)
- `flutter analyze lib/`: **84 issues** (same as baseline, no regressions)
- `_mapReady` + `onPositionChanged` pattern preserved for `_zoomToGeocoded` (MapController safety)

### Files Changed
- `FE/lib/features/map/presentation/widgets/vietnam_map_view.dart`

## feat-053 — Sidebar Navigation (2026-06-24)

### Root Cause
`_AppShell` in `router.dart` used `NavigationBar` with 7 items, violating Material Design `bottom-nav-limit` (max 5). No persistent sidebar existed on desktop.

### Changes Made

1. **`app_sidebar.dart`**: `AppSidebar` (240px expanded / 72px collapsed, `primaryContainer` highlight, tooltip on collapse) + `AppDrawer` (wraps sidebar in `Drawer` for mobile).
2. **`app_shell_scaffold.dart`**: `AppShellScaffold` uses `LayoutBuilder` — `Row([sidebar|content])` on desktop (>=900px), `Scaffold(drawer)` on mobile. `SidebarExpandedNotifier` persists collapse state to `SharedPreferences`.
3. **`router.dart`**: Replaced `_AppShell.build()` body with delegation to `AppShellScaffold`. Removed unused `theme_provider.dart` and `vietnam_map_view.dart` imports.

### Verification
- `flutter analyze lib/app/`: **0 errors, 0 warnings** (12 info hints only)
- `flutter analyze lib/`: **85 issues** (baseline 84; +1 pre-existing const hint)
- Removed legacy desktop split-pane (map+content side-by-side) — `MapPage` now handles its own wide-layout

### Files Changed
- `FE/lib/app/widgets/app_sidebar.dart` (NEW)
- `FE/lib/app/widgets/app_shell_scaffold.dart` (NEW)
- `FE/lib/app/router.dart`

### Next: feat-054 — Analytics Charts Loading/Error UI

---

## feat-054 — Analytics Charts Loading/Error (pending)





### Plan Registered (5 new features queued)

The detailed plan at `c:\Users\docao\.cursor\plans\analytics_charts_+_map_markers_+_modern_sidebar_ui_e0cf8ca0.plan.md` covers five workstreams:

1. **feat-047** — Map: auto-zoom on school navigation + wide-screen marker passthrough + SchoolInfoSheet `?schools=` fix.
2. **feat-048** — Analytics: convert `aggregateDashboardProvider` to `FutureProvider.family<…, AnalyticsFilter>`; add `?campaignId=&schoolUid=` to `/api/analytics/aggregate`.
3. **feat-049** — Charts: 3 new endpoints (`/trend`, `/channels`, `/employees`) + 3 new chart widgets (TrendLineChart, ChannelDonutChart, EmployeeBarChart).
4. **feat-050** — Charts: shared palette via `AppColors.chartColors`, modern tooltips, 600ms entrance animation, Vietnamese empty states, BaseChartCard wrapper.
5. **feat-051** — Analytics: collapsible 280/72px sidebar (persisted in SharedPreferences) replacing the bottom filter bar; mobile becomes a Drawer.

All five entries have been written to `feature_list.json` (now 49 features total).

### Execution Order (per `AGENTS.md` one-feature-at-a-time)

1. feat-047 (low risk, isolated to router + map widget + 1 line in sheet)
2. feat-048 (medium — BE SQL + FE Riverpod refactor)
3. feat-049 (medium — 3 new endpoints, 3 new widgets)
4. feat-050 (low — pure UI changes)
5. feat-051 (medium — new widgets + analytics_page.dart restructure)

Each session ends after `flutter analyze lib/` + `flutter build web --release` (FE) or `mvn -DskipTests package` (BE) passes, with `progress.md` updated and a single commit.

### Latest Changes

#### 1. Removed Dashboard tab from Campaign List
- File: `FE/lib/features/campaign/dashboard/pages/campaign_list_page.dart`
- Action: Removed the `FilledButton.icon` that navigated to `/campaigns/${id}/dashboard`.
- Reason: User requested dashboard to be moved to a dedicated Analytics page.

#### 2. Fixed Map Markers - On-Demand Only
- File: `FE/lib/features/map/presentation/widgets/vietnam_map_view.dart`
- Replaced `SchoolCoordinates` with `SchoolGeocode` model.
- Removed `_loadSchoolCoordinates` (the FAB that auto-loaded ALL schools).
- Markers now only render for schools that the user explicitly selected.
- Added `_SchoolMarkerWidget` adapted to the new `SchoolGeocode` type.

#### 3. Added "Show on Map" Buttons on Campaign Dashboard
- File: `FE/lib/features/campaign/dashboard/pages/campaign_dashboard_page.dart`
- New `_SchoolRowWithMap` widget renders a row per top school with an
  `IconButton(Icons.map_outlined)` that navigates to
  `/map?schools={schoolUid}`.

#### 4. OSM Geocoding - On-Demand Service
- New backend service: `BE/src/main/java/com/vnmap/campaign/service/OsmGeocodingService.java`
  - Calls OSM Nominatim API (`/search?format=json&limit=1&countrycodes=vn`).
  - Falls back to the commune centroid when OSM has no exact match.
  - **Coordinates are NOT persisted** — only returned for the current request.
- New DTO: `BE/src/main/java/com/vnmap/campaign/dto/SchoolGeocodeDto.java`.
- New endpoint: `POST /api/v1/schools/geocode` in `CampaignController.java`.
- New FE repository: `FE/lib/features/map/data/repositories/osm_geocoding_repository.dart`.
- New FE provider: `FE/lib/features/map/presentation/providers/osm_geocoding_provider.dart`.

#### 5. Backend Analytics API
- New service: `BE/src/main/java/com/vnmap/campaign/service/AnalyticsService.java`.
- New controller: `BE/src/main/java/com/vnmap/campaign/controller/AnalyticsController.java`.
- New DTO: `BE/src/main/java/com/vnmap/campaign/dto/AggregateDashboardDto.java`.
- New endpoint: `GET /api/analytics/aggregate` returning:
  - totalCampaigns, totalEvents, totalSchools, totalEmployees, totalInteractions
  - interactionsByOutcome (SUCCESSFUL, FOLLOW_UP, NO_RESPONSE, INTERESTED, NOT_INTERESTED)
  - interactionsByProvince (top 20)
  - topSchools (top 10)

#### 6. Focused Sample Data
- File: `BE/scripts/sample_data.sql` - completely rewritten.
- All inserts use `ON CONFLICT DO NOTHING` / `WHERE NOT EXISTS` to be idempotent.
- Specific named entities:
  - 10 employees (Vietnamese names, distinct roles).
  - 10 app_users linked to employees.
  - 10 named campaigns with explicit owners.
  - 30 events (3 per campaign) with named provinces.
  - Event-school links (~3 per event).
  - Event-assignments (2 staff per event).
  - 200 named students distributed across existing schools.
  - 5 interactions per event (varied outcomes).
  - Student registrations distributed across campaigns.

### Verification Results
- `flutter analyze lib/`: 0 errors (info hints only).
- `flutter build web --release`: SUCCESS.
- `docker-compose build backend`: SUCCESS.
- Backend `/actuator/health`: UP.
- `POST /api/v1/schools/geocode` works:
  - 79-224 → fallback (commune centroid Phường Tân Tạo).
  - 01-003 → OSM exact match (21.1291558, 105.7721668).
- `GET /api/analytics/aggregate` works:
  - 22 campaigns, 127 events, 4943 schools, 10 employees, 593 interactions.
- Flutter is running on port 3000.

### Pre-existing Test Errors (NOT in lib/)
Pre-existing test/ files have errors (`responsive_test.dart`, `result_test.dart`)
unrelated to today's changes. Leave as-is.

### Files Changed
- `FE/lib/features/campaign/dashboard/pages/campaign_list_page.dart` (removed dashboard tab)
- `FE/lib/features/campaign/dashboard/pages/campaign_dashboard_page.dart` (show on map button)
- `FE/lib/features/map/presentation/widgets/vietnam_map_view.dart` (on-demand markers)
- `FE/lib/features/map/data/repositories/osm_geocoding_repository.dart` (NEW)
- `FE/lib/features/map/presentation/providers/osm_geocoding_provider.dart` (NEW)
- `BE/src/main/java/com/vnmap/campaign/service/OsmGeocodingService.java` (NEW)
- `BE/src/main/java/com/vnmap/campaign/dto/SchoolGeocodeDto.java` (NEW)
- `BE/src/main/java/com/vnmap/campaign/service/AnalyticsService.java` (NEW)
- `BE/src/main/java/com/vnmap/campaign/controller/AnalyticsController.java` (NEW)
- `BE/src/main/java/com/vnmap/campaign/dto/AggregateDashboardDto.java` (NEW)
- `BE/src/main/java/com/vnmap/campaign/controller/CampaignController.java` (new endpoint)
- `BE/scripts/sample_data.sql` (focused data rewrite)

### Notes for Next Session
- Default user: `admin@vnmap.local` / `admin123`.
- OSM geocoding requires network access to nominatim.openstreetmap.org.
- Fallback path uses `commune_code` from the `schools` table.

---

## feat-053 — Sidebar Navigation (2026-06-24)

### Root Cause
`_AppShell` used `NavigationBar` with 7 items violating Material Design `bottom-nav-limit` (max 5). No persistent sidebar on desktop.

### Changes Made
1. **`app_sidebar.dart`**: `AppSidebar` (240px / 72px collapsed, `primaryContainer` highlight) + `AppDrawer` (wraps sidebar for mobile).
2. **`app_shell_scaffold.dart`**: `AppShellScaffold` uses `LayoutBuilder` — `Row` on desktop >=900px, `Scaffold(drawer)` on mobile. `SidebarExpandedNotifier` persists collapse to `SharedPreferences`.
3. **`router.dart`**: Replaced `_AppShell.build()` with delegation to `AppShellScaffold`. Removed legacy desktop split-pane (map+content side-by-side); `MapPage` handles its own wide-layout.

### Verification
- `flutter analyze lib/app/`: **0 errors, 0 warnings** (12 info hints)
- `flutter analyze lib/`: **85 issues** (baseline 84)

### Files Changed
- `FE/lib/app/widgets/app_sidebar.dart` (NEW)
- `FE/lib/app/widgets/app_shell_scaffold.dart` (NEW)
- `FE/lib/app/router.dart`

---

## feat-054 — Analytics Charts Loading/Error (2026-06-24)

### Root Cause
`analytics_page.dart` lines 74-77 rendered `SizedBox.shrink()` during loading/error — visible void below KPI section.

### Changes Made
- Added `_ChartsLoadingPlaceholder`: 2 `BaseChartCard` with `ChartEmptyState` message "Đang tải dữ liệu phân tích…"
- Added `_ChartsErrorPlaceholder`: `BaseChartCard` with error subtitle + `FilledButton.icon` retry calling `ref.invalidate(analyticsFilterProvider)`
- Replaced charts `SliverToBoxAdapter` to route through `.when(loading/error/data)`

### Verification
- `flutter analyze lib/features/analytics/`: **0 errors** (19 info hints)
- `flutter analyze lib/`: **87 issues** (baseline 84, +3 pre-existing info hints from new widgets)

### Files Changed
- `FE/lib/features/analytics/presentation/pages/analytics_page.dart`

---

## feat-055 — Dark Mode Sweep (2026-06-24)

### Root Cause
Hardcoded `Colors.white/black/grey` and hex values across ~15 files broke dark mode visually.

### Changes Made
| File | Changes |
|------|---------|
| `vietnam_map_view.dart` | Dark CartoDB tiles, location sheet bg/icon/button/text, event focus badge, school count badge, loading overlays, island label text+shadow |
| `school_info_sheet.dart` | Sheet bg, primary button, `_buildInfoRow` icon/label colors |
| `province_list_body.dart` | Search bar bg, breadcrumb bg, school item bg, all grey hints/icons → `onSurfaceVariant` |
| `school_detail_page.dart` | `_InfoRow` label → `onSurfaceVariant` |
| `event_detail_page.dart` | `_InfoRow` label, time icon/text → `onSurfaceVariant` |
| `weather_card.dart` | Gradient + shadow → slate-900/blue-900 in dark mode |
| `weather_page.dart` | Refresh icon → `onPrimary` |
| `campaign_dashboard_page.dart` | KPI hex colors → `AppColors.primary/tertiary/warning/info` |
| `admin_users_page.dart` | Role chips → `AppColors.error/warning/info/success`; status chips → `AppColors.success/warning` |

### Verification
- `flutter analyze lib/`: **80 issues** (baseline 84, net -4)
- `flutter build web --release`: **exit 0**

### Files Changed
9 files, 467 insertions, 250 deletions

---

## feat-056 — Admin Data Table (2026-06-24)

### Root Cause
`admin_users_page.dart` used `ListView.separated` of `Card`/`ListTile` items with a `PopupMenuButton` — no sort, no search, no filter, no pagination.

### Changes Made
- Added `data_table_2: ^2.7.2` to `pubspec.yaml`
- Created `user_chips.dart`: `UserRoleChip` + `UserStatusChip` shared widgets
- Created `user_admin_table.dart`: `UserAdminTable` stateful widget with `PaginatedDataTable2` — columns for ID, Email (search+sort), Vai trò, Trạng thái, Employee ID, Student ID, Thao tác. Debounced search + Role/Status dropdowns. `_UserDataSource extends DataTableSource`. Inline `IconButton` actions (edit, toggle status, delete).
- Replaced `ListView` in `admin_users_page.dart` with `UserAdminTable`, delegating actions through `UserAction` enum.

### Verification
- `flutter analyze lib/features/admin/`: **0 errors, 0 warnings** (5 info hints)
- `flutter analyze lib/`: **81 issues** (baseline 84)
- `flutter build web --release`: **exit 0**

### Files Changed
- `FE/pubspec.yaml`
- `FE/lib/features/admin/presentation/widgets/user_admin_table.dart` (NEW)
- `FE/lib/features/admin/presentation/widgets/user_chips.dart` (NEW)
- `FE/lib/features/admin/presentation/pages/admin_users_page.dart`

---

## feat-057 — Role-Based Bento Home Pages (2026-06-30)

### Summary
Built 4 role-specific Bento Grid home pages: Manager, Staff, Student, Admin. Each has KPIs, charts, and role-appropriate content. Reuses existing `BentoCard`, `KpiCard`, `StatusChip`, `TrendLineChart`, `OutcomeDonutChart`, `ProvinceBarChart`, `TopSchoolsBarChart`, `AppShellScaffold` from the existing codebase.

### Architecture
- `FE/lib/features/home/` — new feature directory
  - `presentation/widgets/home_grid.dart` — 12-column responsive grid (spans 3/4/6/8/12)
  - `presentation/widgets/home_page_shell.dart` — reusable shell: title + subtitle + badge + quick actions
  - `data/providers/` — 4 providers: `manager_home_provider`, `student_home_provider`, `staff_home_provider`, `admin_home_provider`
  - `presentation/pages/` — 4 pages: `manager_home_page`, `staff_home_page`, `student_home_page`, `admin_home_page`
- `FE/lib/app/router.dart` — added 4 routes (`/home/manager`, `/home/staff`, `/home/student`, `/home/admin`) + `_RoleGate` guards + sidebar nav items ("Tổng quan")
- `FE/lib/features/auth/shared/auth_routes.dart` — updated `landingPathForRole` to redirect to `/home/{role}` after login

### What Existed vs What Was Built
| What | Status |
|---|---|
| `BentoCard` + `KpiCard` + `StatusChip` + `BentoGrid` | Already existed in `FE/lib/core/widgets/bento_card.dart` |
| `AppShellScaffold` + `AppSidebar` | Already existed in `FE/lib/app/widgets/` |
| `aggregateDashboardProvider` + `trendProvider` | Already existed in `analytics_provider.dart` |
| `TrendLineChart`, `OutcomeDonutChart`, `ProvinceBarChart`, `TopSchoolsBarChart` | Already existed |
| `myRegistrationsProvider` | Already existed in `campaign_provider.dart` |
| Home pages + routes + sidebar wiring | **NEW — built this session** |

### Backend Gaps Noted
- `GET /api/v1/employees/{id}/stats` — needed for Staff home (currently derived from campaign events)
- `GET /api/v1/admin/system-stats` — needed for Admin home (currently mocked)

### Verification
- `flutter analyze lib/`: 0 errors
- `flutter build web --release`: exit 0

### Files Changed (14 files)
| File | Action |
|---|---|
| `FE/lib/features/home/presentation/widgets/home_grid.dart` | CREATE |
| `FE/lib/features/home/presentation/widgets/home_page_shell.dart` | CREATE |
| `FE/lib/features/home/data/providers/manager_home_provider.dart` | CREATE |
| `FE/lib/features/home/data/providers/student_home_provider.dart` | CREATE |
| `FE/lib/features/home/data/providers/staff_home_provider.dart` | CREATE |
| `FE/lib/features/home/data/providers/admin_home_provider.dart` | CREATE |
| `FE/lib/features/home/presentation/pages/manager_home_page.dart` | CREATE |
| `FE/lib/features/home/presentation/pages/staff_home_page.dart` | CREATE |
| `FE/lib/features/home/presentation/pages/student_home_page.dart` | CREATE |
| `FE/lib/features/home/presentation/pages/admin_home_page.dart` | CREATE |
| `FE/lib/app/router.dart` | MODIFY — 4 routes + sidebar nav + `_homePathFor` helper |
| `FE/lib/features/auth/shared/auth_routes.dart` | MODIFY — updated `landingPathForRole` |
| `feature_list.json` | MODIFY — added feat-057 + backend gaps |
| `progress.md` | MODIFY — added this session log |

---

## ALL 5 PLAN STEPS COMPLETED

---

## Bug Fixes — 2026-06-30

### Issue 1: RenderFlex Assertion Errors (mouse_tracker)

**Root Cause**: `crossAxisAlignment: CrossAxisAlignment.stretch` on `Row` widgets inside `_HomeGridRow` in all 4 role-based home pages. `Row` with `stretch` tries to make all children match the tallest child's height — but `BentoCard`/`GridView.count` inside `Expanded` children have unbounded intrinsic heights, causing the Flutter assertion:
`RenderFlex children have non-zero flex but incoming height constraints are unbounded`.

**Fix Applied** (4 files):
- `admin_home_page.dart` — `_HomeGridRow` Row
- `manager_home_page.dart` — `_HomeGridRow` Row
- `staff_home_page.dart` — `_HomeGridRow` Row
- `student_home_page.dart` — `_HomeGridRow` Row

Changed `crossAxisAlignment: CrossAxisAlignment.stretch` → `crossAxisAlignment: CrossAxisAlignment.start` in all 4 files. The layout still fills available width correctly via `Expanded(flex: spans[i])`.

### Issue 2: Map Hidden on /map Route

**Root Cause**: `MapPage.build()` had two branches:
- Wide (>600px): Only showed `ProvinceListBody()` — `VietnamMapView` was completely absent.
- Mobile (<600px): Correctly showed `VietnamMapView` + draggable sheet.

**Fix Applied** (`map_page.dart`):
Wide-screen now shows: `Row([VietnamMapView (flex:3) | divider | ProvinceListBody (flex:2)])`, respecting dark/light theme. Also fixed mobile sheet background to use `Theme.of(context).brightness` for dark mode.

### Issue 3: KPI Card Layout Broken (Admin Home Screenshot Bug)

**Root Cause**: Two compounding bugs:
1. `KpiCard` used `showAccent: true` which wraps the child in a `Column` with `Expanded(child: child)`. But `GridView.count` constrains children to a fixed aspect-ratio box — `Expanded` inside a bounded box collapses to zero height, making the card body invisible.
2. `_KpiGrid` in `admin_home_page.dart` used `childAspectRatio: columns >= 4 ? 1.4 : 1.6` but computed `columns` as 6 on wide screens (correct) and 3 on medium — however the 6-column layout on wide screens made cards too narrow.

**Fix Applied**:
1. `bento_card.dart` — `KpiCard`: removed `showAccent` + `accentColor` prop from `BentoCard`. Added accent as a simple 3×32px colored bar at the top of the card body (inside the `Column`, before the icon row). No more `Expanded` conflict.
2. All 4 home pages — `_KpiGrid`/`_KpiRow`: replaced `GridView.count` (fixed aspect ratio) with `Wrap` (free height) + `SizedBox(width: cardWidth)` per card. Cards now size to their content.

**Affected files**: `admin_home_page.dart`, `manager_home_page.dart`, `staff_home_page.dart`, `student_home_page.dart`, `bento_card.dart`

### Issue 4: Blank Body — Double-Expanded Bug

**Root Cause**: `HomePageShell` wraps its `child` in `Expanded(child: child)`. But `HomePageShell` is already passed as `body` to `AppShellScaffold`, which ALSO wraps `body` in `Expanded(child: body)`. Two `Expanded` widgets in sequence gives the inner `Expanded` zero available space — entire body collapses to zero height, completely blank.

**Fix Applied**: Removed the inner `Expanded(` from `home_page_shell.dart` line 97. The `Expanded` from `AppShellScaffold` is sufficient.

**Affected files**: `home_page_shell.dart`

### Issue 5: Missing Donut Chart

**Root Cause**: `_UserRoleCard` used a placeholder `CircularProgressIndicator(value: 1.0)` instead of real chart data.

**Fix Applied**: Replaced placeholder with `fl_chart` `PieChart` showing actual user role distribution. Added `SingleChildScrollView` wrapping the page content so all sections are scrollable and visible.

**Affected files**: `admin_home_page.dart`

### Issue 6: RenderFlex Assertion — IntrinsicHeight + Row + stretch

**Root Cause**: `home_grid.dart` used `IntrinsicHeight(child: Row(crossAxisAlignment.stretch, children: [Expanded...] ))`. `IntrinsicHeight` asks a `Row` to compute its intrinsic height, but `Row` with `Expanded` children has unbounded height — `CrossAxisAlignment.stretch` then forces all children to fill that unbounded height, triggering:
`RenderFlex children have non-zero flex but incoming height constraints are unbounded`.

**Fix Applied**:
- `home_grid.dart`: removed `IntrinsicHeight` wrapper; changed `crossAxisAlignment.stretch` → `crossAxisAlignment.start` on both the `Row` in `_buildRows` and `HomeGridRow`.
- `responsive_sidebar_layout.dart`: changed `Row(crossAxisAlignment.stretch)` → `Row(crossAxisAlignment.start)` in `_WideLayout`.

**Affected files**: `home_grid.dart`, `responsive_sidebar_layout.dart`

### Issue 7: Unbounded chartSize NaN → RenderFlex Cascade

**Root Cause**: `_UserRoleCard` used `LayoutBuilder` to compute `chartSize = c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight`. But `_UserRoleCard` was inside `Expanded` in a `Row`, giving unbounded height. So `c.maxHeight = Infinity`, `chartSize = Infinity`, `SizedBox(width: Infinity, height: Infinity)` → NaN → 0. The downstream `Column` with `Expanded(child: chart)` then caused RenderFlex with unbounded height constraints.

`_CampaignStatusCard` had `Expanded(child: Column(...))` inside a `BentoCard` which is inside `Expanded` in `Row` → unbounded height → RenderFlex.

**Fix Applied**:
- `_UserRoleCard`: replaced unbounded `LayoutBuilder` with a fixed `SizedBox(height: 160)` containing a 160×160 `PieChart` with fixed `centerSpaceRadius: 24` and `radius: 28`. Removed `LayoutBuilder` entirely.
- `_CampaignStatusCard`: removed the outer `Expanded(` wrapping the inner `Column(...)`.

**Affected files**: `admin_home_page.dart`

### Issue 8: BentoCard Container 0-height Collapse → RenderFlex Cascade

**Root Cause**: `BentoCard` used a plain `Container` (no explicit width/height). When placed inside `Expanded` in a `Row`, the `Container` had constraints `(0 <= h <= Infinity)`. The internal `Column` had `mainAxisSize: max`, so it tried to expand to fill the **Infinity** height — triggering RenderFlex with unbounded constraints. Then `SizedBox(BoxConstraints.loose)` at `box.dart:2251` capped `Infinity → 0`, creating NaN cascade.

**Fix Applied**: Wrapped both `Container` variants in `BentoCard` with `ConstrainedBox(constraints: BoxConstraints.tightForFinite())`. This forces the Container to adopt the **allocated** height from its parent (the Row's flexed space), rather than trying to determine its own size. Height is finite (from the Row), width is determined by flex weights — both are now bounded.

**Affected files**: `bento_card.dart`

### Issue 9: Column+Expanded(ListView) RenderFlex in All Home Pages

**Root Cause**: All home pages (admin, staff, student, manager) had BentoCard containing a Column with `mainAxisSize: max` (default) and a child widget using `Expanded(child: ListView/Column)`. When BentoCard's Container had no explicit size and the Row passed `(0 <= h <= Infinity)`, the Column with `mainAxisSize: max` tried to fill infinity → RenderFlex fired → box.dart:2251 capped `Infinity → 0` → cascade of MISSING sizes.

**Fix Applied** (all 4 home pages):
1. Set `mainAxisSize: MainAxisSize.min` on all BentoCard inner Columns
2. Replaced `Expanded(child: ListView)` with `Flexible(child: SizedBox(height: 220))` — gives the scrollable a fixed bounded height, eliminating the unbounded constraint problem
3. Replaced `Expanded(child: Column)` with `Flexible(child: SizedBox(height: 160/200))`

**Cards Fixed**:
- `admin_home_page.dart`: `_RecentUsersCard`
- `staff_home_page.dart`: `_AssignedEventsCard`, `_CampaignBreakdownCard`, `_PersonalOutcomeCard`
- `student_home_page.dart`: `_RegistrationsCard`
- `manager_home_page.dart`: `_RecentActivityCard`

**Verification**:
- `flutter analyze`: **0 errors** (10 info-level lints)
- `flutter run -d chrome`: **zero RenderFlex errors, zero box.dart:2251 assertions, zero mouse_tracker errors after 211+ seconds**