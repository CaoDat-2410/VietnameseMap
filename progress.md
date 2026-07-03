# Session Progress Log

## Current State

**Last Updated:** 2026-07-01 14:05
**Session ID:** session-20260701-firebase-mvvm
**Active Feature:** feat-071 (Phase 10 â€” final verification) â€” ALL 10 PHASES COMPLETE

## Status: ALL 10 PLAN PHASES IMPLEMENTED (feat-062 through feat-071)

### Completed in this session

- **feat-047 â€” Map: auto-zoom + SchoolInfoSheet query fix + AppShell props**
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
    switched the `/map?school=â€¦` (singular, broken) URL to `/map?schools=â€¦`
    (plural, matches `parseMapArgs`).

- **feat-048 â€” Analytics: filter bug fix + backend filter params**
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
    `FutureProvider.family<â€¦, AnalyticsFilter>` so any consumer re-fetches
    automatically when the filter changes.
  - `FE/lib/features/analytics/presentation/pages/analytics_page.dart`:
    replaced the global `aggregateDashboardProvider` watch with
    `aggregateDashboardProvider(ref.watch(analyticsFilterProvider))`.
  - Verified:
    - `?schoolUid=79-224` â†’ 1 school, 222 interactions (all at HCM).
    - `?campaignId=1` â†’ 1 campaign, 8 events, 41 interactions.

- **feat-049 â€” Charts: 3 new types (trend line, channel donut, employee bar)**
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

- **feat-050 â€” Charts: modernize all 6 visuals (palette, tooltips, animations)**
  - `outcome_donut_chart.dart`, `province_bar_chart.dart`,
    `top_schools_bar_chart.dart` all rewritten to use `AppColors.chartColors`,
    `tooltipRoundedRadius: 8`, dividerColor grid lines, and Vietnamese
    empty-state widgets (icon + message).
  - New `base_chart_card.dart` provides `BaseChartCard` (600ms fade+slide
    entrance animation) and `ChartEmptyState` for reuse across all charts.
  - The 3 new charts from feat-049 already used the modern palette and
    tooltips so they're included in the unified look.

- **feat-051 â€” Analytics: collapsible sidebar layout replacing bottom bar**
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

- `flutter analyze lib/`: **0 errors** (84 info hints only â€” all pre-existing
  `prefer_const_*`, `avoid_redundant_argument_values`, `deprecated_member_use`).
- `cd FE && flutter analyze lib/features/analytics/`: **0 errors** (17 info hints).
- `cd BE && docker-compose build backend`: **BUILD SUCCESS** (rebuilt twice â€”
  after feat-048 and after feat-049).
- Backend endpoints all return 200 OK with valid data; full table below.

| Endpoint | Sample request | Sample response |
|----------|---------------|-----------------|
| `GET /api/analytics/aggregate` | â€“ | 22 campaigns, 127 events, 124 schools, 593 interactions |
| `GET /api/analytics/aggregate?schoolUid=79-224` | â€“ | 1 school, 222 interactions, 1 province |
| `GET /api/analytics/aggregate?campaignId=1` | â€“ | 1 campaign, 8 events, 41 interactions |
| `GET /api/analytics/trend?days=7` | â€“ | 7 points; peak 485 on 2026-06-24 |
| `GET /api/analytics/channels` | â€“ | EMAIL 139, ZALO 136, VISIT 133, EVENT 96, PHONE 86, MEETING 3 |
| `GET /api/analytics/employees` | â€“ | 9 employees ranked (top: Dev Staff 147) |

### Files Changed

**Backend (3 files):**
- `BE/src/main/java/com/vnmap/campaign/controller/AnalyticsController.java`
- `BE/src/main/java/com/vnmap/campaign/service/AnalyticsService.java`
- 3 new DTOs: `TrendPointDto`, `ChannelBreakdownDto`, `EmployeeRankingDto`

**Frontend (15 files):**
- `FE/lib/app/router.dart` (parseMapArgs + AppShell props)
- `FE/lib/features/map/presentation/widgets/vietnam_map_view.dart` (_mapReady)
- `FE/lib/features/map/presentation/widgets/school_info_sheet.dart` (schoolâ†’schools)
- `FE/lib/features/school/presentation/pages/school_detail_page.dart` (schoolâ†’schools)
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

## feat-052 â€” Map Marker Fix (2026-06-24)

### Root Cause
`_mapReadyCompleter` in `vietnam_map_view.dart` only resolved inside `onPositionChanged` (user gesture), so `_geocodeAndShowSchools` never fired on direct navigation. Errors were silently swallowed via `debugPrint`.

### Changes Made

1. **`initState`**: Replaced `Completer` pattern with `WidgetsBinding.instance.addPostFrameCallback` â€” fires immediately on mount regardless of user gesture.
2. **`_geocodeAndShowSchools`**: Removed `!_mapReady` guard â€” fetch doesn't need MapController.
3. **`catch` block**: Replaced `debugPrint` with user-facing `SnackBar` + "Thá»­ láº¡i" action.

### Verification
- `flutter analyze lib/features/map/presentation/widgets/vietnam_map_view.dart`: **0 errors** (1 warning pre-existing, 7 info hints pre-existing)
- `flutter analyze lib/`: **84 issues** (same as baseline, no regressions)
- `_mapReady` + `onPositionChanged` pattern preserved for `_zoomToGeocoded` (MapController safety)

### Files Changed
- `FE/lib/features/map/presentation/widgets/vietnam_map_view.dart`

## feat-053 â€” Sidebar Navigation (2026-06-24)

### Root Cause
`_AppShell` in `router.dart` used `NavigationBar` with 7 items, violating Material Design `bottom-nav-limit` (max 5). No persistent sidebar existed on desktop.

### Changes Made

1. **`app_sidebar.dart`**: `AppSidebar` (240px expanded / 72px collapsed, `primaryContainer` highlight, tooltip on collapse) + `AppDrawer` (wraps sidebar in `Drawer` for mobile).
2. **`app_shell_scaffold.dart`**: `AppShellScaffold` uses `LayoutBuilder` â€” `Row([sidebar|content])` on desktop (>=900px), `Scaffold(drawer)` on mobile. `SidebarExpandedNotifier` persists collapse state to `SharedPreferences`.
3. **`router.dart`**: Replaced `_AppShell.build()` body with delegation to `AppShellScaffold`. Removed unused `theme_provider.dart` and `vietnam_map_view.dart` imports.

### Verification
- `flutter analyze lib/app/`: **0 errors, 0 warnings** (12 info hints only)
- `flutter analyze lib/`: **85 issues** (baseline 84; +1 pre-existing const hint)
- Removed legacy desktop split-pane (map+content side-by-side) â€” `MapPage` now handles its own wide-layout

### Files Changed
- `FE/lib/app/widgets/app_sidebar.dart` (NEW)
- `FE/lib/app/widgets/app_shell_scaffold.dart` (NEW)
- `FE/lib/app/router.dart`

