# Design

## Visual Theme

**Style:** Soft Minimalism + Bento Cards — professional dashboard aesthetic with structured surface hierarchy, subtle depth, and a restrained color palette. Not flat-for-the-sake-of-flat; depth is present but never heavy.

**Philosophy:** Every surface earns its place. Cards organize related data. Spacing creates rhythm, not decoration. Color signals state, not style.

## Color Palette

### Primary — Indigo
Used for primary actions, selected states, and interactive accents.

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `primary` | `#6366F1` | `#818CF8` | Primary buttons, active nav, links |
| `primaryLight` | `#818CF8` | — | Hover states, gradients |
| `primaryDark` | `#4F46E5` | — | Pressed states |
| `primaryContainer` | `#EEF2FF` | `#312E81` | Selected nav item bg, chip fills |
| `onPrimaryContainer` | `#312E81` | `#EEF2FF` | Text on container |

### Secondary — Slate
Used for secondary UI, neutral surfaces, and text hierarchy.

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `secondary` | `#64748B` | `#94A3B8` | Secondary actions, inactive icons |
| `secondaryContainer` | `#F1F5F9` | `#475569` | Secondary chips, tag fills |
| `onSecondaryContainer` | `#1E293B` | `#F1F5F9` | Text on secondary surfaces |

### Tertiary — Teal
Used sparingly for positive/confirm accents.

| Token | Light | Dark |
|-------|-------|------|
| `tertiary` | `#14B8A6` | `#14B8A6` |
| `tertiaryContainer` | `#CCFBF1` | `#CCFBF1` |

### Surfaces

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `surface` | `#FFFFFF` | `#0F172A` | Page backgrounds |
| `surfaceContainer` | `#F8FAFC` | `#1E293B` | Card backgrounds |
| `surfaceContainerHigh` | `#F1F5F9` | `#334155` | Elevated cards, dialogs |
| `surfaceContainerHighest` | `#E2E8F0` | `#475569` | Modals, overlays |

### Text

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `onSurface` | `#0F172A` | `#F8FAFC` | Primary text, headings |
| `onSurfaceVariant` | `#475569` | `#CBD5E1` | Secondary text, labels |
| `outline` | `#E2E8F0` | `#334155` | Borders, dividers |
| `outlineVariant` | `#94A3B8` | `#64748B` | Disabled states |

### Status Colors

| Token | Color | Usage |
|-------|-------|-------|
| `success` | `#22C55E` | Completed, active, registered |
| `warning` | `#F59E0B` | Pending, follow-up, draft |
| `error` | `#EF4444` | Failed, cancelled, validation |
| `info` | `#3B82F6` | Informational, neutral status |

### Chart Palette
Ordered for visual variety; reuse per-chart when possible.

```
#6366F1 (Indigo) → #8B5CF6 (Violet) → #EC4899 (Pink)
→ #14B8A6 (Teal) → #22C55E (Green) → #F59E0B (Amber)
→ #64748B (Slate) → #EF4444 (Red)
```

### Shimmer (Loading Skeletons)

| Token | Light | Dark |
|-------|-------|------|
| shimmerBase | `#E2E8F0` | `#334155` |
| shimmerHighlight | `#F8FAFC` | `#475569` |

## Typography

**Font family:** `Roboto` (primary), `RobotoMono` (code/metrics)

No custom Google Fonts required — Roboto is bundled with Flutter.

### Scale

| Style | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| `displayLarge` | 57px | 700 | 1.12 | Not used (too large) |
| `displayMedium` | 45px | 700 | 1.16 | Not used |
| `displaySmall` | 36px | 600 | 1.22 | Not used |
| `headlineLarge` | 32px | 600 | 1.25 | Page titles |
| `headlineMedium` | 28px | 600 | 1.29 | Section headers |
| `headlineSmall` | 24px | 600 | 1.33 | Card titles |
| `titleLarge` | 22px | 500 | 1.27 | App bar titles |
| `titleMedium` | 16px | 500 | 1.5 | List item titles |
| `titleSmall` | 14px | 500 | 1.43 | Chips, small labels |
| `bodyLarge` | 16px | 400 | 1.5 | Primary body text |
| `bodyMedium` | 14px | 400 | 1.43 | Secondary body text |
| `bodySmall` | 12px | 400 | 1.33 | Captions, helper text |
| `labelLarge` | 14px | 500 | 1.43 | Button text |
| `labelMedium` | 12px | 500 | 1.33 | Tab labels, tags |
| `labelSmall` | 11px | 500 | 1.45 | Nav labels, badges |

### KPI / Metric Numbers
Large numeric displays (dashboard KPIs, chart labels):
- `kpiLarge`: 48px, weight 700, letter-spacing -1
- `kpiMedium`: 32px, weight 700, letter-spacing -0.5

## Spacing System

Base unit: 4px.

