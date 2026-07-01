/// Canonical list of all Firebase Analytics events for the VN Map Campaign app.
/// Use [AnalyticsService.logEvent] with these names to ensure consistency.
///
/// Naming convention: snake_case verb_object (e.g. `login`, `screen_view`).
class AnalyticsEvents {
  AnalyticsEvents._();

  // ── Navigation ─────────────────────────────────────────────────────────────

  /// Fired when a user successfully logs in.
  /// Params: `method` — 'password' | 'google'
  static const login = _Event('login', params: ['method']);

  /// Fired when a user logs out.
  static const logout = _Event('logout');

  /// Fired on every screen/push navigation via [NavigationObserver].
  /// Params: `screen_name` — route path, `role` — user role
  static const screenView = _Event('screen_view', params: ['screen_name', 'role']);

  // ── Campaign ───────────────────────────────────────────────────────────────

  /// Fired when a campaign detail page loads.
  /// Params: `campaign_id`
  static const campaignView = _Event('campaign_view', params: ['campaign_id']);

  /// Fired when an event detail page loads.
  /// Params: `event_id`, `campaign_id`
  static const eventView = _Event('event_view', params: ['event_id', 'campaign_id']);

  /// Fired when a school detail page loads.
  /// Params: `school_uid`
  static const schoolView = _Event('school_view', params: ['school_uid']);

  // ── Registration ──────────────────────────────────────────────────────────

  /// Fired when a student submits the registration form.
  /// Params: `campaign_id`
  static const studentRegistrationSubmitted =
      _Event('student_registration_submitted', params: ['campaign_id']);

  /// Fired when a campaign manager/staff changes a student's registration status.
  /// Params: `campaign_id`, `status` — PENDING | APPROVED | REJECTED | CANCELLED
  static const registrationStatusChanged =
      _Event('registration_status_changed', params: ['campaign_id', 'status']);

  // ── Map ──────────────────────────────────────────────────────────────────

  /// Fired when a map marker is tapped.
  /// Params: `school_uid`, `geocode_status` — FULL | APPROXIMATE | PENDING
  static const mapMarkerTapped =
      _Event('map_marker_tapped', params: ['school_uid', 'geocode_status']);

  /// Fired when a province is selected on the map.
  /// Params: `province_code`
  static const mapProvinceSelected =
      _Event('map_province_selected', params: ['province_code']);

  // ── Analytics Page ────────────────────────────────────────────────────────

  /// Fired when a filter is changed on the Analytics page.
  /// Params: `filter_type` — 'date_range' | 'province' | 'outcome',
  ///         `value` — selected value
  static const analyticsFilterChanged =
      _Event('analytics_filter_changed', params: ['filter_type', 'value']);

  // ── Weather ───────────────────────────────────────────────────────────────

  /// Fired when a weather detail page loads.
  /// Params: `unit_code`
  static const weatherViewed = _Event('weather_viewed', params: ['unit_code']);
}

class _Event {
  const _Event(this.name, {this.params});
  final String name;
  final List<String>? params;
}