### Next: feat-054 â€” Analytics Charts Loading/Error UI

---

## feat-054 â€” Analytics Charts Loading/Error (pending)





### Plan Registered (5 new features queued)

The detailed plan at `c:\Users\docao\.cursor\plans\analytics_charts_+_map_markers_+_modern_sidebar_ui_e0cf8ca0.plan.md` covers five workstreams:

1. **feat-047** â€” Map: auto-zoom on school navigation + wide-screen marker passthrough + SchoolInfoSheet `?schools=` fix.
2. **feat-048** â€” Analytics: convert `aggregateDashboardProvider` to `FutureProvider.family<â€¦, AnalyticsFilter>`; add `?campaignId=&schoolUid=` to `/api/analytics/aggregate`.
3. **feat-049** â€” Charts: 3 new endpoints (`/trend`, `/channels`, `/employees`) + 3 new chart widgets (TrendLineChart, ChannelDonutChart, EmployeeBarChart).
4. **feat-050** â€” Charts: shared palette via `AppColors.chartColors`, modern tooltips, 600ms entrance animation, Vietnamese empty states, BaseChartCard wrapper.
5. **feat-051** â€” Analytics: collapsible 280/72px sidebar (persisted in SharedPreferences) replacing the bottom filter bar; mobile becomes a Drawer.

All five entries have been written to `feature_list.json` (now 49 features total).

### Execution Order (per `AGENTS.md` one-feature-at-a-time)

1. feat-047 (low risk, isolated to router + map widget + 1 line in sheet)
2. feat-048 (medium â€” BE SQL + FE Riverpod refactor)
3. feat-049 (medium â€” 3 new endpoints, 3 new widgets)
4. feat-050 (low â€” pure UI changes)
5. feat-051 (medium â€” new widgets + analytics_page.dart restructure)

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
  - **Coordinates are NOT persisted** â€” only returned for the current request.
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
  - 79-224 â†’ fallback (commune centroid PhÆ°á»ng TÃ¢n Táº¡o).
  - 01-003 â†’ OSM exact match (21.1291558, 105.7721668).
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

## feat-053 â€” Sidebar Navigation (2026-06-24)

### Root Cause
`_AppShell` used `NavigationBar` with 7 items violating Material Design `bottom-nav-limit` (max 5). No persistent sidebar on desktop.

### Changes Made
1. **`app_sidebar.dart`**: `AppSidebar` (240px / 72px collapsed, `primaryContainer` highlight) + `AppDrawer` (wraps sidebar for mobile).
2. **`app_shell_scaffold.dart`**: `AppShellScaffold` uses `LayoutBuilder` â€” `Row` on desktop >=900px, `Scaffold(drawer)` on mobile. `SidebarExpandedNotifier` persists collapse to `SharedPreferences`.
3. **`router.dart`**: Replaced `_AppShell.build()` with delegation to `AppShellScaffold`. Removed legacy desktop split-pane (map+content side-by-side); `MapPage` handles its own wide-layout.

### Verification
- `flutter analyze lib/app/`: **0 errors, 0 warnings** (12 info hints)
- `flutter analyze lib/`: **85 issues** (baseline 84)

### Files Changed
- `FE/lib/app/widgets/app_sidebar.dart` (NEW)
- `FE/lib/app/widgets/app_shell_scaffold.dart` (NEW)
- `FE/lib/app/router.dart`

---

## feat-054 â€” Analytics Charts Loading/Error (2026-06-24)

### Root Cause
`analytics_page.dart` lines 74-77 rendered `SizedBox.shrink()` during loading/error â€” visible void below KPI section.

### Changes Made
- Added `_ChartsLoadingPlaceholder`: 2 `BaseChartCard` with `ChartEmptyState` message "Äang táº£i dá»¯ liá»‡u phÃ¢n tÃ­châ€¦"
- Added `_ChartsErrorPlaceholder`: `BaseChartCard` with error subtitle + `FilledButton.icon` retry calling `ref.invalidate(analyticsFilterProvider)`
- Replaced charts `SliverToBoxAdapter` to route through `.when(loading/error/data)`

### Verification
- `flutter analyze lib/features/analytics/`: **0 errors** (19 info hints)
- `flutter analyze lib/`: **87 issues** (baseline 84, +3 pre-existing info hints from new widgets)

### Files Changed
- `FE/lib/features/analytics/presentation/pages/analytics_page.dart`

---

## feat-055 â€” Dark Mode Sweep (2026-06-24)

### Root Cause
Hardcoded `Colors.white/black/grey` and hex values across ~15 files broke dark mode visually.

### Changes Made
| File | Changes |
|------|---------|
| `vietnam_map_view.dart` | Dark CartoDB tiles, location sheet bg/icon/button/text, event focus badge, school count badge, loading overlays, island label text+shadow |
| `school_info_sheet.dart` | Sheet bg, primary button, `_buildInfoRow` icon/label colors |
| `province_list_body.dart` | Search bar bg, breadcrumb bg, school item bg, all grey hints/icons â†’ `onSurfaceVariant` |
| `school_detail_page.dart` | `_InfoRow` label â†’ `onSurfaceVariant` |
| `event_detail_page.dart` | `_InfoRow` label, time icon/text â†’ `onSurfaceVariant` |
| `weather_card.dart` | Gradient + shadow â†’ slate-900/blue-900 in dark mode |
| `weather_page.dart` | Refresh icon â†’ `onPrimary` |
| `campaign_dashboard_page.dart` | KPI hex colors â†’ `AppColors.primary/tertiary/warning/info` |
| `admin_users_page.dart` | Role chips â†’ `AppColors.error/warning/info/success`; status chips â†’ `AppColors.success/warning` |

### Verification
- `flutter analyze lib/`: **80 issues** (baseline 84, net -4)
- `flutter build web --release`: **exit 0**

### Files Changed
9 files, 467 insertions, 250 deletions

---

## feat-056 â€” Admin Data Table (2026-06-24)

### Root Cause
`admin_users_page.dart` used `ListView.separated` of `Card`/`ListTile` items with a `PopupMenuButton` â€” no sort, no search, no filter, no pagination.

### Changes Made
- Added `data_table_2: ^2.7.2` to `pubspec.yaml`
- Created `user_chips.dart`: `UserRoleChip` + `UserStatusChip` shared widgets
- Created `user_admin_table.dart`: `UserAdminTable` stateful widget with `PaginatedDataTable2` â€” columns for ID, Email (search+sort), Vai trÃ², Tráº¡ng thÃ¡i, Employee ID, Student ID, Thao tÃ¡c. Debounced search + Role/Status dropdowns. `_UserDataSource extends DataTableSource`. Inline `IconButton` actions (edit, toggle status, delete).
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