| Token | Value | Usage |
|-------|-------|-------|
| `xxs` | 2px | Minimal inline gaps |
| `xs` | 4px | Icon-to-text, tight lists |
| `sm` | 8px | List item padding, chip gaps |
| `md` | 12px | Card internal padding (compact) |
| `base` | 16px | Standard padding, card padding |
| `lg` | 20px | Section gaps |
| `xl` | 24px | Card padding (spacious), section headers |
| `xxl` | 32px | Page section gaps |
| `xxxl` | 48px | Major page divisions |

## Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radiusXs` | 4px | Small badges, tags |
| `radiusSm` | 6px | Chips, small buttons |
| `radiusMd` | 8px | Inputs, small cards |
| `radiusBase` | 10px | Standard buttons |
| `radiusLg` | 12px | Cards, dialogs |
| `radiusXl` | 16px | Bottom sheets, large cards |
| `radius2xl` | 20px | Dialogs, large modals |
| `radius3xl` | 24px | Not actively used |
| `radiusFull` | 999px | FAB, pill buttons, avatars |

## Elevation (Shadows)

| Level | Blur | Offset | Usage |
|-------|------|--------|-------|
| XS | 2px | 0, 1px | Subtle card lift |
| SM | 4px | 0, 2px | Hover, elevated buttons |
| Base | 8px | 0, 4px | Standard cards, dialogs |
| MD | 12px | 0, 6px | Floating elements |
| LG | 16px | 0, 8px | Modal dialogs, FABs |
| XL | 24px | 0, 12px | Full-page overlays |

**Rule:** Cards use `elevation: 0` + `BorderSide` in light mode. In dark mode, surface elevation is achieved through color differentiation, not shadow.

## Navigation

### Desktop (≥900px)
Collapsible sidebar: **240px expanded / 72px collapsed**.
- `AppSidebar` — full labels + icons when expanded; icons + tooltips when collapsed
- `SidebarExpandedNotifier` persists state to `SharedPreferences` key `sidebar.expanded`
- Active item: `primaryContainer` background, `primary` icon/text
- Hover: subtle tint of `primary` at 5% opacity

### Mobile (<900px)
- `AppDrawer` wraps `AppSidebar` in a `Drawer` widget
- Hamburger button in `AppBar` opens drawer

### Bottom Navigation (legacy — replaced)
Previous `NavigationBar` with 7 items violated Material Design `bottom-nav-limit`. Replaced by sidebar/drawer pattern.

### Breakpoints
| Name | Width | Layout |
|------|-------|--------|
| Mobile | < 600px | Single column, full-width |
| Tablet | 600–899px | Side drawer, optimized columns |
| Desktop | ≥ 900px | Persistent sidebar, multi-column |

## Components

### Bento Card
Primary container component. Soft-minimalist with optional accent tint.

- `BentoCard` — base container with 12px radius, `surface` background, 1px `outline` border
- `KpiCard` — large metric number + label + optional trend indicator
- `StatusChip` — color-coded label: `success`/`warning`/`error`/`info` + text, no icon-only states

### Chart Card
Wraps all charts with `BaseChartCard`:
- 12px radius, surface background
- Optional `ChartEmptyState` (icon + localized message) when no data
- 600ms fade+slide entrance animation
- Modern tooltips: `tooltipRoundedRadius: 8`, grid lines with `dividerColor.withValues(alpha: 0.3)`

### Bottom Sheet
`ModernBottomSheet` used for map info panels and quick-action sheets:
- `DraggableScrollableSheet` starting at 0.4 (map) or 0.25 (compact)
- 24px top radius
- Visible handle indicator

### Sidebar
`AnalyticsSidebar` (280/72px) and `AppSidebar` (240/72px):
- Both use `primaryContainer` highlight for active item
- Both persist expanded state to `SharedPreferences`
- Tooltip on collapsed icon items

### Data Table
`UserAdminTable` using `PaginatedDataTable2`:
- Debounced search on email column
- Sortable columns: email, role, status, employee ID, student ID
- Role/Status filter dropdowns
- Inline `IconButton` actions (edit, toggle status, delete)
- `UserRoleChip` + `UserStatusChip` for cell rendering

### Empty States
Never show empty space. Every list/chart has an empty state:
- Icon (contextual, 48px)
- Heading: what is empty (e.g., "Chưa có chiến dịch nào")
- Optional subtext with action hint
- Optional action button (e.g., "Tạo chiến dịch đầu tiên")

### Loading States
- **Page-level**: `Scaffold` shell renders immediately; content area shows shimmer skeleton
- **Section-level**: Each async section renders its own shimmer via `BaseChartCard` + `ChartEmptyState("Đang tải…")`
- **Shimmer animation**: 1.5s linear sweep, `shimmerBase` → `shimmerHighlight` → `shimmerBase`

