# UI/UX Refresh Plan - VN Map Campaign Module

**Created:** 2026-06-23
**Updated:** 2026-06-23 22:54
**Style:** Soft Minimalism + Bento Cards + Map Glassmorphism
**Performance Target:** Smooth on low-end devices (2GB RAM, slow network)
**Responsive:** Mobile-first, works on phones, tablets, desktop browsers
**Testing Target:** SonarQube Docker, min 86% coverage (FE + BE)
**Build Target:** Flutter Web + Android APK

---

## 0.5. Map Optimization & Sample Data

### 0.5.1 Map Performance Issues & Solutions

| Issue | Current State | Solution |
|-------|--------------|----------|
| Slow initial load | Loads all tiles + boundaries at once | Progressive loading: show map first, load boundaries async |
| Marker clustering | No clustering | Cluster markers at zoom < 12 |
| Boundary rendering | Full GeoJSON detail | Simplify geometry for web (reduce polygon points) |
| Tile caching | No cache | Cache tiles in memory + localStorage |
| Pan/zoom jank | Frequent rebuilds | Use `FlutterMap` with `TileLayer` options |

### 0.5.2 Map Optimization Implementation

```dart
// 1. Progressive Loading Strategy
class MapPage extends StatefulWidget {
  // Phase 1: Show map tiles immediately
  // Phase 2: Load province boundaries (simplified)
  // Phase 3: Load commune boundaries on zoom (full detail)
}

// 2. Tile Caching
TileLayer(
  options: TileLayerOptions(
    tileProvider: CachedTileProvider(), // Use flutter_map_tile_caching
    maxZoom: 18,
    keepBuffer: 3,
  ),
)

// 3. Marker Clustering
MarkerClusterGroup(
  options: MarkerClusterGroupOptions(
    maxClusterRadius: 50,
    size: Size(40, 40),
    markers: schoolMarkers,
  ),
)

// 4. Lazy Boundary Loading
class BoundaryLoader {
  int currentZoom;
  
  Future<GeoJson> loadBoundaries(Province province) async {
    if (currentZoom < 10) {
      return loadSimplifiedProvinceBoundary(province); // ~500 points
    } else if (currentZoom < 12) {
      return loadDistrictBoundaries(province); // ~2000 points
    }
    return loadFullCommuneBoundaries(province); // Full detail
  }
}
```

### 0.5.3 Sample Data Generation

```dart
// Script to generate realistic sample data
class SampleDataGenerator {
  // Generate 10 campaigns with:
  // - Varied statuses (DRAFT, ACTIVE, DONE)
  // - Different date ranges
  // - Realistic objectives
  
  // Each campaign has:
  // - 5-15 events spread across provinces
  // - Events with varied types (WORKSHOP, SURVEY, PRESENTATION)
  // - Interactions by outcome (SUCCESSFUL, FOLLOW_UP, NO_RESPONSE)
  // - Student registrations with varied statuses
  
  // Schools:
  // - 50 schools across 10 provinces
  // - Mix of exact locations and approximate (commune centroid)
  // - Varied student counts (100-2000)
  
  // Interactions:
  // - 500+ interactions
  // - Realistic distribution: 40% successful, 30% follow-up, 30% no response
  // - Varied channels: PHONE, EMAIL, ZALO, VISIT, EVENT
}
```

### 0.5.4 Sample Data SQL

**CORRECTIONS APPLIED:**
1. Campaign cross-join bug fixed (now exactly 10 campaigns)
2. Schools OR clause fixed (no more duplicate rows)
3. Owner_id random() double-call fixed

```sql
-- ================================================================
-- SAMPLE DATA GENERATION SCRIPT
-- Run this AFTER seeding base data (users, provinces, communes)
-- ================================================================

-- PRE-REQUISITES: Ensure at least 5 users exist for owner_id
-- PRE-REQUISITES: Ensure provinces table is populated

-- ================================================================
-- 1. CAMPAIGNS - Exactly 10 campaigns
-- ================================================================
INSERT INTO campaigns (name, objective, status, start_date, end_date, owner_id)
SELECT
  name,
  objective,
  status,
  start_date,
  end_date,
  -- FIXED: Single random() call, clamped to existing user count
  GREATEST(1, LEAST(
    (SELECT COUNT(*) FROM users),
    (random() * 4 + 1)::int
  )) AS owner_id
FROM (
  VALUES
    ('Chiến dịch Hà Nội Q1', 'Tăng cường nhận diện thương hiệu tại Hà Nội', 'ACTIVE',
     CURRENT_DATE - INTERVAL '30 days', CURRENT_DATE + INTERVAL '60 days'),
    ('Chiến dịch HCM Q2', 'Khảo sát nhu cầu học sinh tại TP.HCM', 'ACTIVE',
     CURRENT_DATE - INTERVAL '45 days', CURRENT_DATE + INTERVAL '45 days'),
    ('Workshop Đà Nẵng', 'Workshop giới thiệu sản phẩm mới tại Đà Nẵng', 'ACTIVE',
     CURRENT_DATE - INTERVAL '15 days', CURRENT_DATE + INTERVAL '30 days'),
    ('Chiến dịch Cần Thơ', 'Quảng bá địa phương tại Cần Thơ', 'ACTIVE',
     CURRENT_DATE - INTERVAL '60 days', CURRENT_DATE + INTERVAL '30 days'),
    ('Chiến dịch Hải Phòng', 'Tăng cường nhận diện tại Hải Phòng', 'DRAFT',
     CURRENT_DATE + INTERVAL '7 days', CURRENT_DATE + INTERVAL '90 days'),
    ('Chiến dịch Quảng Ninh', 'Khảo sát tại Quảng Ninh', 'ACTIVE',
     CURRENT_DATE - INTERVAL '20 days', CURRENT_DATE + INTERVAL '40 days'),
    ('Chiến dịch Thanh Hóa', 'Workshop tại Thanh Hóa', 'DONE',
     CURRENT_DATE - INTERVAL '90 days', CURRENT_DATE - INTERVAL '30 days'),
    ('Chiến dịch Nghệ An', 'Quảng bá tại Nghệ An', 'ACTIVE',
     CURRENT_DATE - INTERVAL '10 days', CURRENT_DATE + INTERVAL '50 days'),
    ('Chiến dịch Hà Tĩnh', 'Tăng cường nhận diện tại Hà Tĩnh', 'DRAFT',
     CURRENT_DATE + INTERVAL '14 days', CURRENT_DATE + INTERVAL '75 days'),
    ('Chiến dịch Khánh Hòa', 'Khảo sát tại Khánh Hòa', 'DONE',
     CURRENT_DATE - INTERVAL '120 days', CURRENT_DATE - INTERVAL '60 days')
) AS campaigns(name, objective, status, start_date, end_date);

-- ================================================================
-- 2. SCHOOLS - 50 schools spread across provinces
-- FIXED: Removed OR clause that caused duplicate rows
-- ================================================================
INSERT INTO schools (school_uid, province_code, commune_code, school_code, school_name, address, area_type, latitude, longitude, geocode_status)
WITH province_list AS (
  SELECT code, province_name, latitude, longitude FROM provinces
),
school_provinces AS (
  -- Assign each school to a province (cyclic: 1-63, repeat)
  SELECT gs, code, province_name, latitude, longitude,
         ROW_NUMBER() OVER (PARTITION BY gs) AS rn
  FROM generate_series(1, 50) AS gs
  JOIN province_list ON code::int = (gs % 63) + 1
)
SELECT
  'SCH' || LPAD(gs::text, 4, '0') AS school_uid,
  code AS province_code,
  NULL AS commune_code,  -- Will be NULL for sample data
  'SCH' || LPAD((gs + 100)::text, 3, '0') AS school_code,
  'Trường THPT ' || province_name || ' ' || gs AS school_name,
  province_name || ', Việt Nam' AS address,
  CASE
    WHEN code IN ('01', '79', '48') THEN 'KV1'
    WHEN code IN ('02', '03', '04') THEN 'KV2'
    ELSE 'KV3'
  END AS area_type,
  -- Approximate location (province centroid + small random offset)
  latitude + (random() - 0.5) * 0.3 AS latitude,
  longitude + (random() - 0.5) * 0.3 AS longitude,
  'APPROXIMATE' AS geocode_status
FROM school_provinces
WHERE rn = 1  -- Deduplicate any accidental duplicates
LIMIT 50;

-- ================================================================
-- 3. EVENTS - ~100 events spread across campaigns
-- FIXED: Deterministic event count per campaign (not random per row)
-- ================================================================
WITH campaign_list AS (
  SELECT id, name, start_date, end_date FROM campaigns LIMIT 10
),
event_counts AS (
  -- Fixed: 5-10 events per campaign (deterministic based on campaign id)
  SELECT id, name, start_date, end_date,
         5 + (id % 6) AS num_events
  FROM campaign_list
),
event_series AS (
  SELECT
    c.id AS campaign_id,
    c.name || ' - ' || unnest(ARRAY['WORKSHOP', 'SURVEY', 'PRESENTATION', 'MEETING']) AS event_name,
    unnest(ARRAY['WORKSHOP', 'SURVEY', 'PRESENTATION', 'MEETING']) AS event_type,
    c.start_date + (gs * ((c.end_date - c.start_date)::int / NULLIF(c.num_events, 0))) AS event_date,
    p.code AS province_code,
    p.province_name
  FROM event_counts c
  CROSS JOIN LATERAL generate_series(1, c.num_events) AS gs
  LEFT JOIN province_list p ON p.code::int = (c.id % 63) + 1
)
INSERT INTO campaign_events (campaign_id, name, event_type, status, event_date, location_label, province_code)
SELECT
  campaign_id,
  event_name,
  event_type,
  CASE WHEN event_date < CURRENT_DATE THEN 'COMPLETED' ELSE 'UPCOMING' END,
  event_date,
  'Tại ' || province_name,
  province_code
FROM event_series
LIMIT 100;

-- ================================================================
-- 4. INTERACTIONS - 500+ interactions
-- ================================================================
INSERT INTO interactions (event_id, school_uid, participant_type, participant_id, channel, outcome, notes, created_at)
SELECT
  e.id,
  s.school_uid,
  CASE (random() * 2)::int
    WHEN 0 THEN 'STUDENT'
    WHEN 1 THEN 'PARENT'
    ELSE 'TEACHER'
  END,
  (random() * 1000)::int + 1,
  (ARRAY['PHONE', 'EMAIL', 'ZALO', 'VISIT', 'EVENT'])[1 + (random() * 4)::int],
  CASE
    WHEN random() < 0.4 THEN 'SUCCESSFUL'
    WHEN random() < 0.7 THEN 'FOLLOW_UP'
    ELSE 'NO_RESPONSE'
  END,
  'Interaction notes for testing',
  CURRENT_TIMESTAMP - (random() * 90)::int * INTERVAL '1 day'
FROM campaign_events e
CROSS JOIN LATERAL (
  SELECT school_uid FROM schools
  WHERE province_code = e.province_code
  LIMIT 1
) s
CROSS JOIN LATERAL generate_series(1, 1 + (random() * 4)::int) AS gs(n)
WHERE e.status = 'COMPLETED'
LIMIT 500;

-- ================================================================
-- 5. STUDENT REGISTRATIONS
-- ================================================================
INSERT INTO campaign_student_registrations (campaign_id, student_id, school_uid, registration_date, status)
SELECT
  c.id,
  gs AS student_id,
  s.school_uid,
  c.start_date + (random() * (c.end_date - c.start_date))::int,
  (ARRAY['REGISTERED', 'ATTENDED', 'CANCELLED', 'PENDING'])[1 + (random() * 3)::int]
FROM campaigns c
CROSS JOIN LATERAL generate_series(1, 1 + (random() * 20)::int) AS gs
CROSS JOIN LATERAL (
  SELECT school_uid FROM schools LIMIT 1
) s
WHERE c.id <= 10
LIMIT 200;
```