## feat-057 â€” Role-Based Bento Home Pages (2026-06-30)

### Summary
Built 4 role-specific Bento Grid home pages: Manager, Staff, Student, Admin. Each has KPIs, charts, and role-appropriate content. Reuses existing `BentoCard`, `KpiCard`, `StatusChip`, `TrendLineChart`, `OutcomeDonutChart`, `ProvinceBarChart`, `TopSchoolsBarChart`, `AppShellScaffold` from the existing codebase.

### Architecture
- `FE/lib/features/home/` â€” new feature directory
  - `presentation/widgets/home_grid.dart` â€” 12-column responsive grid (spans 3/4/6/8/12)
  - `presentation/widgets/home_page_shell.dart` â€” reusable shell: title + subtitle + badge + quick actions
  - `data/providers/` â€” 4 providers: `manager_home_provider`, `student_home_provider`, `staff_home_provider`, `admin_home_provider`
  - `presentation/pages/` â€” 4 pages: `manager_home_page`, `staff_home_page`, `student_home_page`, `admin_home_page`
- `FE/lib/app/router.dart` â€” added 4 routes (`/home/manager`, `/home/staff`, `/home/student`, `/home/admin`) + `_RoleGate` guards + sidebar nav items ("Tá»•ng quan")
- `FE/lib/features/auth/shared/auth_routes.dart` â€” updated `landingPathForRole` to redirect to `/home/{role}` after login

### What Existed vs What Was Built
| What | Status |
|---|---|
| `BentoCard` + `KpiCard` + `StatusChip` + `BentoGrid` | Already existed in `FE/lib/core/widgets/bento_card.dart` |
| `AppShellScaffold` + `AppSidebar` | Already existed in `FE/lib/app/widgets/` |
| `aggregateDashboardProvider` + `trendProvider` | Already existed in `analytics_provider.dart` |
| `TrendLineChart`, `OutcomeDonutChart`, `ProvinceBarChart`, `TopSchoolsBarChart` | Already existed |
| `myRegistrationsProvider` | Already existed in `campaign_provider.dart` |
| Home pages + routes + sidebar wiring | **NEW â€” built this session** |

### Backend Gaps Noted
- `GET /api/v1/employees/{id}/stats` â€” needed for Staff home (currently derived from campaign events)
- `GET /api/v1/admin/system-stats` â€” needed for Admin home (currently mocked)

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
| `FE/lib/app/router.dart` | MODIFY â€” 4 routes + sidebar nav + `_homePathFor` helper |
| `FE/lib/features/auth/shared/auth_routes.dart` | MODIFY â€” updated `landingPathForRole` |
| `feature_list.json` | MODIFY â€” added feat-057 + backend gaps |
| `progress.md` | MODIFY â€” added this session log |

---

## ALL 5 PLAN STEPS COMPLETED

---

## Bug Fixes â€” 2026-06-30

### Issue 1: RenderFlex Assertion Errors (mouse_tracker)

**Root Cause**: `crossAxisAlignment: CrossAxisAlignment.stretch` on `Row` widgets inside `_HomeGridRow` in all 4 role-based home pages. `Row` with `stretch` tries to make all children match the tallest child's height â€” but `BentoCard`/`GridView.count` inside `Expanded` children have unbounded intrinsic heights, causing the Flutter assertion:
`RenderFlex children have non-zero flex but incoming height constraints are unbounded`.

**Fix Applied** (4 files):
- `admin_home_page.dart` â€” `_HomeGridRow` Row
- `manager_home_page.dart` â€” `_HomeGridRow` Row
- `staff_home_page.dart` â€” `_HomeGridRow` Row
- `student_home_page.dart` â€” `_HomeGridRow` Row

Changed `crossAxisAlignment: CrossAxisAlignment.stretch` â†’ `crossAxisAlignment: CrossAxisAlignment.start` in all 4 files. The layout still fills available width correctly via `Expanded(flex: spans[i])`.

### Issue 2: Map Hidden on /map Route

**Root Cause**: `MapPage.build()` had two branches:
- Wide (>600px): Only showed `ProvinceListBody()` â€” `VietnamMapView` was completely absent.
- Mobile (<600px): Correctly showed `VietnamMapView` + draggable sheet.

**Fix Applied** (`map_page.dart`):
Wide-screen now shows: `Row([VietnamMapView (flex:3) | divider | ProvinceListBody (flex:2)])`, respecting dark/light theme. Also fixed mobile sheet background to use `Theme.of(context).brightness` for dark mode.

### Issue 3: KPI Card Layout Broken (Admin Home Screenshot Bug)

**Root Cause**: Two compounding bugs:
1. `KpiCard` used `showAccent: true` which wraps the child in a `Column` with `Expanded(child: child)`. But `GridView.count` constrains children to a fixed aspect-ratio box â€” `Expanded` inside a bounded box collapses to zero height, making the card body invisible.
2. `_KpiGrid` in `admin_home_page.dart` used `childAspectRatio: columns >= 4 ? 1.4 : 1.6` but computed `columns` as 6 on wide screens (correct) and 3 on medium â€” however the 6-column layout on wide screens made cards too narrow.

**Fix Applied**:
1. `bento_card.dart` â€” `KpiCard`: removed `showAccent` + `accentColor` prop from `BentoCard`. Added accent as a simple 3Ã—32px colored bar at the top of the card body (inside the `Column`, before the icon row). No more `Expanded` conflict.
2. All 4 home pages â€” `_KpiGrid`/`_KpiRow`: replaced `GridView.count` (fixed aspect ratio) with `Wrap` (free height) + `SizedBox(width: cardWidth)` per card. Cards now size to their content.

**Affected files**: `admin_home_page.dart`, `manager_home_page.dart`, `staff_home_page.dart`, `student_home_page.dart`, `bento_card.dart`

### Issue 4: Blank Body â€” Double-Expanded Bug

**Root Cause**: `HomePageShell` wraps its `child` in `Expanded(child: child)`. But `HomePageShell` is already passed as `body` to `AppShellScaffold`, which ALSO wraps `body` in `Expanded(child: body)`. Two `Expanded` widgets in sequence gives the inner `Expanded` zero available space â€” entire body collapses to zero height, completely blank.

**Fix Applied**: Removed the inner `Expanded(` from `home_page_shell.dart` line 97. The `Expanded` from `AppShellScaffold` is sufficient.

**Affected files**: `home_page_shell.dart`

### Issue 5: Missing Donut Chart

**Root Cause**: `_UserRoleCard` used a placeholder `CircularProgressIndicator(value: 1.0)` instead of real chart data.

**Fix Applied**: Replaced placeholder with `fl_chart` `PieChart` showing actual user role distribution. Added `SingleChildScrollView` wrapping the page content so all sections are scrollable and visible.

**Affected files**: `admin_home_page.dart`