### Error States
- **Inline error**: Red `Card` with `Icons.error_outline` + error message + `FilledButton` retry
- **Full-page error**: `AppErrorWidget` centered with icon + message + retry
- Never silently swallow errors

## Layout Patterns

### Page Structure
```
AppBar (title + actions)
  ↓
Content (scrollable)
  ├── Page header (title + subtitle + primary action)
  ├── Filter/Search bar (if applicable)
  └── Content sections (cards, lists, charts)
      Bottom padding: 96px (prevents FAB overlap)
```

### Responsive Grid
- **≤600px**: 1 column
- **601–900px**: 2 columns (bento grid)
- **≥901px**: 3–4 columns (bento grid)

### Sidebar Layout
- Desktop (≥900px): `Row([sidebar | content])`
- Mobile (<900px): `Scaffold(drawer: AppDrawer)`

### Analytics Page
- `ResponsiveSidebarLayout` with `AnalyticsSidebar` (280px / 72px)
- Charts render to the right of the sidebar on desktop
- Sidebar collapses to icon strip, expanded state persisted

## Dark Mode

Dark mode is a full theme, not a color invert. Key rules:

- **Backgrounds**: Slate-900 → Slate-800 → Slate-700 hierarchy (never pure black)
- **Borders**: `borderDark` (`#334155`) instead of light borders
- **Text**: Light text on dark surfaces — `onSurface` inverts to Slate-50
- **Cards**: `surfaceContainerHighDark` background, 1px `borderDark` border (no shadow)
- **Charts**: Same palette, chart tooltips use `surfaceContainerHighestDark`
- **Map tiles**: CartoDB dark tiles (`dark_all`) in dark mode

All color tokens have light/dark variants. Use `Theme.of(context).colorScheme.*` or `AppColors.*` tokens — never hardcoded hex values.

## Motion & Animation

### Principles
- **Entrance**: Fade + slide (200–400ms). Never content-gated — visible by default, animated in.
- **Duration scale**: Micro (hover, toggle): 150ms; Standard (page, card): 300ms; Complex (sidebar): 400ms
- **Easing**: `Curves.easeOut` for exits, `Curves.easeInOut` for state changes
- **Stagger**: 50ms delay between list items; never uniform delay across unrelated sections

### Page Transitions
Custom `SlidePageRoute` with 300ms `easeInOut`. Configured in `router.dart`.

### Reduced Motion
All animations respect `MediaQuery.disableAnimations`. Instant crossfade or no animation as fallback.

## Icon System

Material Icons (outlined variant for nav, filled for actions):
- Navigation: outlined (`Icons.campaign_outlined`, `Icons.map_outlined`, etc.)
- Actions: filled (`Icons.add`, `Icons.edit`, `Icons.delete`, etc.)
- Status: filled with color (`Icons.check_circle`, `Icons.warning`, etc.)

Icon sizes via `AppSpacing.iconXs` (14) through `icon2xl` (48).

## Accessibility

- **Contrast**: All text ≥ 4.5:1 against background (verified per token pair)
- **Touch targets**: Minimum 48px — `AppSpacing.touchTargetMin`
- **Screen reader**: `Semantics` labels on icon-only buttons; `Tooltip` on collapsed sidebar icons
- **Focus**: Visible focus ring using `focusRing` shadow from `AppShadows`
- **Motion**: `@media (prefers-reduced-motion)` — instant transitions as fallback
- **Status indicators**: Always color + text label (never color alone)

## i18n

Primary locale: **Vietnamese (vi)**.
Fallback: **English (en)**.

All user-facing strings in `FE/lib/l10n/app_vi.arb` / `app_en.arb`.
Language toggle in `AppBar` — persists to `SharedPreferences` key `locale`.

Date format: `dd/MM/yyyy` (Vietnamese convention).
Time format: `HH:mm`.
DateTime format: `dd/MM/yyyy HH:mm`.

## Component Status Map

| Component | Status | Notes |
|-----------|--------|-------|
| AppSidebar | ✅ Live | 240/72px, persisted collapse |
| AnalyticsSidebar | ✅ Live | 280/72px, filter state |
| BentoCard / KpiCard | ✅ Live | Dashboard, school list |
| BaseChartCard | ✅ Live | All 6 chart types |
| UserAdminTable | ✅ Live | PaginatedDataTable2, sort/filter |
| ModernBottomSheet | ✅ Live | Map info panels |
| AppShellScaffold | ✅ Live | Sidebar/drawer responsive switch |
| Page transitions | ✅ Live | Custom SlidePageRoute, 300ms |
| Dark mode | ✅ Live | Full theme, verified per surface |
| Shimmer loading | ✅ Live | Global shimmer widget |
| Empty states | ✅ Live | Charts, lists |
| Error states | ✅ Live | Inline + full-page |
| Language toggle | ✅ Live | Persisted to SharedPreferences |
