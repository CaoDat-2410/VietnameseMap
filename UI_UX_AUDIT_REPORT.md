# UI/UX Audit Report - VN Map Campaign Module

Generated: 2026-06-23 13:58:54 +07:00

Scope: frontend UX audit, dashboard/CRUD coverage review, school location/geocoding proposal, and implementation guidance.

This document is intentionally a report only. No source code behavior was changed while preparing it.

## 1. Executive Summary

The app is functional for the core login/logout and role-based navigation flows, and the backend already exposes many campaign-related APIs. However, the frontend still feels closer to a working prototype than a complete admin/manager dashboard product.

Main findings:

- Dashboard loads successfully and backend dashboard APIs are fast, but the UI is still KPI/table-based and lacks actual charts.
- Map is the heaviest screen. It can take around 5-6 seconds in Flutter web debug mode because it loads map tiles and administrative boundaries.
- Campaign CRUD is incomplete in FE. Create campaign currently creates hardcoded data directly.
- Event CRUD is partially implemented. Create/edit exists, archive/delete API exists, but archive/delete UI is missing.
- User admin page is incomplete. It lists users and changes roles only.
- School list/detail is read-only and lacks school location support.
- School click-to-map cannot be accurate yet because `schools` table does not store latitude/longitude.
- Several UX details are rough: raw datetime strings, technical status labels, code-based filters, bottom-nav overlap risk, weak empty/loading states.
- Potential bug or interaction issue observed in browser audit: tab switching in Event Detail and School Detail did not switch tabs during repeated automated clicks. This should be checked manually on the running UI.

## 2. Verification Notes

Checked using Flutter web at:

```text
http://localhost:3000
```

Backend endpoint timing measured locally:

```text
GET /api/v1/campaigns/2                    ~9-19 ms
GET /api/v1/campaigns/2/dashboard          ~33-36 ms
GET /api/v1/campaigns/2/student-registrations ~9-21 ms
GET /api/v1/campaigns                      ~21 ms
GET /api/v1/campaigns/1/dashboard          ~37 ms
```

Conclusion: current dashboard slowness is not caused by backend query time. Most perceived delay is likely frontend debug-mode render, first route warm-up, map/boundary loading, or full-screen spinner UX.

Browser console during audited screens: no warnings/errors observed.

## 3. Current Feature Coverage

### 3.1 Authentication And Role UI

Current status: mostly OK.

Verified:

- `STAFF` login redirects to `/campaigns`.
- `MANAGER` login redirects to `/campaigns` and sees `Create`.
- `ADMIN` login redirects to `/admin/users`.
- `STUDENT` login redirects to `/student/my-registrations`.
- `STUDENT` direct access to `/admin/users` shows `Access denied`.
- Logout returns to `/login`.

Relevant files:

- `FE/lib/app/router.dart`
- `FE/lib/features/auth/presentation/pages/login_page.dart`
- `FE/lib/features/auth/presentation/pages/logout_page.dart`
- `FE/lib/features/auth/shared/providers/auth_provider.dart`

Potential improvement:

- Add a visible current-user indicator in the shell, e.g. email/role chip in app bar or profile menu.
- Add clearer logout confirmation only if the product requires it. For now direct logout is acceptable.

## 4. Dashboard Audit

### 4.1 Current Behavior

Frontend route:

- `FE/lib/features/campaign/dashboard/pages/campaign_dashboard_page.dart:8`

Current dashboard watches two providers:

- `campaignDetailProvider(campaignId)` at `campaign_dashboard_page.dart:15`
- `campaignDashboardProvider(campaignId)` at `campaign_dashboard_page.dart:16`

It renders:

- Header campaign info.
- KPI grid.
- `Interactions by Outcome` table.
- `Interactions by Province` table.
- `Top Schools` table.
- `Student Registrations` section.

Relevant code:

- KPI grid: `FE/lib/features/campaign/dashboard/pages/campaign_dashboard_page.dart:114`
- DataTables: `campaign_dashboard_page.dart:163`, `:201`, `:241`
- Registrations section: `campaign_dashboard_page.dart:263`
- Registrations provider call: `campaign_dashboard_page.dart:270`

Backend:

- Controller: `BE/src/main/java/com/vnmap/campaign/controller/CampaignController.java:133`
- Service: `BE/src/main/java/com/vnmap/campaign/service/CampaignService.java:234`
- DTO: `BE/src/main/java/com/vnmap/campaign/dto/CampaignDashboardDto.java:6`

### 4.2 Issue: Dashboard Lacks Charts

Problem:

Dashboard currently looks like a report/table page, not a true dashboard. There are no visual charts despite having chart-ready data.

Impact:

- Manager/admin cannot quickly understand campaign progress.
- KPI values are useful but not enough for trend/composition analysis.

Recommended dependency:

```yaml
dependencies:
  fl_chart: ^0.69.0
```