### 0.5.5 Map Responsive Behavior

```dart
// Responsive Map Layout
class ResponsiveMapLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Mobile: Full screen map with bottom sheet
        if (constraints.maxWidth < 600) {
          return _MobileMapLayout();
        }
        // Tablet: Map with side drawer
        if (constraints.maxWidth < 1024) {
          return _TabletMapLayout();
        }
        // Desktop: Map with persistent sidebar
        return _DesktopMapLayout();
      },
    );
  }
}

// Mobile: Stack with DraggableBottomSheet
class _MobileMapLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        VietnamMapView(),
        DraggableScrollableSheet(
          initialChildSize: 0.3,
          minChildSize: 0.15,
          maxChildSize: 0.85,
          builder: (_, scrollController) => _BottomSheet(scrollController),
        ),
      ],
    );
  }
}

// Desktop: Side-by-side with legend
class _DesktopMapLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 2, child: VietnamMapView()),
        Container(
          width: 320,
          child: GlassSidebar(
            isExpanded: true,
            child: _SchoolList(),
          ),
        ),
      ],
    );
  }
}
```

---

## 1. Design System (Design Tokens)

### 1.1 Color Palette

| Token | Light Mode | Dark Mode | Usage |
|-------|------------|-----------|-------|
| `--bg-primary` | `#F8FAFC` | `#0A0A0F` | Main background |
| `--bg-surface` | `#FFFFFF` | `#18181B` | Cards, sheets |
| `--bg-elevated` | `#F1F5F9` | `#27272A` | Hover states |
| `--text-primary` | `#0F172A` | `#FAFAFA` | Headings |
| `--text-secondary` | `#475569` | `#A1A1AA` | Body text |
| `--text-muted` | `#94A3B8` | `#71717A` | Hints |
| `--border-subtle` | `#E2E8F0` | `#3F3F46` | Card borders |
| `--border-focus` | `#B91C1C` | `#EF4444` | Focus rings |
| `--primary` | `#B91C1C` | `#EF4444` | Primary actions |
| `--primary-hover` | `#991B1B` | `#DC2626` | Hover |
| `--secondary` | `#D97706` | `#FB923C` | Secondary |
| `--accent` | `#F59E0B` | `#FBBF24` | Highlights |

### 1.2 Spacing Scale

```dart
// 4px base unit
static const space1 = 4.0;
static const space2 = 8.0;
static const space3 = 12.0;
static const space4 = 16.0;
static const space5 = 20.0;
static const space6 = 24.0;
static const space8 = 32.0;
static const space10 = 40.0;
static const space12 = 48.0;
static const space16 = 64.0;
```

### 1.3 Border Radius

```dart
static const radiusSm = 8.0;   // Buttons, inputs
static const radiusMd = 12.0;  // Cards
static const radiusLg = 16.0; // Modals, sheets
static const radiusXl = 24.0;  // Large containers
```

### 1.4 Shadows

```dart
// Light mode
static const shadowSm = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 4,
  offset: Offset(0, 1),
);
static const shadowMd = BoxShadow(
  color: Color(0x14000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);
static const shadowLg = BoxShadow(
  color: Color(0x1F000000),
  blurRadius: 16,
  offset: Offset(0, 4),
);

// Dark mode (subtle, less spread)
static const shadowDarkSm = BoxShadow(
  color: Color(0x40000000),
  blurRadius: 2,
  offset: Offset(0, 1),
);
```

### 1.5 Typography

```dart
// Scale
displayLarge: 32px / 700 / -0.5px
headlineMedium: 24px / 600 / -0.25px
titleLarge: 20px / 600 / 0
titleMedium: 16px / 600 / 0.15px
bodyLarge: 16px / 400 / 0.5px
bodyMedium: 14px / 400 / 0.25px
labelLarge: 14px / 500 / 0.1px
labelMedium: 12px / 500 / 0.5px
```

---

## 2. Component Library

### 2.1 Bento Card System

```dart
// Core bento card variants
class BentoCard extends StatelessWidget {
  final BentoCardSize size; // sm, md, lg, xl, wide
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;
}

// Size definitions
enum BentoCardSize {
  sm,   // 1x1 grid unit (e.g., 150x100)
  md,   // 1x2 grid unit
  lg,   // 2x2 grid unit
  xl,   // 2x3 grid unit
  wide, // Full width
}
```

**Dashboard Layout Example:**
```
┌───────┬───────┬───────┐
│  KPI  │  KPI  │  KPI  │  <- 3x sm cards
├───────┴───────┼───────┤
│   Donut Chart │ Bar   │  <- lg + sm
├───────────────┴───────┤
│     Table / List       │  <- wide
└───────────────────────┘
```

### 2.2 Modern Bottom Sheet

```dart
class ModernBottomSheet extends StatelessWidget {
  final double initialChildSize; // 0.25 (collapsed) or 0.4 (expanded)
  final double minChildSize;
  final double maxChildSize;
  final Widget? header; // Handle + title
  final Widget child;
}
```

**Features:**
- Rounded top corners (24px)
- Subtle backdrop blur (glassmorphism)
- Smooth drag animation
- Snap points at 0.25, 0.5, 0.9

### 2.3 Glassmorphism Sidebar

```dart
class GlassSidebar extends StatelessWidget {
  final bool isExpanded;
  final Widget child;
  // Frosted glass effect: backdrop-filter blur 20px
  // Background: white/dark with 80% opacity
}
```

### 2.4 Status Chips

```dart
class StatusChip extends StatelessWidget {
  final String label;
  final StatusType type; // success, warning, error, info, neutral
}
```

### 2.5 Shimmer Skeleton

```dart
class ShimmerBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius? borderRadius;
}

class ShimmerCard extends StatelessWidget {
  // Pre-built skeleton for cards
}
```

---

## 3. Map UI Components

### 3.1 Map Tile Switcher

```dart
// Automatic light/dark tile switching
class MapTileProvider {
  bool isDarkMode;
  
  String get tileUrl => isDarkMode
    ? 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png'
    : 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png';
}
```

### 3.2 School Marker

```dart
class SchoolMarker extends StatelessWidget {
  final SchoolMarkerStatus status; // active, pending, approximate
  final bool isSelected;
  final VoidCallback onTap;
}

// Visual: 12px circle, pulsing animation for selected
// Colors: Primary (active), Warning (pending), Muted (approximate)
```

### 3.3 Map Controls

```dart
class MapControls extends StatelessWidget {
  // Positioned based on screen size
  // Mobile: bottom-right, floating pill
  // Desktop: top-right, vertical stack
  
  // Buttons: zoom in/out, locate me, toggle layers
  // Glassmorphism container with backdrop blur
}
```

### 3.4 Responsive Breakpoints

```dart
// Standard breakpoints
static const double breakpointMobile = 600;
static const double breakpointTablet = 900;
static const double breakpointDesktop = 1200;

// Responsive helpers
class Responsive {
  static bool isMobile(BuildContext context) => 
    MediaQuery.of(context).size.width < breakpointMobile;
  
  static bool isTablet(BuildContext context) =>
    MediaQuery.of(context).size.width >= breakpointMobile &&
    MediaQuery.of(context).size.width < breakpointDesktop;
  
  static bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= breakpointDesktop;
  
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }
}
```

### 3.5 Responsive Component Examples

```dart
// Responsive Padding
EdgeInsets responsivePadding(BuildContext context) {
  return EdgeInsets.all(Responsive.value(
    context,
    mobile: 12,
    tablet: 16,
    desktop: 24,
  ));
}

// Responsive Grid
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= breakpointDesktop) {
      return Row(
        children: children.map((child) => Expanded(child: child)).toList(),
      );
    }
    
    if (width >= breakpointMobile) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: children,
      );
    }
    
    return Column(children: children);
  }
}

// Responsive Navigation
class ResponsiveNav extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (Responsive.isDesktop(context)) {
      return NavigationRail(...); // Left side rail
    }
    if (Responsive.isTablet(context)) {
      return NavigationDrawer(...); // Drawer
    }
    return NavigationBar(...); // Bottom bar (mobile)
  }
}
```

---

## 4. Performance Optimizations

### 4.1 Widget Optimization

```dart
// 1. Const constructors everywhere possible
// 2. RepaintBoundary for expensive widgets
// 3. Slivers for long lists
// 4. ListView.builder for lists
// 5. Selective rebuilds with Consumer/Selector

// Example:
RepaintBoundary(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxHeight: 300),
    child: ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) => ItemCard(item: items[index]),
    ),
  ),
)
```

### 4.2 Image/Cache Optimization

```dart
// 1. Use cached_network_image for images
// 2. Pre-cache critical images
// 3. Lazy load non-critical assets
// 4. Use memory cache for API responses (Riverpod)

class MapMarkerCache {
  static final Map<String, Widget> _cache = {};
  
  static Widget getMarker(String id, SchoolMarkerStatus status) {
    return _cache.putIfAbsent('$id-$status', () => _buildMarker(status));
  }
}
```

### 4.3 API Optimization

```dart
// 1. Debounce search inputs (300-500ms)
// 2. Pagination for large lists (20 items/page)
// 3. Batch requests where possible
// 4. Cache responses with TTL

// Search debounce example:
final searchQueryProvider = StateProvider<String>((ref) => '');

final debouncedSearchProvider = debounceProvider(
  searchQueryProvider,
  const Duration(milliseconds: 300),
);

// Pagination example:
class PaginatedListNotifier<T> extends StateNotifier<PaginatedState<T>> {
  Future<void> loadMore() async {
    if (state.hasMore && !state.isLoading) {
      // Load next page
    }
  }
}
```

### 4.4 Map Performance

```dart
// 1. Lazy load boundaries by zoom level
// 2. Simplify GeoJSON for web (reduce points)
// 3. Use FlutterMapTileUpdater for efficient updates
// 4. Cluster markers at low zoom levels
// 5. Cancel previous tile requests on zoom change

class BoundaryLoader {
  int currentZoom;
  
  Future<GeoJson> loadBoundaries(Province province) async {
    // Only load communes at zoom >= 10
    if (currentZoom < 10) {
      return loadProvinceBoundary(province);
    }
    return loadCommuneBoundaries(province);
  }
}
```

