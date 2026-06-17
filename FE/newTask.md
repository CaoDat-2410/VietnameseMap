# Common Setup Before Splitting Tasks

The team lead or the first developer who starts working must confirm that the following shared files already exist and that no duplicate versions are created:

* `FE/lib/core/config/dev_identity.dart`
* `FE/lib/features/campaign/shared/models/campaign_models.dart`
* `FE/lib/features/campaign/shared/repositories/campaign_repository.dart`
* `FE/lib/features/campaign/shared/providers/campaign_provider.dart`
* `FE/lib/features/school/shared/models/school_model.dart`
* `FE/lib/features/school/shared/repositories/schools_repository.dart`
* `FE/lib/features/school/shared/providers/schools_provider.dart`

## General Rules

* Always unwrap API responses from the `data` field.
* Temporarily use `devEmployeeId = 1` for `employeeId`.
* Do not create duplicate models, repositories, or providers.
* Do not modify map/weather features unless directly related to your task.
* Every screen must include:

  * Loading state
  * Error state
  * Empty state

---

# Member 1: Campaign Dashboard

## Objective

Build screens that allow managers to view campaign overviews and performance metrics.

## Scope

* Campaign list
* Campaign detail dashboard
* KPI statistics
* Dashboard refresh functionality

## Routes

* `/campaigns`
* `/campaigns/:campaignId/dashboard`

---

## Screen: `/campaigns`

### UI Requirements

* AppBar title: **Campaigns**
* Display campaigns in a card list or table view.

Each campaign item should display:

* `name`
* `status`
* `objective`
* `startDate - endDate`
* `ownerEmployeeId`

### Navigation

Clicking a campaign should navigate to:

`/campaigns/:id/dashboard`

### States

**Empty State**

* Show: `No campaigns yet.`

**Error State**

* Show error message
* Show Retry button

---

## Screen: `/campaigns/:id/dashboard`

### Header

Display:

* Campaign name
* Status chip
* Date range

### KPI Cards

Display:

* `totalEvents`
* `totalTargetSchools`
* `totalAssignedEmployees`
* `totalInteractions`

### Outcome Section

Render data from:

`interactionsByOutcome`

At minimum display:

* `INTERESTED`
* `NOT_INTERESTED`
* `FOLLOW_UP`

### By Province Section

Table columns:

* Province
* Interactions

### Top Schools Section

Table columns:

* School Name
* School UID
* Interactions

### Actions

* Refresh Dashboard button

---

## APIs

```http
GET /api/v1/campaigns
GET /api/v1/campaigns/{id}
GET /api/v1/campaigns/{id}/dashboard
```

### Provider (Add if Missing)

```dart
final campaignDetailProvider =
    FutureProvider.family<CampaignModel, int>((ref, campaignId) {
  // add method getCampaign(campaignId)
  // in CampaignRepository if needed
});
```

### Repository Method (Add if Missing)

```dart
Future<CampaignModel> getCampaign(int campaignId);
```

---

## Suggested UI Files

```text
FE/lib/features/campaign/dashboard/pages/campaign_list_page.dart
FE/lib/features/campaign/dashboard/pages/campaign_dashboard_page.dart

FE/lib/features/campaign/dashboard/widgets/campaign_kpi_card.dart
FE/lib/features/campaign/dashboard/widgets/outcome_summary_table.dart
FE/lib/features/campaign/dashboard/widgets/province_interaction_table.dart
FE/lib/features/campaign/dashboard/widgets/top_school_table.dart
```

---

## Acceptance Criteria

* Opening `/campaigns` displays at least 2 seeded campaigns.
* Opening campaign ID `1` displays:

  * `totalInteractions = 3`
  * `INTERESTED = 3`
* Dashboard refresh works without crashing.
* No blank screen appears when API requests fail.