Pattern:

- Keep provider/repository as-is for the current aggregate dashboard endpoint.
- Add chart widgets under `FE/lib/features/campaign/dashboard/widgets/`.
- Keep chart widgets pure and data-driven.

Suggested structure:

```text
FE/lib/features/campaign/dashboard/
  pages/
    campaign_dashboard_page.dart
  widgets/
    dashboard_kpi_grid.dart
    outcome_donut_chart.dart
    province_bar_chart.dart
    top_schools_bar_chart.dart
    registrations_status_chart.dart
    dashboard_section_card.dart
```

Example widget pattern:

```dart
class OutcomeDonutChart extends StatelessWidget {
  const OutcomeDonutChart({super.key, required this.outcomes});

  final Map<String, int> outcomes;

  @override
  Widget build(BuildContext context) {
    final entries = outcomes.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return const EmptyChartState(message: 'No interaction outcomes yet');
    }

    return PieChart(
      PieChartData(
        sections: [
          for (final entry in entries)
            PieChartSectionData(
              value: entry.value.toDouble(),
              title: '${entry.value}',
            ),
        ],
      ),
    );
  }
}
```

### 4.3 Issue: Loading UX Feels Slower Than API

Problem:

Dashboard uses nested `AsyncValue.when`. If campaign detail is loading, the whole screen shows one spinner. Then dashboard has its own spinner. Registrations load later inside the page.

Relevant code:

- `campaign_dashboard_page.dart:15-16`
- `campaign_dashboard_page.dart:31-60`
- `campaign_dashboard_page.dart:263-332`

Impact:

- Even when backend is fast, full-screen spinners make the route feel slower.
- Users cannot see partial dashboard content while one section is loading.

Recommended pattern:

- Use page-level shell immediately.
- Load campaign header, dashboard summary, and registrations as independent sections.
- Use skeleton cards for KPIs instead of a full-screen loader.

Example pattern:

```dart
return Scaffold(
  appBar: AppBar(title: const Text('Campaign Dashboard')),
  body: RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(campaignDetailProvider(campaignId));
      ref.invalidate(campaignDashboardProvider(campaignId));
      ref.invalidate(campaignRegistrationsProvider(campaignId));
    },
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        CampaignHeaderSection(campaign: campaign),
        DashboardKpiSection(dashboard: dashboard),
        OutcomeChartSection(dashboard: dashboard),
        RegistrationSection(campaignId: campaignId),
      ],
    ),
  ),
);
```

### 4.4 Issue: Dashboard Data Model Missing Some Chart Dimensions

Current backend DTO:

- `totalEvents`
- `totalTargetSchools`
- `totalAssignedEmployees`
- `totalInteractions`
- `interactionsByOutcome`
- `interactionsByProvince`
- `topSchools`

Relevant file:

- `BE/src/main/java/com/vnmap/campaign/dto/CampaignDashboardDto.java:6`

Missing for richer dashboard:

- Event counts by status.
- Event counts by type.
- Interactions by day/week/month.
- Registrations by status.
- Employee workload.
- Conversion funnel: assigned schools -> contacted schools -> interested -> registrations.

Recommended backend DTO extension:

```java
public record CampaignDashboardDto(
    Long campaignId,
    long totalEvents,
    long totalTargetSchools,
    long totalAssignedEmployees,
    long totalInteractions,
    Map<String, Long> interactionsByOutcome,
    List<ProvinceInteractionDto> interactionsByProvince,
    List<TopSchoolDto> topSchools,
    Map<String, Long> eventsByStatus,
    Map<String, Long> eventsByType,
    Map<String, Long> registrationsByStatus,
    List<TimeSeriesPointDto> interactionsByDate,
    List<EmployeeWorkloadDto> employeeWorkload
) {}
```

Suggested SQL additions:

```sql
SELECT status, COUNT(*) total
FROM campaign_events
WHERE campaign_id = ?
GROUP BY status;

SELECT event_type, COUNT(*) total
FROM campaign_events
WHERE campaign_id = ?
GROUP BY event_type;

SELECT status, COUNT(*) total
FROM campaign_student_registrations
WHERE campaign_id = ?
GROUP BY status;

SELECT DATE(created_at) day, COUNT(*) total
FROM interactions
WHERE campaign_id = ?
GROUP BY DATE(created_at)
ORDER BY day;
```

## 5. Campaign List And Campaign CRUD

### 5.1 Current Behavior

Relevant file:

- `FE/lib/features/campaign/dashboard/pages/campaign_list_page.dart`

Current behavior:

- Shows campaign cards.
- Search by campaign name.
- Filter by status.
- `MANAGER` and `ADMIN` see `Create`.
- Card has `Dashboard` and `Events`.

Relevant lines:

- Page: `campaign_list_page.dart:9`
- Create action: `campaign_list_page.dart:27`
- Floating action button: `campaign_list_page.dart:70`
- Campaign card: `campaign_list_page.dart:174`
- Owner display: `campaign_list_page.dart:207`
- Dashboard button: `campaign_list_page.dart:219`
- Events button: `campaign_list_page.dart:225`

### 5.2 Issue: Create Campaign Uses Hardcoded Data

Problem:

`_createCampaign()` immediately creates a campaign with generated name/objective/dates.

Relevant code:

- `campaign_list_page.dart:27`

Impact:

- Users cannot control campaign name, objective, dates, owner, or status.
- It can create unwanted records by accidental click.
- Looks like placeholder/prototype behavior.

Recommended pattern:

- Replace direct create with a `CampaignFormDialog`.
- Use same dialog for create/edit.
- Require confirmation before archive.

Suggested structure:

```text
FE/lib/features/campaign/dashboard/widgets/campaign_form_dialog.dart
```

Pseudo-code:

```dart
Future<void> _openCampaignForm(BuildContext context, WidgetRef ref) async {
  await showDialog<void>(
    context: context,
    builder: (_) => CampaignFormDialog(
      onSubmit: (data) async {
        await ref.read(campaignRepositoryProvider).createCampaign(data);
        ref.invalidate(campaignsProvider);
      },
    ),
  );
}
```

Suggested form fields:

- Name
- Objective
- Status: `DRAFT`, `ACTIVE`, `DONE`, `CANCELLED`
- Start date
- End date
- Owner employee

### 5.3 Issue: Missing Campaign Edit/Archive UI

Backend/repository already supports:

- `updateCampaign(...)`
- `archiveCampaign(...)`

Relevant file:

- `FE/lib/features/campaign/shared/repositories/campaign_repository.dart`

Missing UI:

- Edit button on card/detail.
- Archive button with confirmation.
- Option to include archived campaigns for manager/admin.

Recommended card actions:

```dart
PopupMenuButton<CampaignAction>(
  onSelected: (action) {
    switch (action) {
      case CampaignAction.edit:
        openCampaignForm(campaign);
      case CampaignAction.archive:
        confirmArchive(campaign);
    }
  },
  itemBuilder: (_) => const [
    PopupMenuItem(value: CampaignAction.edit, child: Text('Edit')),
    PopupMenuItem(value: CampaignAction.archive, child: Text('Archive')),
  ],
)
```

## 6. Event List, Event Detail, And Event CRUD

### 6.1 Current Behavior

Relevant files:

- `FE/lib/features/campaign/events/pages/campaign_events_page.dart`
- `FE/lib/features/campaign/events/pages/event_detail_page.dart`
- `FE/lib/features/campaign/events/widgets/event_form_dialog.dart`
- `FE/lib/features/campaign/shared/repositories/campaign_repository.dart`

Current behavior:

- Event list displays events for campaign.
- Manager/admin can open create event dialog.
- Event detail shows info and edit button.
- Event form supports type, status, timestamps, note, location label, school selection, and manual map pin.
- Repository has archive event API call.

Relevant lines:

- Create event dialog from campaign events page: `campaign_events_page.dart:19`
- Event detail page: `event_detail_page.dart:15`
- Event detail edit: `event_detail_page.dart:28`
- Tab controller: `event_detail_page.dart:81`
- TabBar: `event_detail_page.dart:90`
- TabBarView: `event_detail_page.dart:100`
- Archive event repository: `campaign_repository.dart:103`
- Event form: `event_form_dialog.dart:14`
- Event form datetime fields: `event_form_dialog.dart:213`, `:222`
- Province center warning: `event_form_dialog.dart:313`
- Pick on map: `event_form_dialog.dart:335`

### 6.2 Potential Bug: Event Detail Tabs Did Not Switch During Audit

Observed:

- Repeated automated clicks on `Trường tham gia`, `Nhân sự`, and `Interactions` did not switch from `Thông tin`.
- Browser console showed no errors.

Files to inspect:

- `FE/lib/features/campaign/events/pages/event_detail_page.dart:81-106`

Possible causes:

- Flutter web canvas/hit-testing issue in audit environment.
- `TabBar` overlay or scroll/layout blocking pointer events.
- Coordinate automation issue.
- `TabBarView` gesture conflict.

Manual validation needed:

1. Open `/events/1` as manager/admin.
2. Click each tab by mouse.
3. Confirm whether content changes.
4. If it fails manually, fix as high priority.

Potential fix pattern:

- Replace nested `Column + TabBar + Expanded(TabBarView)` with `NestedScrollView` or simpler scaffold layout.
- Ensure no invisible overlay covers `TabBar`.
- Add `SafeArea` and avoid placing `TabBar` under draggable/stacked widgets.

Example safer layout:

```dart
return DefaultTabController(
  length: 4,
  child: Scaffold(
    appBar: AppBar(
      title: Text(event.name),
      bottom: const TabBar(
        isScrollable: true,
        tabs: [
          Tab(text: 'Thông tin'),
          Tab(text: 'Trường tham gia'),
          Tab(text: 'Nhân sự'),
          Tab(text: 'Interactions'),
        ],
      ),
    ),
    body: TabBarView(
      children: [
        EventInfoTab(...),
        EventSchoolsTab(...),
        EventEmployeesTab(...),
        EventInteractionsTab(...),
      ],
    ),
  ),
);
```

### 6.3 Issue: Missing Event Archive/Delete UI

Backend exists:

- `DELETE /api/v1/events/{eventId}`
- `CampaignRepository.archiveEvent(...)`

Relevant line:

- `FE/lib/features/campaign/shared/repositories/campaign_repository.dart:103`

Missing frontend:

- Archive button/menu in event list card.
- Archive button/menu in event detail.
- Confirmation dialog.
- Invalidate `campaignEventsProvider` and `campaignDashboardProvider`.

Recommended UX:

- Event card menu: Edit, Archive.
- Event detail app bar menu: Edit, Archive.
- Confirmation copy: `Archive this event? It will be hidden from default event lists.`

Pseudo-code:

```dart
Future<void> archiveEvent(BuildContext context, WidgetRef ref, CampaignEventModel event) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => ConfirmDialog(
      title: 'Archive event?',
      message: 'This event will be hidden from normal lists.',
    ),
  );
  if (confirmed != true) return;

  await ref.read(campaignRepositoryProvider).archiveEvent(event.id);
  ref.invalidate(campaignEventsProvider(event.campaignId));
  ref.invalidate(campaignDashboardProvider(event.campaignId));
  if (context.mounted) context.go('/campaigns/${event.campaignId}/events');
}
```

### 6.4 Issue: Date/Time UX Is Too Technical

Current:

- Event list shows raw ISO-like strings such as `2026-08-05T08:00:00`.
- Event form asks user to type `2026-06-20T08:00:00`.

Relevant lines:

- Event form datetime fields: `event_form_dialog.dart:213`, `:222`
- Date parse: `event_form_dialog.dart:374`

Impact:

- Error-prone for non-technical users.
- Looks unfinished.

Recommended:

- Use `showDatePicker` + `showTimePicker`.
- Store ISO in request body internally.
- Display localized format, e.g. `05/08/2026 08:00`.

Pattern:

```dart
Future<DateTime?> pickDateTime(BuildContext context, DateTime? initial) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial ?? DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
  if (date == null) return null;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial ?? DateTime.now()),
  );
  if (time == null) return null;

  return DateTime(date.year, date.month, date.day, time.hour, time.minute);
}
```

## 7. Interactions

### 7.1 Current Behavior

Relevant file:

- `FE/lib/features/campaign/presentation/widgets/event_interactions_tab.dart`

Current:

- Lists interactions.
- Can create interaction.
- Create form fields include school UID, participant type/id, channel, outcome, next follow-up, note.

Relevant lines:

- Create button: `event_interactions_tab.dart:24`
- Dialog class: `event_interactions_tab.dart:85`
- School UID field: `event_interactions_tab.dart:168`
- Participant ID field: `event_interactions_tab.dart:189`
- Follow-up datetime field: `event_interactions_tab.dart:238`

Backend supports:

- Create interaction.
- Update interaction.
- Delete interaction.

### 7.2 Issue: Interaction Edit/Delete UI Missing

Problem:

Repository currently exposes `createInteraction(...)` but not update/delete wrapper methods in FE, even though backend has endpoints.

Needed repository additions:

```dart
Future<InteractionModel> updateInteraction(
  int eventId,
  int interactionId,
  Map<String, dynamic> data,
) async { ... }

Future<void> deleteInteraction(int eventId, int interactionId) async { ... }
```

Needed UI:

- Interaction card menu: Edit, Delete.
- Reuse create dialog as create/edit dialog.
- Confirm delete.

### 7.3 Issue: Interaction Form Uses Raw IDs

Problem:

User must type:

- `School UID`
- `Participant ID`

Impact:

- Staff/manager may not know IDs.
- Easy to create invalid records.

Recommended:

- School field should be searchable dropdown based on assigned event schools.
- Participant should be selected from students/persons/relatives for selected school.
- If participant type changes, list source changes.

Pattern:

```dart
selectedSchool -> load students/persons/relatives -> select participant -> submit participantId
```

## 8. Schools And School Detail

### 8.1 Current Behavior

Relevant files:

- `FE/lib/features/school/presentation/pages/school_list_page.dart`
- `FE/lib/features/school/presentation/pages/school_detail_page.dart`
- `FE/lib/features/school/shared/models/school_model.dart`
- `BE/postgres/campaign-module.sql`

Current:

- School list supports search, province code, commune code, area filter.
- School detail shows overview, students, persons, relatives.
- School detail is read-only.