### 4.5 Animation Optimization

```dart
// 1. Use Curves.easeOutCubic for snappy feel
// 2. 150-300ms for micro-interactions
// 3. 300-500ms for page transitions
// 4. Avoid expensive animations (blur, complex shadows)
// 5. Use AnimatedOpacity/AnimatedContainer instead of Opacity/TweenAnimationBuilder

const kAnimationFast = Duration(milliseconds: 150);
const kAnimationNormal = Duration(milliseconds: 250);
const kAnimationSlow = Duration(milliseconds: 350);

const kCurveSnappy = Curves.easeOutCubic;
const kCurveSmooth = Curves.easeInOut;
```

---

## 5. Implementation Phases (Consolidated)

### Canonical Phase Reference

**All implementation phases are defined in Section 16 (Implementation Phases with BE Testing).**

Quick summary:

| Phase | Name | Key Deliverables |
|-------|------|-----------------|
| 0 | Pre-Implementation Setup | Env verification, SonarQube setup, baseline |
| 1 | Design System Foundation | Theme tokens, responsive helpers |
| 2 | Bento Card Components | BentoCard, ShimmerCard |
| 3 | Map Optimization & Sample Data | Progressive loading, clustering |
| 4 | Map Glassmorphism UI | GlassSidebar, ModernBottomSheet |
| 5 | Responsive Design & Polish | All breakpoints tested |
| 6 | Final Verification & Release | 86% coverage, APK <30MB |

See **Section 16** for detailed checklists per phase.

---

## 6. File Structure

```
FE/lib/
├── core/
│   ├── theme/
│   │   ├── app_theme.dart          # Main theme builder
│   │   ├── app_colors.dart         # Color tokens
│   │   ├── app_spacing.dart       # Spacing scale
│   │   ├── app_typography.dart     # Text styles
│   │   └── app_shadows.dart       # Shadow definitions
│   ├── utils/
│   │   └── responsive.dart         # Responsive breakpoint helpers
│   └── widgets/
│       ├── bento_card.dart         # Bento grid card
│       ├── shimmer_loading.dart     # Skeleton loaders
│       ├── modern_bottom_sheet.dart # Glass sheet
│       ├── glass_sidebar.dart      # Map sidebar
│       ├── status_chip.dart        # Status badges
│       └── responsive_grid.dart     # Responsive layout helpers
└── features/
    ├── map/
    │   └── presentation/
    │       ├── providers/
    │       │   └── map_optimization_provider.dart
    │       └── widgets/
    │           ├── school_marker.dart
    │           ├── map_controls.dart
    │           ├── map_tile_provider.dart
    │           ├── marker_cluster.dart
    │           └── responsive_map_layout.dart
    └── campaign/
        └── dashboard/
            └── pages/
                └── campaign_dashboard_page.dart  # Updated
```

---

## 7. Responsive Design Patterns

### 7.1 Screen Size Reference

| Breakpoint | Width | Devices |
|------------|-------|---------|
| Mobile | < 600px | iPhone, Android phones |
| Tablet | 600-899px | iPad, small tablets |
| Tablet Landscape | 900-1199px | iPad landscape |
| Desktop | ≥ 1200px | Laptops, desktops |

### 7.2 Component Responsiveness

| Component | Mobile | Tablet | Desktop |
|-----------|--------|--------|---------|
| Navigation | Bottom bar | Drawer/NavigationRail | NavigationRail + sidebar |
| Map | Full screen + bottom sheet | Split view | Side-by-side |
| Cards | 1 column | 2-3 columns | 4+ columns |
| Forms | Full width | 2 columns | Inline labels |
| Tables | Card list | Compact table | Full table |
| FAB | Bottom right | Bottom right | Bottom right (offset) |
| AppBar | Title + actions | Title + actions + search | Title + search + user menu |

---

## 8. Performance Targets & Estimated Impact

**NOTE:** These are aspirational targets, NOT committed deliverables. No baseline profiling has been done yet. Measure before and after implementation to verify actual improvements.

| Metric | Baseline (TBD) | Target | Measurement Method |
|--------|-----------------|--------|-------------------|
| First paint | Measure via DevTools | Improve by 20-30% | Lighthouse, DevTools |
| Interactive | Measure via DevTools | Improve by 20-30% | Lighthouse |
| Frame rate (scroll) | Measure via DevTools | Maintain 60fps | Flutter DevTools |
| Memory usage | Measure via DevTools | Reduce by 15-20% | DevTools memory profiler |
| Bundle size | Current size (measure) | Minimize growth | `flutter build --analyze-size` |
| Map load time | Measure in production | Improve by 30-50% | Manual + DevTools network |

**Measurement Commands:**
```bash
# Measure current performance baseline FIRST
# Then implement changes
# Then measure again to verify improvement

# Flutter DevTools
flutter run --observe

# Lighthouse (Web)
# chrome://inspect → Performance tab

# APK size
flutter build apk --release --analyze-size

# Memory profiling
flutter run --enable-asserts
# Use DevTools memory tab
```

---

## 9. Responsive Testing Checklist

### Mobile (< 600px)
- [ ] Bottom navigation works
- [ ] Cards stack vertically
- [ ] Bottom sheet drag works
- [ ] Map full screen with controls
- [ ] Forms are full width
- [ ] Tables show as card list

### Tablet (600-899px)
- [ ] Navigation drawer or rail
- [ ] 2-column grid for cards
- [ ] Split view for map
- [ ] Forms have adequate spacing
- [ ] Tables are scrollable

### Desktop (≥ 1200px)
- [ ] Navigation rail visible
- [ ] 4+ column grid
- [ ] Map with persistent sidebar
- [ ] Inline form labels
- [ ] Full table view
- [ ] Hover states work

### Cross-browser
- [ ] Chrome (desktop & mobile)
- [ ] Safari (iOS)
- [ ] Firefox
- [ ] Edge

---

## 10. Android APK Build & Mobile App Optimization

### 10.1 Android Build Configuration

**CORRECTION:** Android configuration belongs in `android/app/build.gradle`, NOT `pubspec.yaml`.

```groovy
// android/app/build.gradle (NOT pubspec.yaml)

android {
    namespace "com.vnmap.campaign"
    compileSdk 34

    defaultConfig {
        applicationId "com.vnmap.campaign"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }

    buildTypes {
        release {
            signingConfig signingConfigs.debug  // Replace with release config in production
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            debuggable true
        }
    }

    // Release signing (for production)
    signingConfigs {
        release {
            keyAlias System.getenv('KEY_ALIAS') ?: 'vnmaptest'
            keyPassword System.getenv('KEY_PASSWORD') ?: 'changeit'
            storePassword System.getenv('STORE_PASSWORD') ?: 'changeit'
            storeFile file(System.getenv('KEYSTORE_PATH') ?: 'keystore.jks')
        }
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### 10.2 Release Build Configuration

**IMPORTANT:** The release build MUST use `signingConfigs.release`, not `signingConfigs.debug`.

```groovy
// android/app/build.gradle - Complete configuration

android {
    namespace "com.vnmap.campaign"
    compileSdk 34

    defaultConfig {
        applicationId "com.vnmap.campaign"
        minSdk 21
        targetSdk 34
        versionCode 1
        versionName "1.0.0"
        multiDexEnabled true
    }

    signingConfigs {
        release {
            // PRODUCTION: Use environment variables
            // CI/CD: Set via secrets
            // Local: Use local keystore
            keyAlias System.getenv('KEY_ALIAS') ?: 'vnmaptest'
            keyPassword System.getenv('KEY_PASSWORD') ?: 'changeit'
            storePassword System.getenv('STORE_PASSWORD') ?: 'changeit'
            storeFile file(System.getenv('KEYSTORE_PATH') ?: 'keystore.jks')
        }
    }

    buildTypes {
        release {
            // CORRECT: Use signingConfigs.release (not debug!)
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            signingConfig signingConfigs.debug
            debuggable true
        }
    }
}
```

**For Play Store deployment, you MUST:**
1. Generate a production keystore (`keytool -genkeypair`)
2. Store credentials securely (GitHub Secrets, etc.)
3. Replace placeholder values with real credentials

```yaml
# pubspec.yaml - Flutter config only
flutter:
  sdk: flutter
  # No Android-specific config here - that's build.gradle
```

### 10.2 Build Commands

```bash
# Build Android APK (debug)
cd FE
flutter build apk --debug

# Build Android APK (release)
flutter build apk --release

# Build Android App Bundle (for Play Store)
flutter build appbundle --release

# Build for specific ABI (smaller size)
flutter build apk --release --target-platform android-arm64

# Build for multiple ABIs
flutter build apk --release --target-platform android-arm,android-arm64,android-x64
```

### 10.3 Mobile Performance Targets

| Metric | Target | Command |
|--------|--------|---------|
| APK Size | <30MB (release) | `flutter build apk --release` |
| Startup | <2s | Use `--analyze-size` |
| Frame Rate | 60fps | Profile in DevTools |

### 10.4 Mobile Performance Commands

```bash
# Analyze APK size
flutter build apk --release --analyze-size

# Build with debug info for profiling
flutter build apk --debug --split-debug-info=build/debug-info

# Profile on device
flutter attach --device-id=<device_id>
```

---

## 11. Testing Strategy (FE + BE)

### 11.1 Test Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                    TESTING PYRAMID                               │
│              (Test Type Distribution)                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                        ▲ E2E Tests (5%)                         │
│                       /──────────────\                          │
│                      /  Integration     \                       │
│                     /     Tests (15%)     \                      │
│                    /───────────────────────\                    │
│                   /     Component Tests      \                   │
│                  /        (20%)               \                 │
│                 /─────────────────────────────────\             │
│                /       Unit Tests (60%)            \            │
│               /─────────────────────────────────────────\        │
│                                                                  │
│                   TOTAL: 100% of test effort                   │
└─────────────────────────────────────────────────────────────────┘

Coverage Target: 86% minimum (combined FE + BE)
└── Per-project targets: FE ≥ 43%, BE ≥ 43%
```

**Clarification:** The pyramid shows **test effort distribution** (what types of tests to write).
The coverage table shows **contribution to the 86% combined coverage target** (what percentage each type contributes to the final coverage metric).

### 11.2 Frontend Test Structure (Dart)

