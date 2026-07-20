// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Vietnam Map';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get map => 'Map';

  @override
  String get weather => 'Weather';

  @override
  String get campaigns => 'Campaigns';

  @override
  String get campaign => 'Campaign';

  @override
  String get events => 'Events';

  @override
  String get schools => 'Schools';

  @override
  String get school => 'School';

  @override
  String get users => 'Users';

  @override
  String get mine => 'Mine';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get accessDenied => 'Access denied';

  @override
  String get noPermission => 'You do not have permission to view this page.';

  @override
  String get signInToContinue => 'Sign in to continue with your assigned role';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get signingIn => 'Signing in...';

  @override
  String get signUp => 'Sign up';

  @override
  String get loginButton => 'Login';

  @override
  String get search => 'Search';

  @override
  String get refresh => 'Refresh';

  @override
  String get retry => 'Retry';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get create => 'Create';

  @override
  String get apply => 'Apply';

  @override
  String get clear => 'Clear';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get assign => 'Assign';

  @override
  String get remove => 'Remove';

  @override
  String get submit => 'Submit';

  @override
  String get submitRegistration => 'Submit registration';

  @override
  String get submitting => 'Submitting...';

  @override
  String get required => 'Required';

  @override
  String get all => 'All';

  @override
  String get previous => 'Previous';

  @override
  String get next => 'Next';

  @override
  String page(int page, int total) {
    return 'Page $page / $total';
  }

  @override
  String showingOf(int count, int total) {
    return 'Showing $count of $total';
  }

  @override
  String get noCampaignsYet => 'No campaigns yet';

  @override
  String get noEventsYet => 'No events yet';

  @override
  String get noSchoolsFound => 'No schools found';

  @override
  String get noStudents => 'No students';

  @override
  String get noTeachersPersons => 'No teachers/persons';

  @override
  String get noRelatives => 'No relatives';

  @override
  String get noEmployees => 'No employees';

  @override
  String get noRegistrationsYet => 'No registrations yet';

  @override
  String get noData => 'No data';

  @override
  String get campaignCreated => 'Campaign created';

  @override
  String get campaignSaved => 'Campaign saved';

  @override
  String get eventSaved => 'Event saved';

  @override
  String get schoolAssigned => 'School assigned';

  @override
  String get schoolRemoved => 'School removed';

  @override
  String get employeeAssigned => 'Employee assigned';

  @override
  String get employeeRemoved => 'Employee removed';

  @override
  String get registrationSubmitted => 'Registration submitted';

  @override
  String get campaignDashboard => 'Campaign Dashboard';

  @override
  String get campaignEvents => 'Campaign Events';

  @override
  String get createEvent => 'Create Event';

  @override
  String get eventDetail => 'Event Detail';

  @override
  String get thongTin => 'Information';

  @override
  String get truongThamGia => 'Participating Schools';

  @override
  String get nhanSu => 'Staff';

  @override
  String get interactions => 'Interactions';

  @override
  String get assignedSchools => 'Assigned schools';

  @override
  String get findSchools => 'Find schools';

  @override
  String get assignedEmployees => 'Assigned employees';

  @override
  String get employees => 'Employees';

  @override
  String get noAssignedSchools => 'No assigned schools';

  @override
  String get noAssignedEmployees => 'No assigned employees';

  @override
  String get schoolDetail => 'School Detail';

  @override
  String get tongQuan => 'Overview';

  @override
  String get hocSinh => 'Students';

  @override
  String get gvBgh => 'Teachers/Staff';

  @override
  String get nguoiThan => 'Relatives';

  @override
  String get province => 'Province';

  @override
  String get provinceCode => 'Province code';

  @override
  String get commune => 'Commune';

  @override
  String get communeCode => 'Commune code';

  @override
  String get schoolCode => 'School code';

  @override
  String get address => 'Address';

  @override
  String get area => 'Area';

  @override
  String get name => 'Name';

  @override
  String get type => 'Type';

  @override
  String get status => 'Status';

  @override
  String get location => 'Location';

  @override
  String get note => 'Note';

  @override
  String get grade => 'Grade';

  @override
  String get classLabel => 'Class';

  @override
  String get phone => 'Phone';

  @override
  String get role => 'Role';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get owner => 'Owner';

  @override
  String get time => 'Time';

  @override
  String get startsAt => 'Starts at';

  @override
  String get endsAt => 'Ends at';

  @override
  String get viewOnFullMap => 'View on full map';

  @override
  String get createEventTitle => 'Create Event';

  @override
  String get editEventTitle => 'Edit Event';

  @override
  String get eventType => 'Event type';

  @override
  String get locationLabel => 'Address label';

  @override
  String get pickOnMap => 'Pick on map';

  @override
  String get noLocationSelected => 'No location selected';

  @override
  String get noSchoolsAssigned =>
      'No schools assigned yet. Assign schools in the Schools tab to enable auto-location, or drop a pin manually below.';

  @override
  String get provinceCenterLocation =>
      'Using province center as approximate location - drag the pin to refine.';

  @override
  String get endsAtMustBeAfterStartsAt => 'Ends at must be after starts at';

  @override
  String get useYyyyMmDdTHhMmSs => 'Use yyyy-MM-ddTHH:mm:ss';

  @override
  String get campaignRegistration => 'Campaign Registration';

  @override
  String get fullName => 'Full name';

  @override
  String get schoolUid => 'School UID';

  @override
  String get registration => 'Registration';

  @override
  String get myRegistrations => 'My registrations';

  @override
  String get minimum8Characters => 'Minimum 8 characters';

  @override
  String get kpiEvents => 'Events';

  @override
  String get kpiSchools => 'Schools';

  @override
  String get kpiEmployees => 'Employees';

  @override
  String get kpiInteractions => 'Interactions';

  @override
  String get interactionsByOutcome => 'Interactions by Outcome';

  @override
  String get interactionsByProvince => 'Interactions by Province';

  @override
  String get topSchools => 'Top Schools';

  @override
  String get studentRegistrations => 'Student Registrations';

  @override
  String get outcome => 'Outcome';

  @override
  String get total => 'Total';

  @override
  String get schoolUidLabel => 'UID';

  @override
  String get loadingWeather => 'Loading weather...';

  @override
  String weatherUpdatedAt(String time) {
    return 'Updated at: $time';
  }

  @override
  String feelsLike(String temp) {
    return 'Feels like $temp°C';
  }

  @override
  String get humidity => 'Humidity';

  @override
  String get wind => 'Wind';

  @override
  String get pressure => 'Pressure';

  @override
  String get visibility => 'Visibility';

  @override
  String get cachedData => 'Cached data';

  @override
  String get weatherTitle => 'Weather';

  @override
  String get kV1 => 'KV1';

  @override
  String get kV2 => 'KV2';

  @override
  String get kV2Nt => 'KV2_NT';

  @override
  String get kV3 => 'KV3';

  @override
  String get campaignsTitle => 'Campaigns';

  @override
  String get createCampaign => 'Create Campaign';

  @override
  String get searchCampaigns => 'Search campaigns';

  @override
  String get allStatuses => 'All';

  @override
  String get errorLoadingCampaigns => 'Error loading campaigns';

  @override
  String get campaignName => 'Campaign name';

  @override
  String get campaignObjective => 'Campaign objective';

  @override
  String get campaignStartDate => 'Start date';

  @override
  String get campaignEndDate => 'End date';

  @override
  String get createCampaignTitle => 'Create New Campaign';

  @override
  String get editCampaignTitle => 'Edit Campaign';

  @override
  String get saving => 'Saving...';

  @override
  String get archive => 'Archive';

  @override
  String get archived => 'Archived';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get confirmArchive => 'Confirm Archive';

  @override
  String get confirmUnarchive => 'Confirm Unarchive';

  @override
  String get settings => 'Settings';

  @override
  String get registerForEvent => 'Register for event';

  @override
  String get registerForEventSubtitle => 'Submit your information to register';

  @override
  String get yourInformation => 'Your information';

  @override
  String get schoolInformation => 'School information';

  @override
  String get searchSchool => 'Search school';

  @override
  String get className => 'Class';

  @override
  String get registrationSuccess => 'Registration submitted';

  @override
  String get pleaseSelectSchool => 'Please select a school';

  @override
  String get register => 'Register';

  @override
  String get showOnMap => 'Show on map';

  @override
  String get noSchoolsFoundHint => 'No schools found. Try a different keyword.';

  @override
  String get overview => 'Overview';

  @override
  String get profile => 'Profile';

  @override
  String get analytics => 'Analytics';

  @override
  String get registrationReview => 'Registration review';

  @override
  String get reports => 'Reports';

  @override
  String get menu => 'Menu';

  @override
  String get expand => 'Expand';

  @override
  String get collapse => 'Collapse';

  @override
  String get appearance => 'Appearance';

  @override
  String get language => 'Language';

  @override
  String get privacyAnalytics => 'Privacy & Analytics';

  @override
  String get appInformation => 'App information';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get systemTheme => 'System';

  @override
  String get allowAnalytics => 'Allow analytics';

  @override
  String get allowAnalyticsDescription =>
      'Send anonymous usage data to improve the app';

  @override
  String get analyticsDisabledDescription => 'Usage analytics is disabled';

  @override
  String get firebaseDemo => 'Firebase demo';

  @override
  String remoteConfigStatus(String google, String maintenance) {
    return 'Remote Config: Google $google · Maintenance $maintenance';
  }

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String get refreshRemoteConfig => 'Refresh Remote Config';

  @override
  String get remoteConfigRefreshed => 'Remote Config refreshed.';

  @override
  String get crashlyticsDemo => 'Crashlytics demo';

  @override
  String get crashlyticsDemoDescription =>
      'Send a non-fatal event without stopping the app.';

  @override
  String get sendNonFatalDemo => 'Send non-fatal demo';

  @override
  String get crashlyticsEventSent => 'Non-fatal event sent to Crashlytics.';

  @override
  String get crashlyticsUnavailable =>
      'Crashlytics demo is available on Android and iOS only.';

  @override
  String version(String version) {
    return 'Version $version';
  }

  @override
  String get campaignModule => 'Campaign Module';

  @override
  String get notificationManagement => 'Notification management';

  @override
  String get notificationManagementDescription =>
      'Only administrators can send notifications. Recipients see a device push and an inbox record.';

  @override
  String get notificationRecipient => 'Recipient';

  @override
  String get notificationAllUsers => 'All users';

  @override
  String get notificationSearchRecipient => 'Search by email or role';

  @override
  String get notificationCategory => 'Notification type';

  @override
  String get notificationGeneral => 'General announcement';

  @override
  String get notificationCampaignUpdate => 'Campaign update';

  @override
  String get notificationEventReminder => 'Event reminder';

  @override
  String get notificationSystemNotice => 'System notice';

  @override
  String get notificationTitle => 'Title';

  @override
  String get notificationBody => 'Message';

  @override
  String get notificationSend => 'Send notification';

  @override
  String get notificationSending => 'Sending...';

  @override
  String get notificationSent => 'Notification sent to the device.';

  @override
  String get notificationSavedNoDevice =>
      'Saved to the inbox; the recipient has no registered FCM device.';

  @override
  String get notificationTitleRequired => 'Enter a title.';

  @override
  String get notificationBodyRequired => 'Enter a message.';

  @override
  String get notificationLoadUsersFailed => 'Unable to load recipients.';

  @override
  String get notificationSendFailed =>
      'Unable to send the notification. Try again.';

  @override
  String get supportedNotifications => 'Supported notifications';

  @override
  String get supportedNotificationsDescription =>
      'Automatic pushes and administrator messages.';

  @override
  String get notifyRegistrationResult =>
      'Registration review result: approved, rejected, or cancelled';

  @override
  String get notifyCampaignCreated => 'New campaign created';

  @override
  String get notifyEventCreated => 'New event created';

  @override
  String get notifyEventAssignment => 'Staff event assignment';

  @override
  String get notifyAccountDeactivated => 'Account deactivated';

  @override
  String get notifyDailyEventReminder => 'Same-day event reminder';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationInboxDescription =>
      'Notifications sent to your account are stored here.';

  @override
  String get noNotifications => 'No notifications yet';

  @override
  String get markAllNotificationsRead => 'Mark all read';

  @override
  String get allNotificationsRead => 'All notifications marked as read.';

  @override
  String get notificationLoadFailed => 'Unable to load notifications.';

  @override
  String get notificationJustNow => 'Just now';

  @override
  String get attendance => 'Attendance';

  @override
  String get checkIn => 'Check in';

  @override
  String get checkOut => 'Check out';

  @override
  String get openSession => 'Currently checked in';

  @override
  String get noOpenSession => 'Not checked in';

  @override
  String get workedHours => 'Worked hours';

  @override
  String get attendanceCorrectionNote => 'Correction note';

  @override
  String get alreadyCheckedIn => 'You are already checked in';

  @override
  String get noOpenSessionToCheckOut => 'No open session to check out';

  @override
  String get employeeNotLinked =>
      'Your account is not linked to an employee record';

  @override
  String get noActiveCampaign => 'No campaign is currently open';

  @override
  String get campaignNotOpenForCheckIn =>
      'This campaign is not open for check-in';

  @override
  String get selectCampaign => 'Select campaign';

  @override
  String get selectEventOptional => 'Select event (optional)';

  @override
  String get checkInSuccess => 'Check-in recorded successfully';

  @override
  String get checkOutSuccess => 'Check-out recorded successfully';

  @override
  String get confirmCheckOut => 'Confirm check-out';

  @override
  String get confirmCheckOutMessage =>
      'Check out now? The end time will be recorded immediately.';

  @override
  String get notAssignedAttendanceTarget =>
      'You are not assigned to this campaign event';

  @override
  String get noAssignedAttendanceTarget =>
      'No assigned campaign event is currently open for check-in';

  @override
  String get attendanceActionFailed =>
      'Unable to update attendance. Your latest status will be reloaded.';

  @override
  String get attendanceLoadFailed =>
      'Unable to load your current attendance status.';

  @override
  String get attendanceTargetsLoadFailed =>
      'Unable to load assigned campaign events.';

  @override
  String get correctionReason => 'Correction reason';

  @override
  String get deleteReason => 'Reason for removal';

  @override
  String get reasonRequired => 'Please provide a reason';

  @override
  String get clearCheckOutTime => 'Clear check-out time';

  @override
  String get attendanceReport => 'Attendance Report';

  @override
  String get attendanceReportSubtitle =>
      'Summary of work hours, check-in/out by employee, campaign, date range';

  @override
  String get totalRecords => 'Total records';

  @override
  String get totalWorkHours => 'Total work hours';

  @override
  String get avgHoursPerDay => 'Avg hours/day';

  @override
  String get openSessions => 'Open sessions';

  @override
  String get hoursByEmployee => 'Work hours by employee';

  @override
  String get checkInsByDay => 'Check-ins by day';

  @override
  String get generateReport => 'Generate report';

  @override
  String get attendanceDetails => 'Attendance details';

  @override
  String get attendanceSubtitle =>
      'Track your shift and review recent attendance.';

  @override
  String get attendanceReadyTitle => 'Ready to start your shift?';

  @override
  String get attendanceRecentShifts => 'Recent shifts';

  @override
  String get attendanceNoRecentShifts => 'No completed shifts yet';

  @override
  String get attendanceNoRecentShiftsHint =>
      'Your completed shifts will appear here.';

  @override
  String get attendanceShiftDetails => 'Shift details';

  @override
  String get attendanceStartedAt => 'Started at';

  @override
  String get attendanceEndedAt => 'Ended at';

  @override
  String get attendanceDuration => 'Duration';

  @override
  String get attendanceStatusOpen => 'Shift in progress';

  @override
  String get attendanceStatusClosed => 'Shift completed';

  @override
  String get attendanceAddNote => 'Add a note';

  @override
  String get attendanceHideNote => 'Hide note';

  @override
  String get attendanceNoEvent => 'No specific event';

  @override
  String get attendanceEndShift => 'End shift';

  @override
  String get attendanceKeepWorking => 'Keep working';

  @override
  String get attendanceViewShiftDetails => 'View shift details';

  @override
  String get attendanceCheckoutPrompt =>
      'Review this shift before recording your check-out.';

  @override
  String get attendanceRecordedAt => 'Recorded at';

  @override
  String get attendanceTeamTitle => 'Team attendance';

  @override
  String get attendanceStatusAll => 'All statuses';

  @override
  String get attendanceStatusOpenLabel => 'In progress';

  @override
  String get attendanceStatusClosedLabel => 'Completed';

  @override
  String get attendanceLoadingStatus => 'Loading your attendance status...';

  @override
  String get attendanceLoadingTargets => 'Loading assigned campaigns...';

  @override
  String get attendanceNoTeamRecords => 'No team attendance found';

  @override
  String get attendanceNoTeamRecordsHint =>
      'Try another status or refresh the list.';

  @override
  String get close => 'Close';
}