Relevant lines:

- School list page: `school_list_page.dart:9`
- Province filter controller: `school_list_page.dart:18`
- Commune filter controller: `school_list_page.dart:19`
- Query params: `school_list_page.dart:25-26`
- Count text: `school_list_page.dart:82`
- Search hint: `school_list_page.dart:146`
- Address display: `school_list_page.dart:235`
- School detail page: `school_detail_page.dart:7`
- Tab controller: `school_detail_page.dart:24`
- TabBar: `school_detail_page.dart:33`
- TabBarView: `school_detail_page.dart:43`
- Address row: `school_detail_page.dart:102`
- School model address only: `school_model.dart:41`, `:52`, `:64`

### 8.2 Potential Bug: School Detail Tabs Did Not Switch During Audit

Observed:

- Repeated automated clicks on `Học sinh`, `GV/BGH`, `Người thân` did not switch from `Tổng quan`.
- Browser console showed no errors.

Files to inspect:

- `FE/lib/features/school/presentation/pages/school_detail_page.dart:24-46`

Same recommendation as Event Detail:

- Verify manually.
- If reproducible, move `TabBar` into `AppBar.bottom` or simplify layout.

### 8.3 Issue: School Filters Are Hard To Use

Problem:

Users must type province and commune codes manually.

Relevant lines:

- `school_list_page.dart:155`
- `school_list_page.dart:163`

Recommended:

- Province dropdown/search using existing geo providers.
- Commune dropdown depends on selected province.
- Keep code filters internally, but expose names to user.

Suggested UX:

```text
Province: [Hà Nội v]
Commune: [Xã Suối Hai v]
Area: [KV1 v]
Search: [school name/address]
```

Implementation pattern:

```dart
ProvinceSelector(
  selectedCode: provinceCode,
  onChanged: (province) {
    setState(() {
      provinceCode = province.code;
      communeCode = null;
    });
  },
)

CommuneSelector(
  provinceCode: provinceCode,
  selectedCode: communeCode,
  onChanged: (commune) => setState(() => communeCode = commune.code),
)
```

### 8.4 Issue: School Location Not Supported Yet

Current DB:

- `schools` table has `address`.
- It does not have school latitude/longitude.

Relevant schema:

- `BE/postgres/campaign-module.sql:1`
- `BE/postgres/campaign-module.sql:10`

Note:

- Event table has location columns:
  - `BE/postgres/campaign-module.sql:90`
  - `BE/postgres/campaign-module.sql:91`
  - `BE/postgres/campaign-module.sql:92`

Impact:

- Clicking a school cannot show exact school location.
- Event form currently falls back to province center when selecting a school, which is only approximate.

Recommended DB migration:

```sql
ALTER TABLE schools
  ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS geocode_source VARCHAR(50),
  ADD COLUMN IF NOT EXISTS geocode_confidence DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS geocoded_at TIMESTAMP;

CREATE INDEX IF NOT EXISTS idx_schools_location
  ON schools(latitude, longitude);
```

Recommended DTO/model changes:

Backend `SchoolDto`:

```java
public record SchoolDto(
    String schoolUid,
    String provinceCode,
    String provinceName,
    String communeCode,
    String communeName,
    String schoolCode,
    String schoolName,
    String address,
    String areaType,
    Double latitude,
    Double longitude
) {}
```

Frontend `SchoolModel`:

```dart
final double? latitude;
final double? longitude;

bool get hasLocation => latitude != null && longitude != null;
```

School detail button:

```dart
if (school.hasLocation)
  FilledButton.icon(
    onPressed: () => context.push(
      '/map?lat=${school.latitude}&lng=${school.longitude}'
      '&eventName=${Uri.encodeComponent(school.schoolName)}',
    ),
    icon: const Icon(Icons.map_outlined),
    label: const Text('View on map'),
  )
else
  FilledButton.tonalIcon(
    onPressed: () => openGeocodeSuggestion(school),
    icon: const Icon(Icons.location_searching),
    label: const Text('Find location'),
  )
```

### 8.5 Suggested School Geocoding Approaches

Recommended approach: hybrid automatic + manual correction.

Option A: Batch geocode during import

- Build query: `school_name + address + commune_name + province_name + Việt Nam`
- Call geocoding provider.
- Save lat/lng and source/confidence.
- Best for performance because frontend never calls geocoder directly.

Option B: On-demand geocode when admin opens school detail

- If school has no lat/lng, backend geocodes and stores.
- Good for incremental rollout.
- Need rate limiting and cache.

Option C: Manual pin only

- Admin opens school detail.
- Click `Set location`.
- Pick or drag marker on map.
- Save lat/lng.
- Most accurate when address quality is poor.

Option D: Commune/province centroid fallback

- Use existing administrative centroids if geocoding fails.
- Mark as approximate, not exact.