```dart
// FE/test/

// 1. Unit Tests - Core business logic
test/
├── core/
│   ├── utils/
│   │   ├── responsive_test.dart              // Breakpoint helpers
│   │   ├── date_formatter_test.dart          // Date/time formatting
│   │   ├── debouncer_test.dart               // Input debouncing
│   │   ├── validators_test.dart               // Form validation
│   │   └── constants_test.dart                // App constants
│   ├── network/
│   │   ├── api_response_test.dart             // Response parsing
│   │   ├── api_exception_test.dart            // Error handling
│   │   └── failure_mapper_test.dart           // Error mapping
│   └── providers/
│       ├── theme_provider_test.dart           // Theme state
│       └── locale_provider_test.dart          // i18n state
├── features/
│   ├── auth/
│   │   ├── auth_provider_test.dart           // Auth state management
│   │   ├── auth_repository_test.dart         // Login/logout logic
│   │   └── auth_model_test.dart              // Model parsing
│   ├── campaign/
│   │   ├── campaign_provider_test.dart       // Campaign state
│   │   ├── campaign_repository_test.dart     // API calls
│   │   ├── campaign_model_test.dart           // Model parsing
│   │   ├── campaign_list_provider_test.dart  // List state
│   │   └── campaign_filter_test.dart          // Filtering logic
│   ├── events/
│   │   ├── event_provider_test.dart          // Event state
│   │   ├── event_model_test.dart            // Model parsing
│   │   └── event_form_validation_test.dart   // Form validation
│   ├── map/
│   │   ├── map_provider_test.dart           // Map state
│   │   ├── boundary_loader_test.dart         // GeoJSON loading
│   │   ├── school_marker_test.dart            // Marker logic
│   │   └── map_tile_provider_test.dart        // Tile switching
│   ├── school/
│   │   ├── school_provider_test.dart         // School state
│   │   ├── school_model_test.dart            // Model parsing
│   │   └── school_filter_test.dart           // Filtering logic
│   ├── weather/
│   │   ├── weather_provider_test.dart        // Weather state
│   │   └── weather_model_test.dart           // Model parsing
│   └── admin/
│       ├── admin_provider_test.dart          // Admin state
│       └── user_model_test.dart              // User model
├── widgets/                                   // Widget tests (separate)
└── integration_test/                           // Integration tests (separate)

// 2. Widget Tests - UI components
test/widgets/
├── bento_card_test.dart                      // Bento card rendering
├── shimmer_loading_test.dart                  // Loading animations
├── status_chip_test.dart                      // Status badge display
├── modern_bottom_sheet_test.dart              // Drag gesture
├── glass_sidebar_test.dart                    // Glassmorphism effect
├── responsive_grid_test.dart                  // Responsive layout
├── app_error_widget_test.dart                 // Error display
├── loading_widget_test.dart                   // Loading states
└── campaign_card_test.dart                    // Campaign card UI

// 3. Integration Tests - User flows
integration_test/
├── app_test.dart                             // App initialization
├── login_flow_test.dart                       // Login → redirect
├── campaign_flow_test.dart                    // Full campaign CRUD
├── map_interaction_test.dart                  // Map zoom/pan/markers
└── theme_switch_test.dart                     // Light/dark toggle
```

### 11.3 Backend Test Structure (Java)

```java
// BE/src/test/java/com/vnmap/campaign/

// 1. Unit Tests - Service layer
src/test/java/com/vnmap/campaign/
├── service/
│   ├── CampaignServiceTest.java               // Campaign CRUD + logic
│   ├── EventServiceTest.java                  // Event management
│   ├── SchoolServiceTest.java                 // School operations
│   ├── UserServiceTest.java                   // User management
│   ├── AuthServiceTest.java                   // Authentication
│   ├── InteractionServiceTest.java            // Interaction handling
│   ├── StudentServiceTest.java                // Student operations
│   ├── GeocodingServiceTest.java              // Geocoding logic
│   └── DashboardServiceTest.java              // Dashboard aggregation
├── repository/
│   ├── CampaignRepositoryTest.java            // Query methods
│   ├── EventRepositoryTest.java               // Event queries
│   ├── SchoolRepositoryTest.java               // School queries
│   ├── UserRepositoryTest.java                 // User queries
│   └── InteractionRepositoryTest.java         // Interaction queries
├── controller/
│   ├── CampaignControllerTest.java            // REST endpoints
│   ├── EventControllerTest.java               // Event REST
│   ├── SchoolControllerTest.java               // School REST
│   ├── AuthControllerTest.java                 // Auth REST
│   ├── UserControllerTest.java                 // User REST
│   └── DashboardControllerTest.java           // Dashboard REST
├── dto/
│   ├── CampaignDtoTest.java                   // DTO validation
│   ├── EventDtoTest.java                      // DTO validation
│   ├── SchoolDtoTest.java                     // DTO validation
│   └── DashboardDtoTest.java                  // DTO validation
└── util/
    ├── DateUtilsTest.java                     // Date formatting
    └── GeoUtilsTest.java                      // Geo calculations

// 2. Integration Tests - Full flow
src/test/java/com/vnmap/campaign/
├── integration/
│   ├── CampaignIntegrationTest.java          // Full campaign flow
│   ├── EventIntegrationTest.java             // Event lifecycle
│   ├── SchoolIntegrationTest.java            // School management
│   ├── AuthIntegrationTest.java              // Login flow
│   └── DashboardIntegrationTest.java         // Dashboard data
└── e2e/
    └── CampaignE2ETest.java                  // End-to-end scenarios

// 3. Database Tests (Testcontainers)
src/test/java/com/vnmap/campaign/
├── database/
│   ├── BaseIntegrationTest.java              // Testcontainer setup
│   ├── CampaignRepositoryIT.java            // DB queries
│   └── SchoolRepositoryIT.java               // School queries
└── fixtures/
    ├── CampaignFixtures.java                 // Test data builder
    ├── EventFixtures.java                   // Event test data
    └── SchoolFixtures.java                   // School test data
```

### 11.4 Coverage Targets (Realistic)

**NOTE:** 86% coverage is ambitious for a map-heavy Flutter UI. Glassmorphism, animations, and gesture-heavy widgets are the hardest/lowest-value things to test. Focus testing effort on business logic.

| Type | Frontend | Backend | Combined | Notes |
|------|----------|---------|----------|-------|
| Unit Tests (Business Logic) | 25% | 40% | 65% | **Priority:** Campaign/Event/Services |
| Unit Tests (Utils) | 10% | 10% | 20% | Formatters, validators |
| Integration Tests (API) | 5% | 8% | 13% | Controller/repository tests |
| Widget Tests (Critical UI) | 5% | - | 5% | Only complex widgets: forms, dialogs |
| Widget Tests (Skip) | 0% | - | 0% | **Skip:** Animations, gestures, map |
| E2E Tests | 3% | 4% | 7% | Critical user flows only |
| **Total** | **43%** | **43%** | **86%** | |

**Rationale:**
- Widget tests for animations/gestures have ~10% value but take 90% of effort
- Focus on testing business logic: CampaignService, EventService, AuthService
- Skip testing Flutter Map widget, shimmer animations, bottom sheet gestures
- These can be verified manually or via screenshot tests if needed

**If 86% is not achievable:**
- Minimum acceptable: **75%** (with documented exclusions)
- Exclude UI-heavy files from coverage: map widgets, animations, shimmer

**IMPORTANT: Quality Gate Reconciliation**

The SonarQube quality gate MUST match the actual target. The plan supports two paths:

| Path | Quality Gate Threshold | When to Use |
|------|----------------------|-------------|
| **Ideal** | Coverage < 86% → ERROR | All phases complete, UI code excluded |
| **Fallback** | Coverage < 75% → ERROR | 86% not achievable, exclusions documented |

**Implementation:** Use the IDEAL path first. If 86% is not achievable after all business logic is tested:
1. Document exclusions in SonarQube
2. Update quality gate threshold to 75%
3. Record decision in `progress.md`

### 11.5 Coverage Exclusions (Documented)

```properties
# SonarQube exclusions for UI-heavy code
sonar.exclusions=\
  **/*_animation.dart,\
  **/shimmer_*.dart,\
  **/glass_*.dart,\
  **/bento_card.dart,\
  **/map/**/*_view.dart
```

### 11.6 Test Naming Conventions

```dart
// Frontend (Dart) - BDD style
group('CampaignProvider', () {
  test('should load campaigns when initialized', () async {
    // Arrange
    final container = createContainer(overrides: [...]);

    // Act
    await container.read(campaignProvider.future);

    // Assert
    expect(container.read(campaignProvider).value, isNotNull);
  });

  test('should filter campaigns by status', () async {
    // Arrange
    final campaigns = [draftCampaign, activeCampaign, doneCampaign];

    // Act
    final filtered = filterByStatus(campaigns, 'ACTIVE');

    // Assert
    expect(filtered.length, 1);
    expect(filtered.first.status, 'ACTIVE');
  });

  test('should throw exception when API fails', () async {
    // Arrange
    final mockClient = MockHttpClient();

    // Act & Assert
    expect(
      () => fetchCampaigns(mockClient),
      throwsA(isA<ApiException>()),
    );
  });
});
```

```java
// Backend (Java) - JUnit 5
@DisplayName("Campaign Service Tests")
class CampaignServiceTest {

    @Nested
    @DisplayName("createCampaign")
    class CreateCampaignTests {

        @Test
        @DisplayName("should create campaign with valid data")
        void shouldCreateCampaignWithValidData() {
            // Given
            CreateCampaignRequest request = CampaignFixtures.validRequest();

            // When
            Campaign result = campaignService.createCampaign(request);

            // Then
            assertThat(result.getId()).isNotNull();
            assertThat(result.getName()).isEqualTo(request.getName());
            assertThat(result.getStatus()).isEqualTo("DRAFT");
        }

        @Test
        @DisplayName("should throw exception when name is blank")
        void shouldThrowExceptionWhenNameIsBlank() {
            // Given
            CreateCampaignRequest request = CampaignFixtures.blankNameRequest();

            // When/Then
            assertThatThrownBy(() -> campaignService.createCampaign(request))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("name");
        }
    }
}
```

### 11.6 Test Data Fixtures

```dart
// FE/test/fixtures/

class CampaignFixtures {
  static CampaignModel draftCampaign() => CampaignModel(
    id: 1,
    name: 'Chiến dịch Test',
    status: 'DRAFT',
    startDate: DateTime(2026, 1, 1),
    endDate: DateTime(2026, 12, 31),
  );

  static CampaignModel activeCampaign() => CampaignModel(
    id: 2,
    name: 'Chiến dịch Active',
    status: 'ACTIVE',
    startDate: DateTime.now().subtract(Duration(days: 30)),
    endDate: DateTime.now().add(Duration(days: 60)),
  );

  static List<CampaignModel> campaignList() => [
    draftCampaign(),
    activeCampaign(),
    CampaignModel(
      id: 3,
      name: 'Chiến dịch Done',
      status: 'DONE',
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 12, 31),
    ),
  ];
}

class SchoolFixtures {
  static SchoolModel hanoiSchool() => SchoolModel(
    uid: 'SCH001',
    name: 'Trường THPT Hà Nội',
    provinceCode: '01',
    provinceName: 'Hà Nội',
    latitude: 21.0285,
    longitude: 105.8542,
    hasExactLocation: true,
  );

  static SchoolModel approxSchool() => SchoolModel(
    uid: 'SCH002',
    name: 'Trường THPT Sơn La',
    provinceCode: '05',
    provinceName: 'Sơn La',
    latitude: 21.2756, // Commune centroid
    longitude: 103.8593,
    hasExactLocation: false,
  );
}
```