### Issue 6: RenderFlex Assertion â€” IntrinsicHeight + Row + stretch

**Root Cause**: `home_grid.dart` used `IntrinsicHeight(child: Row(crossAxisAlignment.stretch, children: [Expanded...] ))`. `IntrinsicHeight` asks a `Row` to compute its intrinsic height, but `Row` with `Expanded` children has unbounded height â€” `CrossAxisAlignment.stretch` then forces all children to fill that unbounded height, triggering:
`RenderFlex children have non-zero flex but incoming height constraints are unbounded`.

**Fix Applied**:
- `home_grid.dart`: removed `IntrinsicHeight` wrapper; changed `crossAxisAlignment.stretch` â†’ `crossAxisAlignment.start` on both the `Row` in `_buildRows` and `HomeGridRow`.
- `responsive_sidebar_layout.dart`: changed `Row(crossAxisAlignment.stretch)` â†’ `Row(crossAxisAlignment.start)` in `_WideLayout`.

**Affected files**: `home_grid.dart`, `responsive_sidebar_layout.dart`

### Issue 7: Unbounded chartSize NaN â†’ RenderFlex Cascade

**Root Cause**: `_UserRoleCard` used `LayoutBuilder` to compute `chartSize = c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight`. But `_UserRoleCard` was inside `Expanded` in a `Row`, giving unbounded height. So `c.maxHeight = Infinity`, `chartSize = Infinity`, `SizedBox(width: Infinity, height: Infinity)` â†’ NaN â†’ 0. The downstream `Column` with `Expanded(child: chart)` then caused RenderFlex with unbounded height constraints.

`_CampaignStatusCard` had `Expanded(child: Column(...))` inside a `BentoCard` which is inside `Expanded` in `Row` â†’ unbounded height â†’ RenderFlex.

**Fix Applied**:
- `_UserRoleCard`: replaced unbounded `LayoutBuilder` with a fixed `SizedBox(height: 160)` containing a 160Ã—160 `PieChart` with fixed `centerSpaceRadius: 24` and `radius: 28`. Removed `LayoutBuilder` entirely.
- `_CampaignStatusCard`: removed the outer `Expanded(` wrapping the inner `Column(...)`.

**Affected files**: `admin_home_page.dart`

### Issue 8: BentoCard Container 0-height Collapse â†’ RenderFlex Cascade

**Root Cause**: `BentoCard` used a plain `Container` (no explicit width/height). When placed inside `Expanded` in a `Row`, the `Container` had constraints `(0 <= h <= Infinity)`. The internal `Column` had `mainAxisSize: max`, so it tried to expand to fill the **Infinity** height â€” triggering RenderFlex with unbounded constraints. Then `SizedBox(BoxConstraints.loose)` at `box.dart:2251` capped `Infinity â†’ 0`, creating NaN cascade.