Recommended final flow:

```text
Import school address
-> batch geocode
-> save lat/lng + confidence
-> if confidence low, use commune centroid as approximate
-> admin can manually correct pin
-> event form uses school lat/lng, fallback to commune/province centroid
```

Recommended geocoding service abstraction:

```java
public interface GeocodingService {
    GeocodeResult geocodeSchool(SchoolDto school);
}

public record GeocodeResult(
    Double latitude,
    Double longitude,
    String source,
    Double confidence,
    String formattedAddress
) {}
```

## 9. Map Screen

### 9.1 Current Behavior

Relevant files:

- `FE/lib/features/map/presentation/pages/map_page.dart`
- `FE/lib/features/map/presentation/widgets/vietnam_map_view.dart`
- `FE/lib/app/router.dart`

Current:

- Mobile map shows `VietnamMapView` plus `DraggableScrollableSheet`.
- Wide layout renders map on left from `_AppShell`.

Relevant lines:

- Map page: `map_page.dart:6`
- Wide behavior: `map_page.dart:24`
- Mobile stack: `map_page.dart:34`
- Shell wide mode includes map: `router.dart:224-230`

### 9.2 Issue: Map Is The Heaviest Screen

Observed:

- Map route took around 5-6 seconds to visibly settle during audit.

Likely causes:

- Boundary GeoJSON load.
- Tile loading.
- Flutter web debug mode.
- Many map layers/markers/labels.

Recommended improvements:

- Show a clear map loading overlay: `Loading boundaries...`, `Loading tiles...`.
- Cache province boundaries in memory/local storage.
- Lazy-load commune boundaries only after zoom or province select.
- Simplify geometry before sending to FE.
- Consider vector tile or pre-simplified GeoJSON for web.

Pattern:

```dart
Stack(
  children: [
    VietnamMapView(...),
    if (boundaryAsync.isLoading)
      const MapLoadingOverlay(message: 'Loading map boundaries...'),
  ],
)
```

### 9.3 Issue: Bottom Sheet Can Hide Map Content

Current:

- `DraggableScrollableSheet` starts at `0.4`.

Relevant line:

- `map_page.dart:39`

Recommendation:

- Start collapsed lower, e.g. `initialChildSize: 0.25`.
- Add a visible handle and label.
- Add quick button to collapse/expand.

## 10. Weather Screen

### 10.1 Current Behavior

Relevant file:

- `FE/lib/features/weather/presentation/pages/weather_page.dart`

Observed:

- Weather screen loads successfully.
- No console errors.

### 10.2 Issue: Mojibake/Encoding In Source

Observed in source:

- `Thá»i tiáº¿t`
- `LÃ m má»›i`
- `Äang táº£i thá»i tiáº¿t...`
- `Cáº­p nháº­t lÃºc`

Relevant lines:

- `weather_page.dart`

Note:

- Browser screenshot displayed Vietnamese correctly in some places, but source contains corrupted text. This can become visible in other environments or future edits.

Recommendation:

- Normalize files to UTF-8.
- Replace corrupted literals with proper Vietnamese:

```dart
title: const Text('Thời tiết')
tooltip: 'Làm mới'
LoadingWidget(message: 'Đang tải thời tiết...')
'Cập nhật lúc: ...'
```

## 11. Admin Users

### 11.1 Current Behavior

Relevant file:

- `FE/lib/features/admin/presentation/pages/admin_users_page.dart`

Current:

- Admin can view users.
- Admin can change role via popup menu.

Missing:

- Create user.
- Edit user.
- Delete user.
- Change status.
- Search/filter.
- Confirmation dialog.
- Role/status chips.

Backend already supports:

- `GET /api/v1/users`
- `POST /api/v1/users`
- `PUT /api/v1/users/{id}`
- `DELETE /api/v1/users/{id}`
- `PUT /api/v1/users/{id}/role`
- `PUT /api/v1/users/{id}/status`

Relevant backend:

- `BE/src/main/java/com/vnmap/campaign/controller/CampaignController.java:423+`

Recommended UI:

```text
Users page
  Search input
  Role filter
  Status filter
  Create User FAB
  User row/card:
    email
    role chip
    status chip
    linked employee/student
    actions: Edit, Change role, Toggle status, Delete
```

Recommended repository additions:

```dart
Future<UserModel> createUser(UserRequest request);
Future<UserModel> updateUser(int id, UserRequest request);
Future<void> deleteUser(int id);
```

Recommended model:

```dart
class UserModel {
  final int id;
  final String email;
  final String role;
  final String status;
  final int? employeeId;
  final int? studentId;
}
```

## 12. App Shell And Navigation

### 12.1 Current Behavior

Relevant file:

- `FE/lib/app/router.dart`

The app shell:

- Uses `NavigationBar`.
- On width > 600, renders map on the left and feature content on the right.

Relevant lines:

- `_AppShell`: `router.dart:182`
- NavigationBar: `router.dart:206`
- Destination selection: `router.dart:208`
- Wide layout breakpoint: `router.dart:224`
- Wide left map: `router.dart:230`
- Role nav items: `router.dart:271`

### 12.2 Issue: Wide Layout Always Renders Map

Problem:

For every page on wide screens, the app renders `VietnamMapView` on the left.

Impact:

- Admin/users/campaign/dashboard pages may pay map render cost even when user is not using map.
- This can make non-map pages feel slower on desktop/tablet.

Recommendation:

- Render left map only for map-related screens, or make it collapsible.
- For admin/dashboard pages, use full width or a lightweight side navigation.

Pattern:

```dart
final showMapPane = location.startsWith('/map') ||
    location.startsWith('/schools') ||
    location.contains('lat=');

if (constraints.maxWidth > 600 && showMapPane) {
  return SplitMapLayout(child: child);
}

return StandardShell(child: child, navBar: navBar);
```

### 12.3 Issue: Bottom Navigation Can Cover Content

Observed:

- Several pages place lists under a bottom navigation.
- Some pages include bottom padding, others rely on content size.

Recommendation:

- Standardize page bottom padding:

```dart
const EdgeInsets.fromLTRB(16, 16, 16, 96)
```

- Or wrap shell body with `SafeArea(bottom: false)` and provide a `PageScaffold` helper.

Suggested pattern:

```dart
class AppPageList extends StatelessWidget {
  const AppPageList({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: children,
    );
  }
}
```

## 13. Encoding / Text Quality

### 13.1 Issue: Corrupted Vietnamese Text In Source

Observed in multiple places during earlier code audit:

- Event tabs had corrupted source text in one snapshot previously.
- School detail source had corrupted tab strings previously.
- Weather source definitely contains corrupted text.

Run command to find:

```powershell
rg -n "ThÃ|LÃ|Ä|Tá|NgÆ|Há|TrÆ|Cáº|tiá|Má|Ä" FE\lib
```

Recommendation:

- Normalize all Dart source files as UTF-8.
- Replace corrupted strings.
- Add a quick text smoke test or golden text checklist.

## 14. Performance Checklist

### 14.1 Current Performance Observations

Measured through browser audit:

```text
Campaign list direct route: around 7s including Flutter web warm-up
Campaign dashboard: around 2.8-3.0s with fixed audit wait
Campaign events: around 2.7-3.0s with fixed audit wait
Event detail: around 3.1s with fixed audit wait
Schools: around 3.4s with fixed audit wait
School detail: around 3.3s with fixed audit wait
Weather: around 3.8s with fixed audit wait
Map: around 6.0s with fixed audit wait
```

Important:

- These are not exact render-complete timings because audit included fixed waits.
- API timing was fast.
- Flutter debug mode is slower than release.

### 14.2 Recommended Performance Work

Frontend:

- Build and test release web:

```powershell
flutter build web --release
```

- Compare with debug mode.
- Add skeleton states instead of full-screen spinner.
- Avoid rendering `VietnamMapView` on every wide screen.
- Lazy-load map boundaries.
- Cache provider data where safe.

Backend:

- Dashboard SQL currently OK for seed data.
- If dataset grows, add indexes for:
  - `interactions(campaign_id, created_at)`
  - `campaign_events(campaign_id, status)`
  - `campaign_student_registrations(campaign_id, status)`

## 15. Suggested Implementation Phases

### Phase 1 - Stabilize UX And Navigation

Priority: high.

Tasks:

- Verify/fix tab switching in Event Detail.
- Verify/fix tab switching in School Detail.
- Add consistent bottom padding to all scrollable pages.
- Fix corrupted Vietnamese strings.
- Format event date/time for display.
- Replace full-screen dashboard spinner with section skeletons.

Files:

- `FE/lib/features/campaign/events/pages/event_detail_page.dart`
- `FE/lib/features/school/presentation/pages/school_detail_page.dart`
- `FE/lib/features/weather/presentation/pages/weather_page.dart`
- `FE/lib/features/campaign/dashboard/pages/campaign_dashboard_page.dart`
- `FE/lib/app/router.dart`

### Phase 2 - Complete Core CRUD UI

Priority: high.

Tasks:

- Campaign create/edit/archive UI.
- Event archive/delete UI.
- Interaction edit/delete UI.
- Admin user create/edit/status/delete/search/filter.
- Employee CRUD page if managers/admin need to maintain staff.

Files:

- `FE/lib/features/campaign/dashboard/pages/campaign_list_page.dart`
- `FE/lib/features/campaign/events/pages/campaign_events_page.dart`
- `FE/lib/features/campaign/events/pages/event_detail_page.dart`
- `FE/lib/features/campaign/presentation/widgets/event_interactions_tab.dart`
- `FE/lib/features/admin/presentation/pages/admin_users_page.dart`
- `FE/lib/features/campaign/shared/repositories/campaign_repository.dart`