```java
// BE/src/test/java/com/vnmap/campaign/fixtures/

public class CampaignFixtures {

    public static CreateCampaignRequest validRequest() {
        return CreateCampaignRequest.builder()
            .name("Chiến dịch Test")
            .objective("Mục tiêu test")
            .status("DRAFT")
            .startDate(LocalDate.now())
            .endDate(LocalDate.now().plusMonths(6))
            .ownerId(1L)
            .build();
    }

    public static Campaign draftCampaign() {
        Campaign campaign = new Campaign();
        campaign.setId(1L);
        campaign.setName("Chiến dịch Draft");
        campaign.setStatus("DRAFT");
        campaign.setStartDate(LocalDate.now());
        campaign.setEndDate(LocalDate.now().plusMonths(6));
        return campaign;
    }
}
```

### 11.7 Mocking Strategies

```dart
// Frontend - Mocking HTTP client
class MockCampaignRepository implements CampaignRepository {
  final List<CampaignModel> _campaigns;
  final bool shouldFail;

  MockCampaignRepository({
    List<CampaignModel>? campaigns,
    this.shouldFail = false,
  }) : _campaigns = campaigns ?? [];

  @override
  Future<List<CampaignModel>> getCampaigns({
    String? status,
    String? search,
  }) async {
    if (shouldFail) throw ApiException('Network error');
    await Future.delayed(Duration.zero); // Sync to async
    return _campaigns;
  }
}

// Usage in tests
test('should show error when fetch fails', () async {
  final container = createContainer(
    overrides: [
      campaignRepositoryProvider.overrideWith(
        () => MockCampaignRepository(shouldFail: true),
      ),
    ],
  );

  await container.read(fetchCampaignsProvider('ACTIVE').future);

  expect(
    container.read(campaignsProvider).value,
    isA<AsyncError>(),
  );
});
```

```java
// Backend - Mocking with Mockito
@ExtendWith(MockitoExtension.class)
class CampaignServiceTest {

    @Mock
    private CampaignRepository campaignRepository;

    @Mock
    private EventPublisher eventPublisher;

    @InjectMocks
    private CampaignService campaignService;

    @Test
    void shouldCreateCampaign() {
        // Given
        CreateCampaignRequest request = CampaignFixtures.validRequest();
        Campaign savedCampaign = CampaignFixtures.draftCampaign();

        when(campaignRepository.save(any(Campaign.class)))
            .thenReturn(savedCampaign);

        // When
        Campaign result = campaignService.createCampaign(request);

        // Then
        assertThat(result.getId()).isNotNull();
        verify(campaignRepository).save(any(Campaign.class));
        verify(eventPublisher).publish(any(CampaignCreatedEvent.class));
    }
}
```

### 11.8 API Contract Testing

```dart
// FE/test/api/

// Test API contract between FE and BE
group('API Contract Tests', () {
  test('GET /api/v1/campaigns returns expected structure', () async {
    // This test ensures FE and BE contracts match
    final response = await http.get(
      Uri.parse('http://localhost:8080/api/v1/campaigns'),
    );

    expect(response.statusCode, 200);

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    expect(json['success'], true);
    expect(json['data'], isA<List>());
    expect(json['message'], isNull);

    if ((json['data'] as List).isNotEmpty) {
      final campaign = (json['data'] as List).first;
      expect(campaign['id'], isA<int>());
      expect(campaign['name'], isA<String>());
      expect(campaign['status'], isIn(['DRAFT', 'ACTIVE', 'DONE', 'CANCELLED']));
    }
  });

  test('POST /api/v1/campaigns validates required fields', () async {
    final response = await http.post(
      Uri.parse('http://localhost:8080/api/v1/campaigns'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': ''}), // Missing required fields
    );

    expect(response.statusCode, 400);
  });
});
```

```java
// BE/src/test/java/.../controller/CampaignControllerContractTest.java

@WebMvcTest(CampaignController.class)
@Import(TestConfig.class)
class CampaignControllerContractTest {

    @Test
    @DisplayName("GET /api/v1/campaigns returns 200 with correct structure")
    void shouldReturnCampaignsWithCorrectStructure() throws Exception {
        // Given
        List<Campaign> campaigns = List.of(
            CampaignFixtures.activeCampaign(),
            CampaignFixtures.draftCampaign()
        );
        when(campaignService.getCampaigns(any(), any())).thenReturn(campaigns);

        // When/Then
        mockMvc.perform(get("/api/v1/campaigns"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success", is(true)))
            .andExpect(jsonPath("$.data", hasSize(2)))
            .andExpect(jsonPath("$.data[0].id", notNullValue()))
            .andExpect(jsonPath("$.data[0].name", notNullValue()))
            .andExpect(jsonPath("$.data[0].status", anyOf(
                is("DRAFT"),
                is("ACTIVE"),
                is("DONE"),
                is("CANCELLED")
            )));
    }
}
```

---

## 12. SonarQube Docker Setup (Combined FE + BE)

### 12.1 Start SonarQube Container

```bash
# Start SonarQube
docker run -d --name sonarqube \
  -p 9000:9000 \
  -p 9092:9092 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_OVERRIDE=true \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:latest

# Wait for startup (~1-2 minutes)
docker logs -f sonarqube
# Look for: "SonarQube is operational"

# Check health
curl http://localhost:9000/api/system/health
# Should return: {"mode":"UP"}

# Default credentials: admin / admin
# URL: http://localhost:9000
```

### 12.2 Create Projects in SonarQube

```bash
# Create Frontend project
curl -X POST "http://localhost:9000/api/projects/create" \
  -u admin:admin \
  -d "name=VN Map Campaign FE" \
  -d "project=vnmap-campaign-fe"

# Create Backend project
curl -X POST "http://localhost:9000/api/projects/create" \
  -u admin:admin \
  -d "name=VN Map Campaign BE" \
  -d "project=vnmap-campaign-be"

# Create combined project for overall view
curl -X POST "http://localhost:9000/api/projects/create" \
  -u admin:admin \
  -d "name=VN Map Campaign (Combined)" \
  -d "project=vnmap-campaign"
```

### 12.3 Quality Gate Configuration

```bash
# Create Quality Gate via API
curl -X POST "http://localhost:9000/api/qualitygates/create" \
  -u admin:admin \
  -d "name=VN Map Standards"

# Add conditions
# Coverage < 86% → ERROR
curl -X POST "http://localhost:9000/api/qualitygates/create_condition" \
  -u admin:admin \
  -d "gateId=<gate_id>&metric=coverage&operator=LT&error=86"

# Coverage < 90% → WARNING
curl -X POST "http://localhost:9000/api/qualitygates/create_condition" \
  -u admin:admin \
  -d "gateId=<gate_id>&metric=coverage&operator=LT&warning=90"

# Bugs > 0 → ERROR
curl -X POST "http://localhost:9000/api/qualitygates/create_condition" \
  -u admin:admin \
  -d "gateId=<gate_id>&metric=new_bugs&operator=GT&error=0"

# Duplications > 5% → ERROR
curl -X POST "http://localhost:9000/api/qualitygates/create_condition" \
  -u admin:admin \
  -d "gateId=<gate_id>&metric=duplicated_lines_density&operator=GT&error=5"

# Code Smells > 20 → ERROR
curl -X POST "http://localhost:9000/api/qualitygates/create_condition" \
  -u admin:admin \
  -d "gateId=<gate_id>&metric=code_smells&operator=GT&error=20"

# Assign to projects
curl -X POST "http://localhost:9000/api/qualitygates/select" \
  -u admin:admin \
  -d "gateId=<gate_id>&project=vnmap-campaign-fe"
curl -X POST "http://localhost:9000/api/qualitygates/select" \
  -u admin:admin \
  -d "gateId=<gate_id>&project=vnmap-campaign-be"
```

### 12.4 Frontend SonarQube Configuration

**CORRECTION:** Flutter/Dart produces LCOV coverage format, NOT Jacoco XML. Remove all Jacoco references from FE config.

```properties
# FE/sonar-project.properties
sonar.projectKey=vnmap-campaign-fe
sonar.projectName=VN Map Campaign FE
sonar.projectVersion=1.0.0

# Source code
sonar.sources=lib
sonar.tests=test
sonar.test.inclusions=**/*_test.dart
sonar.test.exclusions=**/*.g.dart,l10n/**

# Coverage - Dart produces LCOV format, not Jacoco
# flutter test --coverage produces coverage/lcov.info
sonar.coverage.jacoco.xmlReportsPaths=  # REMOVE - not valid for Dart
sonar.jacoco.reportPaths=              # REMOVE - not valid for Dart

# Use LCOV sensor (sonar-sonar-analyzers plugin handles this automatically)
# SonarQube 9.x+ auto-detects LCOV from coverage/lcov.info in project root
# If using older SonarQube, convert LCOV to Cobertura first:
#   dart run coverage:to_cobertura coverage/lcov.info > coverage/cobertura.xml
# Then use:
#   sonar.coverage.cobertura.xmlReportPaths=coverage/cobertura.xml

# Language
sonar.language=dart

# Encoding
sonar.sourceEncoding=UTF-8

# Quality gate
sonar.qualitygate.wait=true
sonar.qualitygate.timeout=300

# Exclusions
sonar.exclusions=**/*.g.dart,**/*.freezed.dart,l10n/**,lib/generated/**,build/**

# Branch (for PR analysis)
sonar.branch.name=main
sonar.pullrequest.key=${PULL_REQUEST_ID}
```

### 12.5 Backend SonarQube Configuration

```properties
# BE/sonar-project.properties
sonar.projectKey=vnmap-campaign-be
sonar.projectName=VN Map Campaign BE
sonar.projectVersion=1.0.0

# Source code
sonar.sources=src/main/java
sonar.tests=src/test/java
sonar.test.inclusions=**/*Test.java
sonar.test.exclusions=**/fixtures/**,**/resources/**

# Coverage (Jacoco - CORRECT for Java)
sonar.java.binaries=target/classes
sonar.java.source=17
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml

# Language
sonar.language=java

# Encoding
sonar.sourceEncoding=UTF-8

# Quality gate
sonar.qualitygate.wait=true
sonar.qualitygate.timeout=300

# Exclusions
sonar.exclusions=**/*.properties,**/*.xml,target/**,src/main/resources/**

# Branch
sonar.branch.name=main
```

### 12.6 Backend pom.xml Jacoco Configuration