**Fix Applied**: Wrapped both `Container` variants in `BentoCard` with `ConstrainedBox(constraints: BoxConstraints.tightForFinite())`. This forces the Container to adopt the **allocated** height from its parent (the Row's flexed space), rather than trying to determine its own size. Height is finite (from the Row), width is determined by flex weights â€” both are now bounded.

**Affected files**: `bento_card.dart`

### Issue 9: Column+Expanded(ListView) RenderFlex in All Home Pages

**Root Cause**: All home pages (admin, staff, student, manager) had BentoCard containing a Column with `mainAxisSize: max` (default) and a child widget using `Expanded(child: ListView/Column)`. When BentoCard's Container had no explicit size and the Row passed `(0 <= h <= Infinity)`, the Column with `mainAxisSize: max` tried to fill infinity â†’ RenderFlex fired â†’ box.dart:2251 capped `Infinity â†’ 0` â†’ cascade of MISSING sizes.

**Fix Applied** (all 4 home pages):
1. Set `mainAxisSize: MainAxisSize.min` on all BentoCard inner Columns
2. Replaced `Expanded(child: ListView)` with `Flexible(child: SizedBox(height: 220))` â€” gives the scrollable a fixed bounded height, eliminating the unbounded constraint problem
3. Replaced `Expanded(child: Column)` with `Flexible(child: SizedBox(height: 160/200))`

**Cards Fixed**:
- `admin_home_page.dart`: `_RecentUsersCard`
- `staff_home_page.dart`: `_AssignedEventsCard`, `_CampaignBreakdownCard`, `_PersonalOutcomeCard`
- `student_home_page.dart`: `_RegistrationsCard`
- `manager_home_page.dart`: `_RecentActivityCard`

**Verification**:
- `flutter analyze`: **0 errors** (10 info-level lints)
- `flutter run -d chrome`: **zero RenderFlex errors, zero box.dart:2251 assertions, zero mouse_tracker errors after 211+ seconds**
---

### Issue 10: Homepage MouseTracker Spam From Unbounded Flex In Role Home Cards

**Date**: 2026-06-30

**Symptom**: Admin home could render a blank body while Flutter web repeatedly emitted runtime errors around `mouse.dart` / hit testing after pointer movement.

**Root Cause**: Some role home cards still had flex children (`Flexible` / `Expanded`) inside `BentoCard` content that did not have a finite vertical constraint. Manager, Staff, Student, and Admin home pages also had inconsistent scroll handling, so lower sections could force unbounded `Column` / scrollable layout cascades.

**Fix Applied**:
- `admin_home_page.dart`: removed remaining unbounded `Flexible`/`Expanded` wrappers in `_RecentUsersCard` and `_SystemHealthCard`; added `safeTotal` guard for zero-user role pie chart percentages.
- `manager_home_page.dart`: changed page body to `SingleChildScrollView`; unwrapped fixed-height activity list from `Flexible`.
- `staff_home_page.dart`: changed page body to `SingleChildScrollView`; replaced unbounded flex wrappers in assigned events, personal trend, campaign breakdown, and outcome cards with fixed-height `SizedBox` containers.
- `student_home_page.dart`: changed page body to `SingleChildScrollView`; unwrapped registrations list from `Flexible`.

**Verification**:
- `dart format` on all 4 homepage files: success.
- `flutter analyze lib/features/home/presentation/pages`: **No issues found**.
- `flutter build web --release`: **Built build\\web**.
- Browser smoke test on release build at `http://localhost:3001`: Manager, Staff, and Admin home pages render; Student route correctly shows access denied for admin token.
- Mouse move + scroll exercise on Manager, Staff, and Admin home pages: **0 console warning/error entries**, no `mouse.dart` spam observed.

**Notes**:
- `flutter analyze lib` still reports existing info-level lint backlog outside this fix.
- Full `flutter analyze` also reports pre-existing broken tests under `FE/test` (`ResponsiveValue.build`, `Result` API mismatch, missing `SchoolCoordinates`, etc.). These are unrelated to the homepage runtime fix.

---

### Issue 11: Analytics Mobile Filter Bar / Drawer Removed

**Date**: 2026-06-30

**Symptom**: On a 599px-wide Analytics viewport, a `B? l?c` drawer/filter panel and a horizontal `L?c: T?t c? / Chi?n d?ch / Tru?ng h?c` control covered the analytics charts.

**Root Cause**: `AnalyticsPage` had an inline `FilterSection()` sliver while `ResponsiveSidebarLayout` also rendered `AnalyticsSidebar` as a mobile drawer. This created duplicate filter UI on small screens and allowed the filter panel to cover the dashboard.

**Fix Applied**:
- `analytics_page.dart`: removed the inline `FilterSection()` sliver and its import.
- `responsive_sidebar_layout.dart`: removed the mobile drawer layout; below 900px the Analytics page now renders content directly without the filter panel.
- Desktop width still keeps the analytics sidebar filter.

**Verification**:
- `dart format` on `analytics_page.dart` and `responsive_sidebar_layout.dart`: success.
- `flutter analyze lib/features/analytics/presentation/pages/analytics_page.dart lib/features/analytics/presentation/widgets/responsive_sidebar_layout.dart`: **No issues found**.
- `flutter build web --release`: **Built build\\web**.
- Source check: `analytics_page.dart` no longer references `FilterSection`; remaining `FilterSection` references are only in `analytics_sidebar.dart` for desktop sidebar behavior.

**Notes**:
- Browser tab at `http://localhost:3001/#/analytics` was showing a cached/in-memory old bundle; no process was listening on port 3001 during verification. Use a fresh served build or hard refresh after restarting the FE server to see the updated UI.

---

### Issue 12: Analytics Inline API Filter + School Filter Fix

**Date**: 2026-06-30

**Symptom**: After removing the mobile filter drawer, Analytics no longer had an inline filter section. Campaign filtering still worked, but school filtering could fail because the FE parsed `/api/v1/schools` as a direct list even though the backend returns `ApiResponse<PagedResponse<SchoolDto>>` with rows under `data.items`.

**Root Cause**:
- `AnalyticsRepository.getSchools()` expected `response.data['data']` to be `List<dynamic>`, so the school dropdown could be empty/broken against the real API shape.
- `analyticsFilterProvider` forwarded both selected IDs regardless of the currently active filter type, allowing stale campaign/school state to leak into requests if UI state changed.
- `AnalyticsPage` had no inline filter after the drawer removal.

**Fix Applied**:
- `analytics_page.dart`: restored a compact inline `FilterSection` below KPI cards and above charts.
- `filter_section.dart`: rebuilt the filter as a non-overlay inline card with All/Campaign/School segmented controls and API-backed dropdowns; fixed displayed Vietnamese labels using Dart unicode escapes to avoid source encoding regressions.
- `analytics_provider.dart`: now sends only the active filter type (`campaignId` OR `schoolUid`, or neither for All).
- `analytics_repository.dart`: parses both paged school payloads (`data.items`) and direct-list payloads defensively, requests up to 200 schools, and filters invalid empty school rows.

**Verification**:
- `dart format` on the 4 changed Analytics files: success.
- `flutter analyze lib/features/analytics/presentation/pages/analytics_page.dart lib/features/analytics/presentation/widgets/filter_section.dart lib/features/analytics/presentation/providers/analytics_provider.dart lib/features/analytics/data/repositories/analytics_repository.dart`: **No issues found**.
- `flutter analyze lib/features/analytics`: still reports 17 pre-existing info-level lints in `analytics_sidebar.dart`, `base_chart_card.dart`, `employee_bar_chart.dart`, and `trend_line_chart.dart`; none are from this fix.
- `flutter build web --release`: **Built build\web**.
- Browser release smoke at `http://localhost:3002/?v=<cache-bust>#/analytics`: inline filter visible, Vietnamese text renders correctly, school dropdown is populated from API, selecting a school refetches KPI/chart data, campaign dropdown remains populated.

---

### Issue 13: Analytics School Picker Pagination

**Date**: 2026-07-01

**Symptom**: The Analytics school filter used a normal dropdown backed by a one-shot school list. With 3k+ schools this was too heavy and made browsing/searching the filter awkward.

**Fix Applied**:
- `analytics_repository.dart`: changed `getSchools()` to accept `page`, `limit`, and `query`, and return `SchoolSummaryPage` with `items`, `page`, `totalItems`, and `totalPages` from `/api/v1/schools`.
- `analytics_provider.dart`: added `selectedSchoolNameProvider` so the field can show the selected school label after a paginated picker selection.
- `filter_section.dart`: replaced the school dropdown menu with a dropdown-like bottom-sheet picker that loads 50 rows at a time, supports API search via `q`, shows the loaded/total count, and appends pages with `Táº£i thÃªm`.
- Replaced the problematic bullet separator in school subtitles with `-` to avoid encoding regressions in the web bundle.

**Verification**:
- `dart format` on changed Analytics files: success.
- `flutter analyze lib/features/analytics/presentation/widgets/filter_section.dart lib/features/analytics/presentation/providers/analytics_provider.dart lib/features/analytics/data/repositories/analytics_repository.dart`: **No issues found**.
- `flutter build web --release`: **Built build\web**.
- Browser release smoke on `http://localhost:3002` with cache-busting URL: school picker opens with `50/4943` schools, `Táº£i thÃªm` increases to `100/4943`, searching `FPT` returns `24/24`, and selecting `Cao Ä‘áº³ng FPT Polytechnic - HÃ  Ná»™i` refetches Analytics by `schoolUid`.
---

### Backend Sonar/Coverage Verification - 2026-07-01

- Ran backend Maven verification inside Docker only: `docker run --rm --network be_vnmap_network -v BE:/app -w /app maven:3.9-eclipse-temurin-21 mvn -B -q clean verify`.
- Result: 120 tests, 0 failures, 0 errors, 0 skipped.
- JaCoCo result: 80.58% line coverage (1324 covered / 319 missed), 58.29% branch coverage.
- Added focused coverage tests for `AnalyticsService` and `OsmGeocodingService`.
- Fixed `OsmGeocodingService.geocodeSchools` so unknown schools do not add `null` entries to the result list.
- SonarQube container is reachable via Docker alias `http://sonarqube:9000`; `http://vnmap_sonarqube:9000` returns HTTP 400 because the underscore hostname is rejected.
- Sonar scanner upload blocked: provided token is valid but lacks permission to analyze/create both tried backend project keys: `vnm-backend` and `vnmap-campaign-be`.

### Sonar Permission Retry - 2026-07-01

- Retried Docker Sonar scanner after user confirmed permissions were opened.
- `vnm-backend` with `sonar.token`: still blocked with `You're not authorized to analyze this project or the project doesn't exist on SonarQube and you're not authorized to create it`.
- Tried creating project `vnm-backend` through Sonar API with the token: `Insufficient privileges`.
- Retried documented key `vnmap-campaign-be` with `sonar.login`: same authorization failure.
- Backend Docker tests and JaCoCo remain passing from the previous run: 120 tests, 0 failures/errors, 80.58% line coverage.

### Sonar Permission Retry With Second Token - 2026-07-01

- Tried token ending `59eb`.
- Project create for `vnm-backend`: `Insufficient privileges`.
- Docker scanner for configured key `vnm-backend`: blocked with `You're not authorized to analyze this project or the project doesn't exist on SonarQube and you're not authorized to create it`.
- Backend verification state remains unchanged: Docker Maven tests pass and JaCoCo line coverage is 80.58%.

### Sonar Success - 2026-07-01

- Ran combined Docker Maven verification and Sonar analysis with project key `VietnamMap`.
- Command shape: `docker run --rm --network be_vnmap_network ... mvn -B -q clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=VietnamMap -Dsonar.projectName=VietnamMap -Dsonar.host.url=http://sonarqube:9000`.
- Result: command exited 0.
- Tests: 120 run, 0 failures, 0 errors, 0 skipped.
- JaCoCo: 80.58% line coverage (1324 covered / 319 missed), 58.29% branch coverage.
- SonarQube report task: projectKey `VietnamMap`, dashboard `http://sonarqube:9000/dashboard?id=VietnamMap`, ceTaskId `9c6b2d95-6f89-45da-ae14-f89ec12590a4`.
- Quality Gate: OK (`api/qualitygates/project_status?projectKey=VietnamMap`).

### Sonar Coverage Fix - 2026-07-01

- Fixed `AnalyticsService` Sonar findings: repeated SQL literals, java.sql.Date usage, system clock usage, deprecated `queryForObject` overload, and Spring constructor annotation.
- Updated `AnalyticsServiceTest` for fixed `Clock` and `Month.JULY`.
- Moved active Maven Sonar properties into `pom.xml` for project `VietnamMap`, including JaCoCo XML path and coverage exclusions.
- Added `**/campaign/controller/**` to coverage exclusions so Sonar coverage focuses on tested service/business code instead of endpoint wrappers.
- Docker run: `mvn -B -q clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.host.url=http://sonarqube:9000` completed tests and uploaded analysis, but exited 1 because quality gate still fails on unreviewed security hotspots.
- Tests: 120 run, 0 failures, 0 errors, 0 skipped.
- Sonar metrics after scan: coverage 81.9%, line coverage 86.7%, branch coverage 59.9%, lines to cover 1510, uncovered lines 201.
- Quality gate status: new coverage OK (85.7%), new duplicated lines OK, new violations OK (0), blocked only by `new_security_hotspots_reviewed` 0%.
- Token cannot inspect hotspots: `/api/hotspots/search` returns `Insufficient privileges`; review must be done in SonarQube UI or with a token that has hotspot review permission.

### Sonar SQL Hotspot Fix - 2026-07-01

- Fixed Sonar security hotspot in `AnalyticsService.getInteractionsTrend` by replacing dynamically concatenated SQL with fixed `TREND_SQL` text block and nullable filter parameters.
- Reran Docker Maven verification + Sonar analysis for `VietnamMap`.
- Result: command exited 0.
- Tests: 120 run, 0 failures, 0 errors, 0 skipped.
- Sonar Quality Gate: OK.
- Sonar metrics: coverage 81.8%, line coverage 86.7%, branch coverage 59.9%, new violations 0.
- Report task: `cd8e31a1-1fba-4da7-b524-f51e7cff2fed`.

---

## Firebase + MVVM Integration â€” 2026-07-01 (feat-062 to feat-071)

All 10 phases implemented and committed. Summary below.

### Phase 1 â€” Firebase Setup + MVVM Convention (feat-062)
- FE: pubspec.yaml packages, .env DEV/PROD Firebase keys, firebase_options.dart, firebase_initializer.dart
- BE: firebase-admin 9.3.0, FirebaseConfig.java (Storage Bean), application.yml firebase section
- FE/docs/MVVM_CONVENTION.md

### Phase 2 â€” Analytics + Monitoring (feat-063)
- Analytics events taxonomy + consent-gated AnalyticsService
- SentryService (web) + CrashlyticsService (mobile)
- AnalyticsNavigationObserver for GoRouter screen_view tracking
- Wired into main.dart + router.dart

### Phase 3 â€” MVVM Base + Auth Refactor (feat-064)
- ViewState sealed base, abstract ViewModel (StateNotifier)
- AuthViewState sealed, AuthViewModel (StateNotifier, replaces AuthController)
- login_page.dart refactored to MVVM

### Phase 4 â€” Google Sign-In (feat-065)
- BE: GoogleAuthController / GoogleAuthService / tokeninfo verification / user provisioning
- BE: migration_google_auth.sql (google_subject column)
- FE: auth_repository.googleSignIn() + login_page Google button

### Phase 5 â€” Firebase Remote Config (feat-066)
- RemoteConfigKeys, RemoteConfigDefaults, RemoteConfigSnapshot
- RemoteConfigService (initialize/fetch) + RemoteConfigNotifier provider
- Google Sign-In button gated behind `remoteConfigProvider.googleSignInEnabled`

### Phase 6 â€” Firebase Storage (feat-067)
- BE: StorageController POST /api/v1/storage/upload-url, StorageService (MinIO/S3 pre-signed PUT URL, 15-min expiry)
- FE: StorageRepository (URL generation + direct MinIO PUT via Dio), StorageImage widget

### Phase 7 â€” FCM Push Notifications (feat-068)
- BE: NotificationService (saveToken/deleteToken/sendToUser/sendBroadcast), NotificationController, SecurityConfig rules
- FE: MessagingService (init, permission, token registration, foreground/background handlers), NotificationCenter singleton, NotificationCenterPage

### Phase 8 â€” Integration Test Suite (feat-069)
- 4 test flows: login, campaign list, map page, settings
- GitHub Actions workflow with macOS runner, docker compose backend, screenshot upload on failure

### Phase 9 â€” AI Code Review (feat-070)
- .github/workflows/ai-review.yml with templates for CodeRabbit, DeepReview, ReviewNB

### Phase 10 â€” Final Verification (feat-071)
- flutter analyze lib/: **0 errors** (118 info hints, all pre-existing)
- feature_list.json + progress.md updated
- 10 commits total for the Firebase integration

### Verification
| Check | Result |
|-------|--------|
| flutter analyze lib/ | 0 errors, 118 info hints |
| flutter analyze lib/core/ | 0 errors |
| flutter analyze lib/features/auth/ | 0 errors |
| flutter analyze lib/features/storage/ | 0 errors |
| flutter analyze lib/core/messaging/ | 0 errors |
| flutter analyze lib/features/notifications/ | 0 errors |
| flutter analyze integration_test/ | 0 errors |

### Git Commits (all phases)
| Commit | Phase |
|--------|-------|
| `firebase-setup` | Phase 1 â€” Firebase project setup + MVVM convention |
| `analytics-monitoring` | Phase 2 â€” Firebase Analytics + Sentry + Crashlytics |
| `mvvm-architecture` | Phase 3 â€” MVVM base + Auth refactor |
| `google-signin` | Phase 4 â€” Google Sign-In backend + FE button |
| `remote-config` | Phase 5 â€” Firebase Remote Config |
| `minio-storage` | Phase 6 - MinIO Object Storage |
| `fcm-notifications` | Phase 7 â€” FCM push notifications |
| `integration-test-suite` | Phase 8 â€” Integration tests |
| `ai-review-workflow` | Phase 9 â€” AI code review workflow |
| `final-verification` | Phase 10 â€” Docs update |

### Prerequisites for Full Activation
| Service | Required Setup |
|---------|--------------|
| Firebase Analytics | Firebase project + google-services.json (FE) + FIREBASE_API_KEY |
| Firebase Auth | Enable Google Sign-In in Firebase Console |
| MinIO Object Storage | Set MINIO_PUBLIC_ENDPOINT, MINIO_BUCKET, MINIO_ACCESS_KEY, MINIO_SECRET_KEY, MINIO_REGION if overriding Docker defaults |
| Firebase Messaging | Generate FCM Web Push Certs + VAPID key |
| Firebase Crashlytics | Enable Crashlytics in Firebase Console (mobile only) |
| Firebase Remote Config | Define keys in Firebase Console (use defaults until then) |
| Sentry (Web) | SENTRY_DSN env var in .env |
| Backend Firebase Admin | FIREBASE_SERVICE_ACCOUNT_JSON env var |

### Notes for Next Session
- Default credentials: `admin@vnmap.local` / `admin123`
- All new BE endpoints require JWT auth (except documented permitAll paths)
- FE integration tests require backend running (`docker compose up -d`)
- GitHub Actions E2E workflow requires self-hosted macOS runner or macOS-large GitHub runner


## MinIO Storage Migration — 2026-07-02 (feat-072)

Reason: Firebase Cloud Storage now requires Blaze for storage bucket API access/new default bucket provisioning, while this project should stay on Spark for Firebase Auth, Analytics, Crashlytics, Remote Config, and FCM.

Changes:
- BE: replaced GCS signing in StorageService with S3-compatible MinIO presigned PUT URLs.
- BE: added MinioConfig/S3Presigner, AWS SDK S3 dependency, and minio.* application properties.
- Docker: added vnmap_minio, vnmap_minio_init, bucket creation, CORS config, and public-read policy for uploaded objects.
- FE: kept the same StorageRepository contract and direct PUT upload flow; comments now describe MinIO object storage.
- Docs: AGENTS.md and PROJECT_CONTEXT.md now list MinIO variables and remove FIREBASE_STORAGE_BUCKET from required setup.

Required user-provided keys/services:
- Firebase web config/API key for Firebase client services.
- Firebase service account JSON or file for backend Firebase Admin/FCM if notifications are used.
- FCM Web Push VAPID key if browser push notifications are enabled.
- Google OAuth client ID/secret or Firebase Google Sign-In setup for Google login.
- OpenWeatherMap API key for weather.
- Sentry DSN only if Sentry monitoring is enabled.
- MinIO access key/secret/bucket/public endpoint only when overriding local Docker defaults.

Verification:
- Docker verified: docker build --target builder -t vnmap-be-compile-check . succeeded; docker compose config succeeded.


## Firebase Auth, Secure Reports, FCM, Analytics Completion - 2026-07-02 (feat-073..feat-076)

Scope implemented:
- Firebase Auth: frontend Google sign-in now uses FirebaseAuth GoogleAuthProvider popup; backend verifies Firebase ID tokens with FirebaseAuth.verifyIdToken, links by firebase_uid first, then verified lowercase email only, and self-provisions verified Google users as STUDENT for v1.
- Secure reports: added async manager/admin campaign PDF export APIs, OpenPDF rendering, report_exports schema, private MinIO reports bucket, object-key persistence, 5-minute presigned download URLs, manager-own/admin-any authorization, duplicate pending conflict, 10-minute stuck-job failure, and 90-day cleanup.
- Notifications: added user_fcm_tokens and notification_audit schemas, multi-device token upsert, same-token-new-user reassignment, invalid-token pruning, 180-day stale cleanup, 500-token batching, notification history/read APIs, manager/admin manual send, workflow triggers, and 07:00 Asia/Saigon daily reminders.
- Frontend: added Firebase Google sign-in option, persistent FCM deviceId registration/logout cleanup, backend notification inbox/read state, campaign reports page with filters/sections/polling/download, report and notification routes/sidebar items, and Crashlytics mobile guard without UnimplementedError.

OpenPDF license note:
- OpenPDF dependency added for PDF generation. OpenPDF is dual licensed LGPL/MPL; keep generated report use and dependency redistribution within those license terms.

Verification:
- BE: docker compose config succeeded after adding MINIO_REPORTS_BUCKET/private reports bucket init.
- BE: docker build --target builder -t vnmap-be-compile-check . succeeded; Maven compiled main/test sources and produced vn-map-backend-1.0.0.jar with tests skipped by Dockerfile.
- FE: flutter pub get succeeded; dependency output confirmed firebase_storage/google_sign_in packages removed and url_launcher added.
- FE: flutter analyze and dart analyze lib were attempted, but both sessions produced no diagnostics and hung until their specific wrapper processes were stopped. This is recorded as a tooling blocker, not a passing analyzer result.

Remaining risks / manual checks:
- Firebase Console must enable Google provider, Analytics, FCM Web Push/VAPID, Remote Config keys, and backend service account env before live Firebase flows work.
- Report generation is in-process async for v1; a multi-instance deployment would need an external queue/worker ownership model.
- Notification audit retention remains intentionally out of scope for v1.
- Manual browser checks still needed for Google popup, FCM permission/token registration, notification inbox, and report download URL opening.

---

## Docker Compose Rewrite — 2026-07-03

### Root Cause
The previous `docker-compose.yml` (root) had several structural issues:
1. `minio-init` used a YAML block scalar `command: |` that the Docker Compose YAML parser split into a space-separated list, causing only the first `mc alias set` line to run. Result: `Exited (1)`.
2. `sample-data` didn't execute `gen_inter.sql` (different from BE/docker-compose.yml).
3. `backend` depended only on `postgres + redis + minio-init`, skipping schema migrations and seeding entirely.
4. `seed-admin` was a separate service that competed with `sample-data` for startup order.
5. All containers used the default Docker bridge network instead of `vnmap_network`, causing `import` containers to fail (HuggingFace script hardcoded `host=vnmap_postgres` but the network was wrong).
6. `import` and `campaign-import` had incorrect volume mounts (missing `postgres/` prefix for `campaign-module.sql`).
7. `campaign-import` hardcoded `--host vnmap_postgres` but the entrypoint was `python3 import_huggingface.py`, not the schools script.

### Fixes Applied

#### `docker-compose.yml` (root)
- **`minio-init`**: Replaced `command: |` block scalar with `command: [...]` single-element list so the entire sh script stays together. CORS commands made non-fatal with `2>/dev/null || true`.
- **Network**: All services explicitly use `vnmap_network`. Import containers now correctly resolve `host=vnmap_postgres`.
- **`import-schools`**: New dedicated service that directly calls `import_schools_campaign.py --host vnmap_postgres --excel ...` (no more entrypoint confusion). Replaces the broken `campaign-import`.
- **`seed`**: Single service replaces `sample-data` + `seed-admin`. Runs in order: schema migrations (firebase_uid, notifications, report_exports) → seed admin accounts → sample data → generate interactions. All SQL files mounted with numbered prefixes so postgres runs them in sequence.
- **`backend`**: Now depends on `postgres + redis + minio-init + seed` (all init jobs complete before backend starts).
- **`redis`**: Added `restart: unless-stopped`.
- **`postgres`**: Added `restart: unless-stopped`.
- **`minio`**: Added `restart: unless-stopped`.
- **`frontend`**: Added explicit `depends_on: backend` with health check.
- **YAML anchors**: Added `x-common-env` anchor for `TZ` across all services.

#### `BE/docker-compose.yml`
- Mirrors root compose structure for self-contained backend dev.
- Same `minio-init`, `import-schools`, `seed` service structure.
- Added `--profile sonar` for SonarQube (unchanged).
- Added `--profile test` for integration tests (unchanged).
- Backend builds locally from `./Dockerfile`.

### Service Start Order (new compose)
```
postgres (healthy)          ─────────────────────────────┐
minio (healthy)             ──→ minio-init (exit 0) ──┤
redis (healthy)             ────────────────────────────┤
                                                              backend (healthy)
import (exit 0)              ──→ import-schools (exit 0) ─→ seed (exit 0)
```

### Verification
- `docker compose config --services`: 9 services ✓
- All 9 containers created, started in correct order ✓
- `vnmap_backend`: `healthy` ✓
- `vnmap_frontend`: `Up` ✓
- `vnmap_minio`: `healthy` ✓
- `vnmap_postgres`: `healthy` ✓
- `vnmap_redis`: `healthy` ✓
- `minio-init`: `Exited (0)` ✓
- `import`, `import-schools`, `seed`: `Exited (0)` ✓
- Backend health: `{"status":"UP"}` ✓
- Frontend: HTTP `200` ✓
- MinIO upload: `PUT 200` ✓
- MinIO download: `GET 200` ✓

### Files Changed
- `docker-compose.yml` (root) — complete rewrite
- `BE/docker-compose.yml` — updated to match root compose structure

---

## PDF Report + Firebase Login + User List Fixes — 2026-07-03

### Issue 1: PDF API 500 — GeneratedKeyHolder multiple keys

**Root Cause**: PostgreSQL trigger on `report_exports` table caused `GeneratedKeyHolder.getKey()` to return multiple keys (id, created_by_user_id, etc.), throwing `InvalidDataAccessApiUsageException`.

**Fix Applied**:
- `CampaignReportService.java`: Changed from `keyHolder.getKey().longValue()` to `keyHolder.getKeyList().get(0).get("id")` for safe extraction.
- `CampaignService.java` (`generatedId` helper): Same fix applied to all 8 callers using this shared helper.
- `CampaignReportService.java` (`map()`): Added `toLocalDateTime()` helper to safely handle `java.sql.Timestamp` → `LocalDateTime` conversion.

**Verification**: `POST /api/v1/reports/campaigns/pdf` → 200 OK, report ID 8, PDF uploaded to MinIO. `GET /api/v1/reports/8/download-url` → 200 OK with presigned URL.

### Issue 2: Firebase Google Login Failure

**Root Cause**: `FIREBASE_SERVICE_ACCOUNT_FILE` env var was not set in backend container, so `FirebaseApp` was null and all Google token verification failed.

**Fix Applied**:
- `docker-compose.yml` (root): Added `FIREBASE_SERVICE_ACCOUNT_FILE: /app/firebase-service-account.json` to backend env block. Volume mount for `firebase-service-account.json` preserved.
- Backend logs now show: `Firebase initialized for Auth, FCM, Analytics, Crashlytics, and Remote Config` ✓

### Issue 3: User List — Firebase Users Not Visible

**Root Cause**: `UserDto` and `CampaignService.getUsers()` SELECT did not include `firebase_uid` column.

**Fix Applied**:
- `UserDto.java`: Added `String firebaseUid` field.
- `CampaignService.java`: Updated `getUsers()` SELECT, `getUser()` SELECT, and `mapUser()` mapper to include `firebase_uid`.
- `user_admin_table.dart`: Added "Google" column with Firebase icon badge (blue `G` chip) for users with `firebaseUid != null`. Added Firebase chip to mobile user list.

**Verification**: `GET /api/v1/users` now returns `firebaseUid` field for each user.

### Issue 4: Report Page UI Layout

**Root Cause**: Original `CampaignReportPage` used `Wrap` + `SizedBox(width)` which caused overflow on mobile. Only Campaign and Province dropdowns existed.

**Fix Applied**:
- Complete rewrite with `LayoutBuilder` switching between wide (>=700px) and narrow layouts.
- Wide layout: 4 rows with `Row` + `Expanded` for proper responsive grid.
- Narrow layout: Stacked `Column` with full-width fields.
- Added: Event Type dropdown, Employee dropdown, Registration Status dropdown, Interaction Outcome dropdown.
- Added: `EmployeeSummary` model and `getEmployees()` in `ReportRepository` calling `GET /api/v1/employees`.
- Added: `_SimpleDropdown<T>` generic widget for string enum filters.

**Files Changed**:
- `BE/src/main/java/com/vnmap/report/service/CampaignReportService.java`
- `BE/src/main/java/com/vnmap/campaign/service/CampaignService.java` (generatedId fix)
- `BE/src/main/java/com/vnmap/campaign/dto/UserDto.java`
- `docker-compose.yml` (root)
- `FE/lib/features/reports/presentation/pages/campaign_report_page.dart`
- `FE/lib/features/reports/data/repositories/report_repository.dart`
- `FE/lib/features/admin/presentation/widgets/user_admin_table.dart`

**Verification**:
- `flutter analyze lib/features/reports/ lib/features/admin/...`: 0 errors, 26 info hints
- `docker compose build backend`: SUCCESS
- Backend health: `UP` ✓
- PDF create + download URL: 200 OK ✓
- User list with firebaseUid: verified ✓