### Phase 3 - Real Dashboard

Priority: medium-high.

Tasks:

- Add `fl_chart`.
- Add chart widgets.
- Extend backend dashboard DTO for event status/type, registration status, interaction time series, employee workload.
- Add empty states for no data.

Files:

- `FE/pubspec.yaml`
- `FE/lib/features/campaign/dashboard/pages/campaign_dashboard_page.dart`
- `BE/src/main/java/com/vnmap/campaign/dto/CampaignDashboardDto.java`
- `BE/src/main/java/com/vnmap/campaign/service/CampaignService.java`

### Phase 4 - School Location / Geocoding

Priority: medium-high because user requested click-school-to-map.

Tasks:

- Add school lat/lng columns.
- Add geocoding service and backfill job.
- Add lat/lng to `SchoolDto` and `SchoolModel`.
- Add `View on map` button in school cards/detail.
- Update event form to use school exact location.
- Add manual pin correction UI for admin/manager.

Files:

- `BE/postgres/campaign-module.sql`
- `BE/src/main/java/com/vnmap/campaign/dto/SchoolDto.java`
- `BE/src/main/java/com/vnmap/campaign/service/CampaignService.java`
- `FE/lib/features/school/shared/models/school_model.dart`
- `FE/lib/features/school/presentation/pages/school_list_page.dart`
- `FE/lib/features/school/presentation/pages/school_detail_page.dart`
- `FE/lib/features/campaign/events/widgets/event_form_dialog.dart`
- `FE/lib/features/map/presentation/pages/map_page.dart`

### Phase 5 - School/Student/Person/Relative Management

Priority: medium.

Tasks:

- Add CRUD UI in School Detail tabs.
- Add student/person/relative create/edit/delete dialogs.
- Add validation and confirmation dialogs.

Backend APIs already exist for students/persons/relatives.

Relevant backend:

- `BE/src/main/java/com/vnmap/campaign/controller/CampaignController.java`

## 16. Suggested Shared UI Patterns

### 16.1 Confirm Dialog

Use for archive/delete/status changes.

```dart
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmText = 'Confirm',
  });

  final String title;
  final String message;
  final String confirmText;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
        ),
      ],
    );
  }
}
```

### 16.2 Async Section

Avoid full-screen loaders for dashboard sections.

```dart
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.value,
    required this.builder,
    required this.loading,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final Widget loading;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading,
      error: (error, _) => InlineError(message: error.toString()),
      data: builder,
    );
  }
}
```

### 16.3 Entity Form Dialog Pattern

Use same dialog for create/edit.

```dart
class EntityFormDialog<T> extends StatefulWidget {
  const EntityFormDialog({
    super.key,
    this.initial,
    required this.onSubmit,
  });

  final T? initial;
  final Future<void> Function(Map<String, dynamic> data) onSubmit;
}
```

### 16.4 Repository Method Pattern

Keep all API wrappers in repository, not inside widgets.

```dart
Future<T> _parseOne<T>(
  Future<Response<Map<String, dynamic>>> request,
  T Function(Object? json) fromJson,
) async {
  final res = await request;
  final api = ApiResponse.fromJson(res.data!, fromJson);
  _assertSuccess(api);
  return api.data!;
}
```

## 17. Acceptance Criteria For Future Fixes

Dashboard:

- Dashboard shows at least 4 charts.
- Loading is section-based, not one full-screen spinner.
- No bottom nav overlap.
- Empty datasets show friendly empty states.

Campaign CRUD:

- Create uses a form.
- Edit works.
- Archive has confirmation.
- Archived list can be viewed by manager/admin.

Event CRUD:

- Create/edit/archive available.
- Date/time pickers replace manual ISO input.
- Event cards display friendly date/time.
- Event detail tabs switch reliably.

School location:

- School has stored lat/lng or approximate fallback.
- School list/detail has `View on map`.
- Event form auto-fills exact school location if available.
- Admin/manager can correct location manually.

Admin users:

- Search/filter works.
- Create/edit/delete/status/role all available.
- Destructive actions ask confirmation.

Performance:

- Dashboard API remains under 300ms for normal data.
- Map displays clear loading state.
- Wide non-map screens do not render heavy map pane unless needed.

## 18. Quick Priority List

1. Verify/fix Event Detail and School Detail tab switching.
2. Replace campaign hardcoded create with real form.
3. Add event archive/delete UI.
4. Add dashboard charts and section skeletons.
5. Add school lat/lng + geocoding + `View on map`.
6. Complete admin user CRUD UI.
7. Replace raw IDs/code filters with searchable dropdowns.
8. Improve map loading/caching and avoid wide-layout map render on unrelated pages.
9. Fix corrupted Vietnamese strings in source.