```xml
<!-- BE/pom.xml -->
<properties>
    <jacoco.version>0.8.11</jacoco.version>
</properties>

<plugin>
    <groupId>org.jacoco</groupId>
    <artifactId>jacoco-maven-plugin</artifactId>
    <version>${jacoco.version}</version>
    <executions>
        <execution>
            <id>prepare-agent</id>
            <goals>
                <goal>prepare-agent</goal>
            </goals>
        </execution>
        <execution>
            <id>report</id>
            <phase>test</phase>
            <goals>
                <goal>report</goal>
            </goals>
            <configuration>
                <dataFileIncludes>**/*.exec</dataFileIncludes>
                <outputDirectory>target/site/jacoco</outputDirectory>
            </configuration>
        </execution>
        <execution>
            <id>check</id>
            <goals>
                <goal>check</goal>
            </goals>
            <configuration>
                <rules>
                    <rule>
                        <element>BUNDLE</element>
                        <limits>
                            <limit>
                                <counter>LINE</counter>
                                <value>COVEREDRATIO</value>
                                <minimum>0.86</minimum>
                            </limit>
                        </limits>
                    </rule>
                </rules>
            </configuration>
        </execution>
    </executions>
</plugin>
```

### 12.7 Run Tests & Upload to SonarQube

```bash
# ============= FRONTEND (DART) =============

cd FE

# 1. Run tests with coverage
flutter test --coverage

# 2. Install LCOV tools (if not installed)
# macOS
brew install lcov
# Linux
sudo apt install lcov
# Windows - use WSL or install via scoop

# 3. Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# 4. Convert to Cobertura XML for SonarQube
# Create script: lcov_to_cobertura.py
# Or use: dart run coverage:to_cobertura coverage/lcov.info

# 5. Upload to SonarQube
sonar-scanner \
  -Dsonar.projectKey=vnmap-campaign-fe \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<your-fe-token> \
  -Dsonar.sourceEncoding=UTF-8

# ============= BACKEND (JAVA) =============

cd BE

# 1. Run tests with coverage
mvn clean verify

# 2. Upload to SonarQube
sonar-scanner \
  -Dsonar.projectKey=vnmap-campaign-be \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<your-be-token> \
  -Dsonar.sourceEncoding=UTF-8

# ============= COMBINED REPORT =============

# Create combined coverage report
sonar-scanner \
  -Dsonar.projectKey=vnmap-campaign \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.token=<your-token> \
  -Dsonar.projectBaseDir=. \
  -Dsonar.sources=FE/lib,BE/src/main/java \
  -Dsonar.tests=FE/test,BE/src/test/java \
  -Dsonar.java.binaries=BE/target/classes
```

### 12.8 GitHub Actions CI/CD (SonarQube Docker)

**CORRECTION:** Each job's `services:` block creates an isolated container. Solution: Start SonarQube in a separate job and pass the host URL to other jobs via `needs:` and `outputs:`.

```yaml
# .github/workflows/test-sonarqube.yml

name: Test & SonarQube Analysis

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  JAVA_VERSION: '17'
  FLUTTER_VERSION: '3.24.0'

jobs:
  # ================================================================
  # Step 1: Start SonarQube Docker container
  # ================================================================
  sonarqube:
    runs-on: ubuntu-latest
    outputs:
      sq_host: ${{ steps.sq.outputs.host }}
    steps:
      - name: Start SonarQube
        run: |
          docker run -d --name sonarqube \
            -p 9000:9000 \
            -e SONAR_ES_BOOTSTRAP_CHECKS_OVERRIDE=true \
            sonarqube:latest

      - name: Wait for SonarQube to be ready
        id: sq
        run: |
          for i in {1..60}; do
            if curl -sf http://localhost:9000/api/system/health | grep -q '"mode":"UP"'; then
              echo "host=http://localhost:9000" >> $GITHUB_OUTPUT
              echo "SonarQube is ready"
              exit 0
            fi
            echo "Waiting... ($i/60)"
            sleep 3
          done
          echo "host=http://localhost:9000" >> $GITHUB_OUTPUT
          echo "Timed out waiting for SonarQube"
          exit 1

      - name: Keep container alive
        run: sleep 3600

  # ================================================================
  # Step 2: Backend Tests + Upload to SonarQube
  # ================================================================
  backend-test:
    runs-on: ubuntu-latest
    needs: sonarqube
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_DB: vnmap_test
          POSTGRES_USER: vnmap
          POSTGRES_PASSWORD: vnmap
        ports:
          - 5432:5432
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Set up JDK
        uses: actions/setup-java@v4
        with:
          java-version: ${{ env.JAVA_VERSION }}
          distribution: 'temurin'

      - name: Run tests and upload to SonarQube
        run: |
          cd BE
          SQ_HOST="${{ needs.sonarqube.outputs.sq_host }}"
          mvn clean verify sonar:sonar \
            -Dsonar.projectKey=vnmap-campaign-be \
            -Dsonar.host.url=$SQ_HOST \
            -Dsonar.token=${{ secrets.SONAR_TOKEN_BE }}

  # ================================================================
  # Step 3: Frontend Tests + Upload to SonarQube
  # ================================================================
  frontend-test:
    runs-on: ubuntu-latest
    needs: sonarqube

    steps:
      - uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: 'stable'

      - name: Run tests and upload to SonarQube
        run: |
          cd FE
          flutter pub get
          flutter test --coverage

          SQ_HOST="${{ needs.sonarqube.outputs.sq_host }}"
          sonar-scanner \
            -Dsonar.projectKey=vnmap-campaign-fe \
            -Dsonar.host.url=$SQ_HOST \
            -Dsonar.token=${{ secrets.SONAR_TOKEN_FE }} \
            -Dsonar.sourceEncoding=UTF-8

  # ================================================================
  # Step 4: Android Build (independent, no SonarQube needed)
  # ================================================================
  android-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: ${{ env.FLUTTER_VERSION }}
          channel: 'stable'

      - name: Build APK
        run: |
          cd FE
          flutter pub get
          flutter build apk --release

      - name: Upload APK
        uses: actions/upload-artifact@v4
        with:
          name: android-apk
          path: FE/build/app/outputs/flutter-apk/app-release.apk
```

### 12.9 Quality Gate Thresholds

| Metric | Warning | Error | Application |
|--------|---------|-------|-------------|
| Coverage | <90% | **<86%** | FE + BE |
| Line Coverage | <90% | **<86%** | BE only |
| Branch Coverage | <80% | <70% | BE only |
| Duplications | >3% | >5% | FE + BE |
| Code Smells | >10 | >20 | FE + BE |
| Bugs | >0 | >0 | FE + BE |
| Vulnerabilities | >0 | >0 | FE + BE |
| Security Hotspots | >0 | >0 | FE + BE |
| New Code Coverage | <90% | <86% | FE + BE |

---

## 13. Pre-Implementation Verification Checklist

### 13.1 Environment Verification (CRITICAL - Must Pass Before Starting)

```bash
# ============= WINDOWS (PowerShell) =============

# 1. Flutter SDK
flutter --version
flutter doctor

# 2. Android SDK
flutter doctor -v

# 3. Java for Backend
java -version  # Should be 17+

# 4. Docker Desktop
docker --version
docker ps  # Should show running containers

# 5. Verify current builds work
cd FE
flutter analyze
flutter test  # Run existing tests
flutter build web --release
flutter build apk --debug

# 6. Verify Backend builds
cd BE
mvn clean compile
mvn test  # Run existing tests

# ============= ALL MUST PASS BEFORE CONTINUING =============
```

### 13.2 SonarQube Setup (FE + BE)

```bash
# 1. Start SonarQube container
docker run -d --name sonarqube `
  -p 9000:9000 `
  -p 9092:9092 `
  -e SONAR_ES_BOOTSTRAP_CHECKS_OVERRIDE=true `
  sonarqube:latest

# 2. Wait for startup (~1-2 minutes)
docker logs -f sonarqube
# Look for: "SonarQube is operational"

# 3. Verify accessible
curl http://localhost:9000/api/system/health
# Should return: {"mode":"UP"}

# 4. Login: admin / admin
# 5. Create project: Administration → Projects → Create Project
# 6. Generate token: Account → Security → Generate Token

# ============= CREATE BOTH FE AND BE PROJECTS =============

# Create FE project
curl -X POST "http://localhost:9000/api/projects/create" `
  -u admin:admin `
  -d "name=VN Map Campaign FE" `
  -d "project=vnmap-campaign-fe"

# Create BE project
curl -X POST "http://localhost:9000/api/projects/create" `
  -u admin:admin `
  -d "name=VN Map Campaign BE" `
  -d "project=vnmap-campaign-be"
```

### 13.3 Quality Gate Setup

```bash
# 1. Create Quality Gate
# UI: Quality Gates → Create → Name: "VN Map 86% Min"

# 2. Add Conditions:
#    Coverage < 86% → ERROR
#    Bugs > 0 → ERROR
#    Code Smells > 20 → ERROR
#    Duplicated Lines > 5% → ERROR

# 3. Assign to projects
```

### 13.4 Baseline Coverage Scan

```bash
# ============= FRONTEND BASELINE =============

cd FE

# Run tests with coverage
flutter test --coverage

# Check coverage output
# Should be in: coverage/lcov.info

# Upload to SonarQube
sonar-scanner `
  -Dsonar.projectKey=vnmap-campaign-fe `
  -Dsonar.host.url=http://localhost:9000 `
  -Dsonar.token=<your-token>

# Check: http://localhost:9000/dashboard?id=vnmap-campaign-fe

# ============= BACKEND BASELINE =============

cd BE

# Run tests with coverage
mvn clean verify

# Check coverage output
# Should be in: target/site/jacoco/jacoco.xml

# Upload to SonarQube
sonar-scanner `
  -Dsonar.projectKey=vnmap-campaign-be `
  -Dsonar.host.url=http://localhost:9000 `
  -Dsonar.token=<your-token>

# Check: http://localhost:9000/dashboard?id=vnmap-campaign-be
```

### 13.5 Backend Test Infrastructure Setup

```bash
# 1. Add test dependencies to pom.xml
# Ensure these are in pom.xml:

# JUnit 5
<dependency>
    <groupId>org.junit.jupiter</groupId>
    <artifactId>junit-jupiter</artifactId>
    <version>5.10.0</version>
    <scope>test</scope>
</dependency>

# Mockito
<dependency>
    <groupId>org.mockito</groupId>
    <artifactId>mockito-core</artifactId>
    <version>5.7.0</version>
    <scope>test</scope>
</dependency>

# AssertJ
<dependency>
    <groupId>org.assertj</groupId>
    <artifactId>assertj-core</artifactId>
    <version>3.24.2</version>
    <scope>test</scope>
</dependency>

# Testcontainers (for integration tests)
<dependency>
    <groupId>org.testcontainers</groupId>
    <artifactId>testcontainers</artifactId>
    <version>1.19.3</version>
    <scope>test</scope>
</dependency>

# 2. Verify tests run
cd BE
mvn test

# 3. Check test results
# Should be in: target/surefire-reports/
```

### 13.6 Frontend Test Infrastructure Setup

```bash
# 1. Verify test dependencies in pubspec.yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.4.0
  build_runner: ^2.4.0

# 2. Run existing tests
cd FE
flutter test

# 3. Run tests with coverage
flutter test --coverage

# 4. Check coverage
# Should be in: coverage/
```

### 13.7 Pre-Implementation Sign-Off Checklist

```bash
# ============= MUST ALL BE GREEN BEFORE CODING =============

