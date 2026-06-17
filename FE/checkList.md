Based on the detailed plan we agreed upon, **Member 1's** primary responsibility focuses entirely on the **Campaign Dashboard** (Campaign Overview and Analytics).

This task is for the person handling data display, KPI analytics, and high-level campaign list management. The major advantage of this role is that it **relies completely on the Dashboard APIs**, meaning it can be started independently right away without being blocked by other team members.

Here is the detailed breakdown of Member 1's tasks:

### 1. Assigned Routes (GoRouter)

* `/campaigns`: Master list of all campaigns.
* `/campaigns/:campaignId/dashboard`: Detailed analytics dashboard for a specific campaign.

### 2. Detailed Screen Implementations

#### Campaign List Screen (`/campaigns`)

* **UI:** Design as Cards or a Table (responsive: use a table for wide screens, switch to cards for narrow/mobile screens).
* **Item Details:** Each item must display `name`, `status chip`, `objective`, `startDate - endDate`, and `ownerEmployeeId`.
* **Features:**
* Implement local (or API-based) filtering by status (`ALL`, `DRAFT`, `ACTIVE`, `DONE`, `CANCELLED`).
* Local search by campaign name.
* Clicking an item navigates to its respective dashboard (`/campaigns/:id/dashboard`).


* **UI States:** Must handle all 3 states: Loading (Skeleton/CircularProgress), Error (display error message + **Retry** button), and Empty state (show "No campaigns yet" if the list is empty).

#### Campaign Dashboard Screen (`/campaigns/:campaignId/dashboard`)

* **Data Loading Mechanism:** Make parallel API calls (fetching both Campaign detail and Dashboard data simultaneously).
* **Header:** Show the campaign name, objective, status chip, and date range.
* **KPI Cards (Top metrics):** Clearly display 4 metrics: `totalEvents`, `totalTargetSchools`, `totalAssignedEmployees`, and `totalInteractions`.
* **Outcome Section:** Render a chart or list of interactions by outcome (must display at least 3 statuses: `INTERESTED`, `NOT_INTERESTED`, `FOLLOW_UP`).
* **By Province Section:** A table displaying `provinceName`, `provinceCode`, and `totalInteractions`.
* **Top Schools Section:** A table displaying `schoolName`, `schoolUid`, and `totalInteractions`.
* **Refresh Feature:** Place a Refresh button in the Header (or implement Pull-to-refresh) to trigger state invalidation: `ref.invalidate(campaignDashboardProvider(campaignId));`.

### 3. APIs & Layered Architecture

* **Consumed APIs:**
* `GET /api/v1/campaigns`
* `GET /api/v1/campaigns/{id}`
* `GET /api/v1/campaigns/{id}/dashboard`


* **Models:** Strictly use the data structures from the shared `campaign_models.dart` file. **Do not create duplicate models.**
* **Repository:** Add the `Future<CampaignModel> getCampaign(int campaignId)` method to the `CampaignRepository` if it doesn't already exist.
* **Provider (Riverpod):** Implement `campaignDetailProvider` and `campaignDashboardProvider` as `FutureProvider.family` to manage state based on the `campaignId`.

### 4. Acceptance Criteria (Definition of Done)

* Opening `/campaigns` must show at least 2 pre-existing (seed data) campaigns.
* Clicking on campaign ID = 1 must accurately display: `totalInteractions = 3` and `INTERESTED = 3`.
* Clicking the Refresh button updates data normally without crashing or causing a blank/red error screen.
* If the backend is offline/disconnected, the screen must clearly show an Error state with a Retry button, not just a blank screen.