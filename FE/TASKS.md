# Flutter Frontend Tasks - Vietnam Map App

**Backend API:** `http://localhost:8080/api/v1`

---

## Person 1: Data Layer & Core Services

### Task 1.1: Project Setup & API Client
- [ ] Create Flutter project with `flutter create`
- [ ] Setup `pubspec.yaml` dependencies:
  - `dio` - HTTP client
  - `flutter_bloc` - State management
  - `get_it` - Dependency injection
  - `equatable` - Value equality
  - `flutter_map` + `latlong2` - Map display
  - `geolocator` - GPS location
- [ ] Create API client with Dio (base URL, interceptors, error handling)
- [ ] Create `.env` config for API URL

### Task 1.2: Geo Repository & Models
- [ ] Create `AdministrativeUnit` model
  ```dart
  class AdministrativeUnit {
    final int id;
    final String code;
    final String name;
    final String level; // PROVINCE, DISTRICT, WARD
    final int? parentId;
    final double? centroidLat;
    final double? centroidLng;
  }
  ```
- [ ] Create `Weather` model
  ```dart
  class Weather {
    final double temperature;
    final double feelsLike;
    final int humidity;
    final double windSpeed;
    final String description;
    final String iconCode;
    final String locationName;
    final DateTime timestamp;
  }
  ```
- [ ] Create `GeoRepository`
  - `getProvinces()` -> `GET /geo/provinces`
  - `getDistricts(provinceCode)` -> `GET /geo/districts?provinceCode=`
  - `getWards(districtCode)` -> `GET /geo/wards?districtCode=`
  - `getUnit(code)` -> `GET /geo/units/{code}`
  - `getBoundary(code)` -> `GET /geo/units/{code}/boundary`
  - `reverseGeocode(lat, lng)` -> `GET /geo/reverse?lat=&lng=`
- [ ] Create `WeatherRepository`
  - `getWeather(lat, lng)` -> `GET /weather?lat=&lng=`
  - `getWeatherByUnit(unitCode)` -> `GET /weather/unit/{code}`

### Task 1.3: State Management (BLoC)
- [ ] `GeoBloc` - manages province/district/ward selection
- [ ] `WeatherCubit` - manages weather state
- [ ] `LocationCubit` - manages GPS location state

### Deliverable: PR #1 - Core Data Layer
- Clean architecture with repository pattern
- All models and API services
- Unit tests for repositories

---

## Person 2: Map & Location Features

### Task 2.1: Vietnam Map Display
- [ ] Setup `flutter_map` with OpenStreetMap tiles
- [ ] Add Vietnam boundary GeoJSON from API
- [ ] Implement map zoom/pan controls
- [ ] Add scale indicator
- [ ] Center map on Vietnam (lat: 14.0583, lng: 108.2772)

### Task 2.2: Province Selection on Map
- [ ] Display province polygons with different colors
- [ ] Tap on province -> show info card + highlight
- [ ] Show province name label
- [ ] Zoom to province on tap

### Task 2.3: Location Picker Feature
- [ ] Hierarchical picker: Province -> District -> Ward
- [ ] Search/filter in picker
- [ ] Recent selections
- [ ] "Use my location" button (GPS)
- [ ] Show selected location on map

### Task 2.4: Reverse Geocoding UI
- [ ] Long press on map -> reverse geocode
- [ ] Show location info bottom sheet
- [ ] Option to set as selected location

### Deliverable: PR #2 - Map & Location Features
- Interactive map with Vietnam boundaries
- Location picker with hierarchical selection
- GPS integration

---

## Person 3: Weather & UI Polish

### Task 3.1: Weather Display Widget
- [ ] Weather card widget (temperature, humidity, wind, icon)
- [ ] Weather icon mapping (weather code -> icon)
- [ ] Weather detail expansion
- [ ] Loading and error states
- [ ] Pull-to-refresh weather data

### Task 3.2: Weather Screen
- [ ] Weather for selected location
- [ ] Weather for current GPS location
- [ ] Toggle between Celsius/Fahrenheit
- [ ] Last updated timestamp

### Task 3.3: Home Screen Integration
- [ ] Combine map + weather
- [ ] Selected location weather card at top
- [ ] Quick actions (my location, search)
- [ ] Bottom sheet for location details

### Task 3.4: App Shell & Navigation
- [ ] Bottom navigation: Map | Weather | Settings
- [ ] App bar with search
- [ ] Settings screen (units, theme)
- [ ] Splash screen
- [ ] Error handling screens

### Task 3.5: Polish & Performance
- [ ] Skeleton loaders
- [ ] Error messages
- [ ] Empty states
- [ ] Responsive layout (phone/tablet)
- [ ] App icon and splash screen assets

### Deliverable: PR #3 - Weather & Polish
- Complete weather feature
- Integrated home screen
- Production-ready UI

---

## Task Dependencies

```
PR #1 (Person 1) ──────┐
                        ├──► PR #3 (Person 3) needs PR #1
PR #2 (Person 2) ──────┘
                        └──► PR #3 (Person 3) needs PR #2
```

---

## API Reference

### Geo Endpoints
| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/api/v1/geo/provinces` | List of provinces |
| GET | `/api/v1/geo/districts?provinceCode=` | List of districts |
| GET | `/api/v1/geo/wards?districtCode=` | List of wards |
| GET | `/api/v1/geo/units/{code}` | Unit details with centroid |
| GET | `/api/v1/geo/units/{code}/boundary` | GeoJSON polygon |
| GET | `/api/v1/geo/provinces/{code}/boundary` | Province GeoJSON |
| GET | `/api/v1/geo/reverse?lat=&lng=` | Reverse geocode |
| POST | `/api/v1/geo/admin/calculate-centroids` | Recalculate centroids |

### Weather Endpoints
| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/api/v1/weather?lat=&lng=` | Weather by coordinates |
| GET | `/api/v1/weather/unit/{code}` | Weather by unit code |
| GET | `/api/v1/weather/cache?lat=&lng=` | Check cache status |

### System Endpoints
| Method | Endpoint | Response |
|--------|----------|----------|
| GET | `/actuator/health` | Health check |
| GET | `/api-docs` | OpenAPI JSON |
| GET | `/swagger-ui.html` | Swagger UI |

### Response Format
```json
{
  "success": true,
  "message": "Provinces retrieved successfully",
  "data": [...],
  "timestamp": "2026-05-28T18:00:00"
}
```

---

## Suggested Timeline

| Day | Person 1 | Person 2 | Person 3 |
|-----|----------|----------|----------|
| 1-2 | Project setup, API client | Map setup, tiles | Weather widget design |
| 3-4 | Models, repositories | Province polygons | Weather screen |
| 5-6 | BLoC state management | Location picker | Home screen integration |
| 7 | PR review, fixes | PR review, fixes | Polish, bug fixes |

---

## Code Review Checklist

- [ ] API errors handled gracefully
- [ ] Loading states for all async operations
- [ ] Null safety enforced
- [ ] Unit tests for business logic
- [ ] No hardcoded strings (use localization ready)
- [ ] Responsive layouts tested