## Environment
- [ ] flutter --version shows 3.24.0+
- [ ] flutter doctor shows no errors
- [ ] flutter build apk --debug succeeds
- [ ] flutter build web --release succeeds
- [ ] flutter test passes
- [ ] java -version shows 17+
- [ ] mvn test passes
- [ ] Docker is running

## SonarQube
- [ ] SonarQube is accessible at localhost:9000
- [ ] Both projects created (FE + BE)
- [ ] Quality gate created with 86% threshold
- [ ] Quality gate assigned to projects

## Coverage Baseline
- [ ] FE coverage report generated
- [ ] BE coverage report generated
- [ ] Both uploaded to SonarQube
- [ ] Initial scan shows baseline coverage

## ONLY PROCEED WHEN ALL CHECKS ARE GREEN
```

---

## 14. Implementation Verification (Per Feature)

### 14.1 Per-Feature Checklist (TDD Workflow)

```bash
# ============= BEFORE CODING =============
# 1. Read spec
- [ ] Read relevant section in UI_REFRESH_PLAN.md
- [ ] Understand requirements fully

# 2. Write tests first (TDD - RED first)
- [ ] Write FE unit tests (should fail initially)
- [ ] Write FE widget tests
- [ ] Write BE service tests
- [ ] Write BE controller tests

# ============= WHILE CODING =============
# 3. Implement feature
- [ ] Implement frontend code
- [ ] Implement backend code if needed
- [ ] Run flutter analyze (0 errors)
- [ ] Run mvn compile (BE)

# ============= AFTER CODING =============
# 4. Verify tests pass (GREEN)
- [ ] flutter test passes
- [ ] flutter test --coverage shows ≥86%
- [ ] mvn test passes (BE)
- [ ] mvn test with coverage (BE)

# 5. Build verification
- [ ] flutter build web --release succeeds
- [ ] flutter build apk --debug succeeds
- [ ] mvn clean verify succeeds (BE)

# 6. Code quality
- [ ] No new code smells
- [ ] No new bugs
- [ ] SonarQube scan shows green

# 7. Commit
- [ ] Commit with descriptive message
- [ ] Include test evidence in commit message
```

### 14.2 Phase Completion Checklist

```bash
# ============= PHASE COMPLETION =============

# Before finishing each phase:

## Phase 1: Design System Foundation
- [ ] lib/core/theme/ created with all tokens
- [ ] Light/dark mode works
- [ ] FE: Unit tests for theme providers
- [ ] BE: Baseline coverage established
- [ ] flutter analyze passes
- [ ] flutter build web --release succeeds
- [ ] flutter build apk --debug succeeds
- [ ] BE: mvn test passes

## Phase 2: Bento Card Components
- [ ] BentoCard implemented
- [ ] ShimmerCard implemented
- [ ] Widget tests written
- [ ] Dashboard uses bento cards
- [ ] BE: CampaignService tests written
- [ ] flutter analyze passes
- [ ] flutter build succeeds

## Phase 3: Map Optimization
- [ ] Progressive loading works
- [ ] Marker clustering implemented
- [ ] Boundary lazy loading works
- [ ] FE: Map provider tests written
- [ ] BE: GeocodingService tests written
- [ ] flutter build succeeds
- [ ] mvn test passes

## Phase 4: Map Glassmorphism UI
- [ ] GlassSidebar implemented
- [ ] ModernBottomSheet implemented
- [ ] Responsive layout works
- [ ] Widget tests written
- [ ] BE: Map controller tests written
- [ ] FE coverage ≥ 70%
- [ ] BE coverage ≥ 60%

## Phase 5: Responsive Design
- [ ] All pages responsive
- [ ] Mobile tested
- [ ] Tablet tested
- [ ] Desktop tested
- [ ] Responsive tests written
- [ ] FE coverage ≥ 80%
- [ ] BE coverage ≥ 70%

## Phase 6: Final Verification
- [ ] ALL FE tests pass
- [ ] ALL BE tests pass
- [ ] FE coverage ≥ 86%
- [ ] BE coverage ≥ 86%
- [ ] SonarQube quality gate GREEN
- [ ] flutter build web --release succeeds
- [ ] flutter build apk --release succeeds
- [ ] APK size < 30MB
```

---

## 15. Backend Test Implementation Details

### 15.1 Backend Test Classes to Create

```java
// BE/src/test/java/com/vnmap/campaign/

// Service Layer Tests (Unit Tests)
service/
├── CampaignServiceTest.java          // 50+ test cases
├── EventServiceTest.java              // 40+ test cases
├── SchoolServiceTest.java             // 30+ test cases
├── UserServiceTest.java              // 30+ test cases
├── InteractionServiceTest.java       // 40+ test cases
├── GeocodingServiceTest.java        // 20+ test cases
└── AuthServiceTest.java             // 25+ test cases

// Repository Tests (Integration Tests)
repository/
├── CampaignRepositoryTest.java       // 20+ test cases
├── EventRepositoryTest.java          // 20+ test cases
├── SchoolRepositoryTest.java         // 15+ test cases
├── UserRepositoryTest.java          // 15+ test cases
└── InteractionRepositoryTest.java   // 20+ test cases

// DB Testing Strategy:
// - Unit tests use Mockito (no real DB)
// - Integration tests use Testcontainers with PostgreSQL
// - Repository tests use @DataJpaTest with @AutoConfigureTestDatabase

// Controller Tests (WebMvcTest)
controller/
├── CampaignControllerTest.java      // 30+ test cases
├── EventControllerTest.java          // 25+ test cases
├── SchoolControllerTest.java         // 20+ test cases
├── AuthControllerTest.java          // 20+ test cases
├── UserControllerTest.java          // 25+ test cases
└── DashboardControllerTest.java     // 15+ test cases
```

### 15.2 Backend Test Example (CampaignServiceTest)

```java
package com.vnmap.campaign.service;

import com.vnmap.campaign.dto.CreateCampaignRequest;
import com.vnmap.campaign.entity.Campaign;
import com.vnmap.campaign.exception.ValidationException;
import com.vnmap.campaign.exception.ResourceNotFoundException;
import com.vnmap.campaign.repository.CampaignRepository;
import com.vnmap.campaign.event.CampaignEventPublisher;
import org.junit.jupiter.api.*;
import org.mockito.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
@DisplayName("Campaign Service Tests")
class CampaignServiceTest {

    @Mock private CampaignRepository campaignRepository;
    @Mock private CampaignEventPublisher eventPublisher;
    @InjectMocks private CampaignService campaignService;

    private Campaign activeCampaign;

    @BeforeEach void setUp() {
        activeCampaign = Campaign.builder()
            .id(1L).name("Test Campaign").status("ACTIVE")
            .startDate(LocalDate.now()).endDate(LocalDate.now().plusMonths(6))
            .build();
    }

    @Nested @DisplayName("createCampaign")
    class CreateCampaignTests {

        @Test @DisplayName("should create campaign with valid data")
        void shouldCreateWithValidData() {
            // Given
            CreateCampaignRequest req = CreateCampaignRequest.builder()
                .name("New Campaign").objective("Test").status("DRAFT")
                .startDate(LocalDate.now()).endDate(LocalDate.now().plusMonths(3))
                .ownerId(1L).build();
            when(campaignRepository.save(any(Campaign.class))).thenReturn(activeCampaign);

            // When
            Campaign result = campaignService.createCampaign(req);

            // Then
            assertThat(result.getId()).isNotNull();
            verify(campaignRepository).save(any(Campaign.class));
            verify(eventPublisher).publish(any());
        }

        @Test @DisplayName("should throw when name is blank")
        void shouldThrowWhenNameBlank() {
            CreateCampaignRequest req = CreateCampaignRequest.builder()
                .name("").objective("Test").build();

            assertThatThrownBy(() -> campaignService.createCampaign(req))
                .isInstanceOf(ValidationException.class);
            verify(campaignRepository, never()).save(any());
        }

        @Test @DisplayName("should throw when end date before start date")
        void shouldThrowWhenDateInvalid() {
            CreateCampaignRequest req = CreateCampaignRequest.builder()
                .name("Test").objective("Test")
                .startDate(LocalDate.now().plusMonths(3))
                .endDate(LocalDate.now()).build();

            assertThatThrownBy(() -> campaignService.createCampaign(req))
                .isInstanceOf(ValidationException.class)
                .hasMessageContaining("end date");
        }
    }

    @Nested @DisplayName("getCampaigns")
    class GetCampaignsTests {

        @Test @DisplayName("should return all campaigns when no filter")
        void shouldReturnAllWhenNoFilter() {
            when(campaignRepository.findAll()).thenReturn(List.of(activeCampaign));
            List<Campaign> result = campaignService.getCampaigns(null, null);
            assertThat(result).hasSize(1);
        }

        @Test @DisplayName("should filter by status")
        void shouldFilterByStatus() {
            when(campaignRepository.findByStatus("ACTIVE"))
                .thenReturn(List.of(activeCampaign));
            List<Campaign> result = campaignService.getCampaigns("ACTIVE", null);
            assertThat(result).hasSize(1);
            assertThat(result.get(0).getStatus()).isEqualTo("ACTIVE");
        }
    }

    @Nested @DisplayName("updateCampaign")
    class UpdateCampaignTests {

        @Test @DisplayName("should update when found")
        void shouldUpdateWhenFound() {
            when(campaignRepository.findById(1L)).thenReturn(Optional.of(activeCampaign));
            when(campaignRepository.save(any())).thenReturn(activeCampaign);

            campaignService.updateCampaign(1L, UpdateCampaignRequest.builder()
                .name("Updated").build());

            verify(campaignRepository).save(any(Campaign.class));
        }

        @Test @DisplayName("should throw when not found")
        void shouldThrowWhenNotFound() {
            when(campaignRepository.findById(999L)).thenReturn(Optional.empty());

            assertThatThrownBy(() -> campaignService.updateCampaign(999L, null))
                .isInstanceOf(ResourceNotFoundException.class);
        }
    }
}
```

### 15.3 Controller Test Example

```java
@WebMvcTest(CampaignController.class)
@DisplayName("Campaign Controller Tests")
class CampaignControllerTest {

    @Autowired private MockMvc mockMvc;
    @Autowired private ObjectMapper objectMapper;
    @MockBean private CampaignService campaignService;

    @Test @DisplayName("GET /api/v1/campaigns returns 200")
    @WithMockUser(roles = "MANAGER")
    void shouldReturnCampaigns() throws Exception {
        when(campaignService.getCampaigns(any(), any()))
            .thenReturn(List.of(CampaignDto.builder().id(1L).name("Test").build()));

        mockMvc.perform(get("/api/v1/campaigns"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.success").value(true))
            .andExpect(jsonPath("$.data[0].name").value("Test"));
    }

    @Test @DisplayName("POST returns 400 when name blank")
    @WithMockUser(roles = "MANAGER")
    void shouldReturn400WhenNameBlank() throws Exception {
        mockMvc.perform(post("/api/v1/campaigns")
                .with(csrf())
                .contentType(MediaType.APPLICATION_JSON)
                .content("{\"name\":\"\"}"))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.success").value(false));
    }
}
```

---

## 16. Implementation Phases (Updated with BE Testing)

### Phase 0: Pre-Implementation Setup
- [ ] Verify Flutter environment
- [ ] Verify Backend environment (Java 17+, Maven)
- [ ] Setup SonarQube Docker
- [ ] Create projects in SonarQube (FE + BE)
- [ ] Configure quality gates (86% min)
- [ ] Create baseline coverage scan
- [ ] Write sample tests for CI/CD

### Phase 1: Design System Foundation
**Frontend:**
- [ ] Create theme files with design tokens
- [ ] Add responsive helpers
- [ ] Write tests for theme components
- [ ] FE coverage target: 20%

**Backend:**
- [ ] Create test infrastructure (JUnit 5, Mockito)
- [ ] Write baseline model tests
- [ ] BE coverage target: 15%

**Verification:**
- [ ] flutter analyze passes
- [ ] mvn test passes
- [ ] FE coverage ≥ 20%, BE coverage ≥ 15%

### Phase 2: Bento Card Components
**Frontend:**
- [ ] Create BentoCard component
- [ ] Create ShimmerCard component
- [ ] Write widget tests
- [ ] Update dashboard KPIs
- [ ] FE coverage target: 35%

**Backend:**
- [ ] Write CampaignService tests
- [ ] Write CampaignController tests
- [ ] BE coverage target: 30%

**Verification:**
- [ ] flutter build apk --debug succeeds
- [ ] flutter build web --release succeeds
- [ ] mvn test passes
- [ ] FE coverage ≥ 35%, BE coverage ≥ 30%

### Phase 3: Map Optimization & Sample Data
**Frontend:**
- [ ] Progressive boundary loading
- [ ] Marker clustering
- [ ] Write map provider tests
- [ ] FE coverage target: 50%

**Backend:**
- [ ] Write GeocodingService tests
- [ ] Write SchoolService tests
- [ ] Write MapController tests
- [ ] BE coverage target: 45%

**Verification:**
- [ ] Map loads in <3s
- [ ] flutter build succeeds
- [ ] mvn test passes
- [ ] FE coverage ≥ 50%, BE coverage ≥ 45%

### Phase 4: Map Glassmorphism UI
**Frontend:**
- [ ] GlassSidebar component
- [ ] ModernBottomSheet component
- [ ] Responsive map layout
- [ ] Write widget tests
- [ ] FE coverage target: 65%

**Backend:**
- [ ] Write EventService tests
- [ ] Write InteractionService tests
- [ ] BE coverage target: 60%

**Verification:**
- [ ] FE coverage ≥ 65%, BE coverage ≥ 60%
- [ ] Quality gate GREEN
- [ ] flutter build succeeds

### Phase 5: Responsive Design & Polish
**Frontend:**
- [ ] All pages responsive
- [ ] Write responsive tests
- [ ] Test on mobile (physical device)
- [ ] Test on tablet
- [ ] Test on desktop
- [ ] FE coverage target: 80%

**Backend:**
- [ ] Write remaining service tests
- [ ] Write integration tests
- [ ] BE coverage target: 75%

**Verification:**
- [ ] Responsive works on all breakpoints
- [ ] FE coverage ≥ 80%, BE coverage ≥ 75%

### Phase 6: Final Verification & Release
**Frontend:**
- [ ] All FE tests pass
- [ ] FE coverage ≥ 86%
- [ ] flutter build web --release succeeds
- [ ] flutter build apk --release succeeds
- [ ] APK size < 30MB

**Backend:**
- [ ] All BE tests pass
- [ ] BE coverage ≥ 86%
- [ ] mvn clean verify succeeds

**Quality:**
- [ ] SonarQube quality gate GREEN
- [ ] No critical bugs
- [ ] No security vulnerabilities

---

## 18. Accessibility (A11Y)

**IMPORTANT:** A UI/UX refresh should maintain and improve accessibility. Flutter Web apps must meet WCAG 2.1 AA standards.

### 18.1 Color Contrast Requirements

**CORRECTION:** The current primary color `#B91C1C` has insufficient contrast for some use cases. The same red used for both primary actions and focus indicators reduces visual distinction.

| Element | Current Color | Contrast Ratio | WCAG AA Required | Status |
|---------|--------------|----------------|------------------|--------|
| Primary text on white | `#0F172A` | 15.3:1 | ≥ 4.5:1 | ✅ Pass |
| Primary button on white | `#B91C1C` | 4.6:1 | ≥ 4.5:1 | ✅ Pass |
| Focus ring on white | `#B91C1C` | 4.6:1 | ≥ 3:1 | ✅ Pass |
| Red text on pink background | `#B91C1C` on `#FEE2E2` | ~2.5:1 | ≥ 4.5:1 | ❌ Fail |

**Recommended Fix:**
```dart
// Use different colors for actions vs. focus
Color primaryAction = Color(0xFFB91C1C);  // Primary buttons
Color focusIndicator = Color(0xFF2563EB);  // Focus rings (blue - better distinction)
```

### 18.2 Semantic Widgets & Screen Reader Support

```dart
// DO: Use semantic widgets
Semantics(
  label: 'Campaign list with ${campaigns.length} items',
  child: ListView.builder(...),
)

// DO: Use proper heading hierarchy
Heading(level: 1, child: Text('Campaign Dashboard'))
Heading(level: 2, child: Text('Active Campaigns'))
Heading(level: 3, child: Text('Campaign: Summer 2026'))

// DON'T: Rely on color alone for meaning
// BAD: Icon(color: Colors.red) - what does red mean?
// GOOD: Icon(color: Colors.red, semanticLabel: 'Error: Campaign inactive')
```

### 18.3 Keyboard Navigation (Web)

```dart
// Enable keyboard navigation for all interactive elements
FocusTraversalGroup(
  child: Row(
    children: [
      // Tab order should be logical
      ElevatedButton(key: Key('save-btn'), ...),
      OutlinedButton(key: Key('cancel-btn'), ...),
    ],
  ),
)

// Custom shortcuts
Shortcuts(
  shortcuts: {
    LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
      SaveIntent,
    LogicalKeySet(LogicalKeyboardKey.escape): CancelIntent,
  },
  child: Actions(...),
)
```

### 18.4 Touch Targets (Mobile)

```dart
// Minimum 48x48dp touch target (WCAG 2.1)
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    onPressed: onPressed,
    icon: Icon(Icons.menu),
    tooltip: 'Menu', // Important for screen readers
  ),
)
```

### 18.5 Accessibility Checklist

```bash
# Testing commands
# 1. Chrome DevTools → Elements → Accessibility panel
# 2. Lighthouse → Accessibility audit
# 3. Screen reader testing (VoiceOver, NVDA)

# Accessibility Requirements
- [ ] All images have alt text
- [ ] Color is not the only indicator of meaning
- [ ] Focus states are visible (keyboard users)
- [ ] Touch targets ≥ 48x48dp
- [ ] Text contrast ratio ≥ 4.5:1
- [ ] Semantic headings (h1 → h6)
- [ ] Form labels are associated with inputs
- [ ] Error messages are announced to screen readers
- [ ] Page has lang attribute
```

---

## 19. Rollback & Feature Flag Strategy

### 19.1 Why Feature Flags?

A 6-phase visual overhaul touching theme, cards, map, and navigation simultaneously needs a rollback strategy. Without it, Phase 4 regressions affect all previous phases.

### 19.2 Feature Flag Implementation

```dart
// FE/lib/core/config/feature_flags.dart
class FeatureFlags {
  static const bool useNewTheme = true;
  static const bool useBentoCards = true;
  static const bool useGlassmorphism = true;
  static const bool useResponsiveLayout = true;

  // Phase gates (for gradual rollout)
  static bool get useNewDesign => useNewTheme && useBentoCards;
}

// Usage in code
Widget build(BuildContext context) {
  if (FeatureFlags.useBentoCards) {
    return BentoDashboard();
  }
  return LegacyDashboard();
}
```

### 19.3 Environment-Based Feature Flags

```dart
// FE/lib/core/config/feature_flags.dart
class FeatureFlags {
  // Read from environment or remote config
  static bool useNewTheme = bool.fromEnvironment('USE_NEW_THEME', defaultValue: true);
  static bool useBentoCards = bool.fromEnvironment('USE_BENTO_CARDS', defaultValue: true);

  // Remote config (for production rollout)
  static Future<void> loadRemoteConfig() async {
    final remote = await RemoteConfigService.getConfig();
    useNewTheme = remote['useNewTheme'] ?? true;
    useBentoCards = remote['useBentoCards'] ?? true;
  }
}
```

### 19.4 Rollback Strategy

```bash
# 1. Feature Flag Rollback (Fastest)
# Just flip the flag in config - no redeploy needed
# FeatureFlags.useNewTheme = false;

# 2. Git Rollback (If flag not working)
# Revert to previous commit
git revert HEAD  # Creates new commit
git push origin main

# 3. Full Deploy Rollback (If major issue)
git checkout v1.2.3  # Previous tag
flutter build web --release
# Deploy previous build
```

### 19.5 Phase Isolation Strategy

```bash
# Each phase should be independently deployable
# Phase 1: Design tokens (low risk)
# Phase 2: Bento cards (medium risk - affects dashboard)
# Phase 3: Map optimization (high risk - core feature)
# Phase 4: Glassmorphism UI (medium risk - affects map)
# Phase 5: Responsive (high risk - affects all pages)
# Phase 6: Final polish (low risk)

# Recommended rollout:
# Phase 1 → 2 → 3 (map first, as it's the heaviest) → 4 → 5 → 6
```

### 19.6 Rollback Checklist

```bash
# Before each phase deployment:
- [ ] Document current working state (git tag)
- [ ] Enable feature flag for phase
- [ ] Deploy to staging
- [ ] Run smoke tests
- [ ] Monitor error rates
- [ ] If regression: flip flag or git revert

# Rollback commands:
git tag -a v1.2.3 -m "Before Phase X"
git push origin v1.2.3

# If needed:
git revert HEAD
git push origin main
```

---

## 20. Testing Checklist (Final)

### Core Functionality
- [ ] Light mode renders correctly
- [ ] Dark mode renders correctly
- [ ] Theme toggle is smooth (no flash)
- [ ] Bento cards align on all screen sizes
- [ ] Bottom sheet drag works smoothly
- [ ] Map tiles switch per mode
- [ ] Shimmer animations are smooth
- [ ] No jank on 60fps scroll

### Mobile App
- [ ] Android APK builds successfully
- [ ] APK size <30MB (release)
- [ ] App launches <2s
- [ ] 60fps scrolling
- [ ] Touch interactions work
- [ ] Map gestures work (pinch/zoom)

### Quality Assurance
- [ ] Test coverage ≥ 86%
- [ ] SonarQube quality gate passes
- [ ] flutter analyze passes (0 errors)
- [ ] All tests pass
- [ ] No regression in existing features
