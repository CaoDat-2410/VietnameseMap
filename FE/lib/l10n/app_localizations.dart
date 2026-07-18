import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('vi'),
    Locale('en')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Vietnam Map'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @map.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get map;

  /// No description provided for @weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weather;

  /// No description provided for @campaigns.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaigns;

  /// No description provided for @campaign.
  ///
  /// In en, this message translates to:
  /// **'Campaign'**
  String get campaign;

  /// No description provided for @events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get events;

  /// No description provided for @schools.
  ///
  /// In en, this message translates to:
  /// **'Schools'**
  String get schools;

  /// No description provided for @school.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get school;

  /// No description provided for @users.
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get users;

  /// No description provided for @mine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get mine;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @accessDenied.
  ///
  /// In en, this message translates to:
  /// **'Access denied'**
  String get accessDenied;

  /// No description provided for @noPermission.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to view this page.'**
  String get noPermission;

  /// No description provided for @signInToContinue.
  ///
  /// In en, this message translates to:
  /// **'Sign in to continue with your assigned role'**
  String get signInToContinue;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @signingIn.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get signingIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @assign.
  ///
  /// In en, this message translates to:
  /// **'Assign'**
  String get assign;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @submitRegistration.
  ///
  /// In en, this message translates to:
  /// **'Submit registration'**
  String get submitRegistration;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @page.
  ///
  /// In en, this message translates to:
  /// **'Page {page} / {total}'**
  String page(int page, int total);

  /// No description provided for @showingOf.
  ///
  /// In en, this message translates to:
  /// **'Showing {count} of {total}'**
  String showingOf(int count, int total);

  /// No description provided for @noCampaignsYet.
  ///
  /// In en, this message translates to:
  /// **'No campaigns yet'**
  String get noCampaignsYet;

  /// No description provided for @noEventsYet.
  ///
  /// In en, this message translates to:
  /// **'No events yet'**
  String get noEventsYet;

  /// No description provided for @noSchoolsFound.
  ///
  /// In en, this message translates to:
  /// **'No schools found'**
  String get noSchoolsFound;

  /// No description provided for @noStudents.
  ///
  /// In en, this message translates to:
  /// **'No students'**
  String get noStudents;

  /// No description provided for @noTeachersPersons.
  ///
  /// In en, this message translates to:
  /// **'No teachers/persons'**
  String get noTeachersPersons;

  /// No description provided for @noRelatives.
  ///
  /// In en, this message translates to:
  /// **'No relatives'**
  String get noRelatives;

  /// No description provided for @noEmployees.
  ///
  /// In en, this message translates to:
  /// **'No employees'**
  String get noEmployees;

  /// No description provided for @noRegistrationsYet.
  ///
  /// In en, this message translates to:
  /// **'No registrations yet'**
  String get noRegistrationsYet;

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @campaignCreated.
  ///
  /// In en, this message translates to:
  /// **'Campaign created'**
  String get campaignCreated;

  /// No description provided for @campaignSaved.
  ///
  /// In en, this message translates to:
  /// **'Campaign saved'**
  String get campaignSaved;

  /// No description provided for @eventSaved.
  ///
  /// In en, this message translates to:
  /// **'Event saved'**
  String get eventSaved;

  /// No description provided for @schoolAssigned.
  ///
  /// In en, this message translates to:
  /// **'School assigned'**
  String get schoolAssigned;

  /// No description provided for @schoolRemoved.
  ///
  /// In en, this message translates to:
  /// **'School removed'**
  String get schoolRemoved;

  /// No description provided for @employeeAssigned.
  ///
  /// In en, this message translates to:
  /// **'Employee assigned'**
  String get employeeAssigned;

  /// No description provided for @employeeRemoved.
  ///
  /// In en, this message translates to:
  /// **'Employee removed'**
  String get employeeRemoved;

  /// No description provided for @registrationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Registration submitted'**
  String get registrationSubmitted;

  /// No description provided for @campaignDashboard.
  ///
  /// In en, this message translates to:
  /// **'Campaign Dashboard'**
  String get campaignDashboard;

  /// No description provided for @campaignEvents.
  ///
  /// In en, this message translates to:
  /// **'Campaign Events'**
  String get campaignEvents;

  /// No description provided for @createEvent.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEvent;

  /// No description provided for @eventDetail.
  ///
  /// In en, this message translates to:
  /// **'Event Detail'**
  String get eventDetail;

  /// No description provided for @thongTin.
  ///
  /// In en, this message translates to:
  /// **'Information'**
  String get thongTin;

  /// No description provided for @truongThamGia.
  ///
  /// In en, this message translates to:
  /// **'Participating Schools'**
  String get truongThamGia;

  /// No description provided for @nhanSu.
  ///
  /// In en, this message translates to:
  /// **'Staff'**
  String get nhanSu;

  /// No description provided for @interactions.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get interactions;

  /// No description provided for @assignedSchools.
  ///
  /// In en, this message translates to:
  /// **'Assigned schools'**
  String get assignedSchools;

  /// No description provided for @findSchools.
  ///
  /// In en, this message translates to:
  /// **'Find schools'**
  String get findSchools;

  /// No description provided for @assignedEmployees.
  ///
  /// In en, this message translates to:
  /// **'Assigned employees'**
  String get assignedEmployees;

  /// No description provided for @employees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// No description provided for @noAssignedSchools.
  ///
  /// In en, this message translates to:
  /// **'No assigned schools'**
  String get noAssignedSchools;

  /// No description provided for @noAssignedEmployees.
  ///
  /// In en, this message translates to:
  /// **'No assigned employees'**
  String get noAssignedEmployees;

  /// No description provided for @schoolDetail.
  ///
  /// In en, this message translates to:
  /// **'School Detail'**
  String get schoolDetail;

  /// No description provided for @tongQuan.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get tongQuan;

  /// No description provided for @hocSinh.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get hocSinh;

  /// No description provided for @gvBgh.
  ///
  /// In en, this message translates to:
  /// **'Teachers/Staff'**
  String get gvBgh;

  /// No description provided for @nguoiThan.
  ///
  /// In en, this message translates to:
  /// **'Relatives'**
  String get nguoiThan;

  /// No description provided for @province.
  ///
  /// In en, this message translates to:
  /// **'Province'**
  String get province;

  /// No description provided for @provinceCode.
  ///
  /// In en, this message translates to:
  /// **'Province code'**
  String get provinceCode;

  /// No description provided for @commune.
  ///
  /// In en, this message translates to:
  /// **'Commune'**
  String get commune;

  /// No description provided for @communeCode.
  ///
  /// In en, this message translates to:
  /// **'Commune code'**
  String get communeCode;

  /// No description provided for @schoolCode.
  ///
  /// In en, this message translates to:
  /// **'School code'**
  String get schoolCode;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @area.
  ///
  /// In en, this message translates to:
  /// **'Area'**
  String get area;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @grade.
  ///
  /// In en, this message translates to:
  /// **'Grade'**
  String get grade;

  /// No description provided for @classLabel.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get classLabel;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get end;

  /// No description provided for @owner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get owner;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @startsAt.
  ///
  /// In en, this message translates to:
  /// **'Starts at'**
  String get startsAt;

  /// No description provided for @endsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at'**
  String get endsAt;

  /// No description provided for @viewOnFullMap.
  ///
  /// In en, this message translates to:
  /// **'View on full map'**
  String get viewOnFullMap;

  /// No description provided for @createEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Event'**
  String get createEventTitle;

  /// No description provided for @editEventTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get editEventTitle;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get eventType;

  /// No description provided for @locationLabel.
  ///
  /// In en, this message translates to:
  /// **'Address label'**
  String get locationLabel;

  /// No description provided for @pickOnMap.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pickOnMap;

  /// No description provided for @noLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'No location selected'**
  String get noLocationSelected;

  /// No description provided for @noSchoolsAssigned.
  ///
  /// In en, this message translates to:
  /// **'No schools assigned yet. Assign schools in the Schools tab to enable auto-location, or drop a pin manually below.'**
  String get noSchoolsAssigned;

  /// No description provided for @provinceCenterLocation.
  ///
  /// In en, this message translates to:
  /// **'Using province center as approximate location - drag the pin to refine.'**
  String get provinceCenterLocation;

  /// No description provided for @endsAtMustBeAfterStartsAt.
  ///
  /// In en, this message translates to:
  /// **'Ends at must be after starts at'**
  String get endsAtMustBeAfterStartsAt;

  /// No description provided for @useYyyyMmDdTHhMmSs.
  ///
  /// In en, this message translates to:
  /// **'Use yyyy-MM-ddTHH:mm:ss'**
  String get useYyyyMmDdTHhMmSs;

  /// No description provided for @campaignRegistration.
  ///
  /// In en, this message translates to:
  /// **'Campaign Registration'**
  String get campaignRegistration;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @schoolUid.
  ///
  /// In en, this message translates to:
  /// **'School UID'**
  String get schoolUid;

  /// No description provided for @registration.
  ///
  /// In en, this message translates to:
  /// **'Registration'**
  String get registration;

  /// No description provided for @myRegistrations.
  ///
  /// In en, this message translates to:
  /// **'My registrations'**
  String get myRegistrations;

  /// No description provided for @minimum8Characters.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get minimum8Characters;

  /// No description provided for @kpiEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get kpiEvents;

  /// No description provided for @kpiSchools.
  ///
  /// In en, this message translates to:
  /// **'Schools'**
  String get kpiSchools;

  /// No description provided for @kpiEmployees.
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get kpiEmployees;

  /// No description provided for @kpiInteractions.
  ///
  /// In en, this message translates to:
  /// **'Interactions'**
  String get kpiInteractions;

  /// No description provided for @interactionsByOutcome.
  ///
  /// In en, this message translates to:
  /// **'Interactions by Outcome'**
  String get interactionsByOutcome;

  /// No description provided for @interactionsByProvince.
  ///
  /// In en, this message translates to:
  /// **'Interactions by Province'**
  String get interactionsByProvince;

  /// No description provided for @topSchools.
  ///
  /// In en, this message translates to:
  /// **'Top Schools'**
  String get topSchools;

  /// No description provided for @studentRegistrations.
  ///
  /// In en, this message translates to:
  /// **'Student Registrations'**
  String get studentRegistrations;

  /// No description provided for @outcome.
  ///
  /// In en, this message translates to:
  /// **'Outcome'**
  String get outcome;

  /// No description provided for @total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @schoolUidLabel.
  ///
  /// In en, this message translates to:
  /// **'UID'**
  String get schoolUidLabel;

  /// No description provided for @loadingWeather.
  ///
  /// In en, this message translates to:
  /// **'Loading weather...'**
  String get loadingWeather;

  /// No description provided for @weatherUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated at: {time}'**
  String weatherUpdatedAt(String time);

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temp}°C'**
  String feelsLike(String temp);

  /// No description provided for @humidity.
  ///
  /// In en, this message translates to:
  /// **'Humidity'**
  String get humidity;

  /// No description provided for @wind.
  ///
  /// In en, this message translates to:
  /// **'Wind'**
  String get wind;

  /// No description provided for @pressure.
  ///
  /// In en, this message translates to:
  /// **'Pressure'**
  String get pressure;

  /// No description provided for @visibility.
  ///
  /// In en, this message translates to:
  /// **'Visibility'**
  String get visibility;

  /// No description provided for @cachedData.
  ///
  /// In en, this message translates to:
  /// **'Cached data'**
  String get cachedData;

  /// No description provided for @weatherTitle.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get weatherTitle;

  /// No description provided for @kV1.
  ///
  /// In en, this message translates to:
  /// **'KV1'**
  String get kV1;

  /// No description provided for @kV2.
  ///
  /// In en, this message translates to:
  /// **'KV2'**
  String get kV2;

  /// No description provided for @kV2Nt.
  ///
  /// In en, this message translates to:
  /// **'KV2_NT'**
  String get kV2Nt;

  /// No description provided for @kV3.
  ///
  /// In en, this message translates to:
  /// **'KV3'**
  String get kV3;

  /// No description provided for @campaignsTitle.
  ///
  /// In en, this message translates to:
  /// **'Campaigns'**
  String get campaignsTitle;

  /// No description provided for @createCampaign.
  ///
  /// In en, this message translates to:
  /// **'Create Campaign'**
  String get createCampaign;

  /// No description provided for @searchCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Search campaigns'**
  String get searchCampaigns;

  /// No description provided for @allStatuses.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get allStatuses;

  /// No description provided for @errorLoadingCampaigns.
  ///
  /// In en, this message translates to:
  /// **'Error loading campaigns'**
  String get errorLoadingCampaigns;

  /// No description provided for @campaignName.
  ///
  /// In en, this message translates to:
  /// **'Campaign name'**
  String get campaignName;

  /// No description provided for @campaignObjective.
  ///
  /// In en, this message translates to:
  /// **'Campaign objective'**
  String get campaignObjective;

  /// No description provided for @campaignStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get campaignStartDate;

  /// No description provided for @campaignEndDate.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get campaignEndDate;

  /// No description provided for @createCampaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Create New Campaign'**
  String get createCampaignTitle;

  /// No description provided for @editCampaignTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Campaign'**
  String get editCampaignTitle;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @archived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get archived;

  /// No description provided for @unarchive.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// No description provided for @confirmDelete.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// No description provided for @confirmArchive.
  ///
  /// In en, this message translates to:
  /// **'Confirm Archive'**
  String get confirmArchive;

  /// No description provided for @confirmUnarchive.
  ///
  /// In en, this message translates to:
  /// **'Confirm Unarchive'**
  String get confirmUnarchive;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @registerForEvent.
  ///
  /// In en, this message translates to:
  /// **'Register for event'**
  String get registerForEvent;

  /// No description provided for @registerForEventSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Submit your information to register'**
  String get registerForEventSubtitle;

  /// No description provided for @yourInformation.
  ///
  /// In en, this message translates to:
  /// **'Your information'**
  String get yourInformation;

  /// No description provided for @schoolInformation.
  ///
  /// In en, this message translates to:
  /// **'School information'**
  String get schoolInformation;

  /// No description provided for @searchSchool.
  ///
  /// In en, this message translates to:
  /// **'Search school'**
  String get searchSchool;

  /// No description provided for @className.
  ///
  /// In en, this message translates to:
  /// **'Class'**
  String get className;

  /// No description provided for @registrationSuccess.
  ///
  /// In en, this message translates to:
  /// **'Registration submitted'**
  String get registrationSuccess;

  /// No description provided for @pleaseSelectSchool.
  ///
  /// In en, this message translates to:
  /// **'Please select a school'**
  String get pleaseSelectSchool;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get showOnMap;

  /// No description provided for @noSchoolsFoundHint.
  ///
  /// In en, this message translates to:
  /// **'No schools found. Try a different keyword.'**
  String get noSchoolsFoundHint;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @registrationReview.
  ///
  /// In en, this message translates to:
  /// **'Registration review'**
  String get registrationReview;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @menu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get menu;

  /// No description provided for @expand.
  ///
  /// In en, this message translates to:
  /// **'Expand'**
  String get expand;

  /// No description provided for @collapse.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapse;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @privacyAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Analytics'**
  String get privacyAnalytics;

  /// No description provided for @appInformation.
  ///
  /// In en, this message translates to:
  /// **'App information'**
  String get appInformation;

  /// No description provided for @lightTheme.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get darkTheme;

  /// No description provided for @systemTheme.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get systemTheme;

  /// No description provided for @allowAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Allow analytics'**
  String get allowAnalytics;

  /// No description provided for @allowAnalyticsDescription.
  ///
  /// In en, this message translates to:
  /// **'Send anonymous usage data to improve the app'**
  String get allowAnalyticsDescription;

  /// No description provided for @analyticsDisabledDescription.
  ///
  /// In en, this message translates to:
  /// **'Usage analytics is disabled'**
  String get analyticsDisabledDescription;

  /// No description provided for @firebaseDemo.
  ///
  /// In en, this message translates to:
  /// **'Firebase demo'**
  String get firebaseDemo;

  /// No description provided for @remoteConfigStatus.
  ///
  /// In en, this message translates to:
  /// **'Remote Config: Google {google} · Maintenance {maintenance}'**
  String remoteConfigStatus(String google, String maintenance);

  /// No description provided for @enabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get enabled;

  /// No description provided for @disabled.
  ///
  /// In en, this message translates to:
  /// **'Disabled'**
  String get disabled;

  /// No description provided for @refreshRemoteConfig.
  ///
  /// In en, this message translates to:
  /// **'Refresh Remote Config'**
  String get refreshRemoteConfig;

  /// No description provided for @remoteConfigRefreshed.
  ///
  /// In en, this message translates to:
  /// **'Remote Config refreshed.'**
  String get remoteConfigRefreshed;

  /// No description provided for @crashlyticsDemo.
  ///
  /// In en, this message translates to:
  /// **'Crashlytics demo'**
  String get crashlyticsDemo;

  /// No description provided for @crashlyticsDemoDescription.
  ///
  /// In en, this message translates to:
  /// **'Send a non-fatal event without stopping the app.'**
  String get crashlyticsDemoDescription;

  /// No description provided for @sendNonFatalDemo.
  ///
  /// In en, this message translates to:
  /// **'Send non-fatal demo'**
  String get sendNonFatalDemo;

  /// No description provided for @crashlyticsEventSent.
  ///
  /// In en, this message translates to:
  /// **'Non-fatal event sent to Crashlytics.'**
  String get crashlyticsEventSent;

  /// No description provided for @crashlyticsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Crashlytics demo is available on Android and iOS only.'**
  String get crashlyticsUnavailable;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String version(String version);

  /// No description provided for @campaignModule.
  ///
  /// In en, this message translates to:
  /// **'Campaign Module'**
  String get campaignModule;

  /// No description provided for @notificationManagement.
  ///
  /// In en, this message translates to:
  /// **'Notification management'**
  String get notificationManagement;

  /// No description provided for @notificationManagementDescription.
  ///
  /// In en, this message translates to:
  /// **'Only administrators can send notifications. Recipients see a device push and an inbox record.'**
  String get notificationManagementDescription;

  /// No description provided for @notificationRecipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get notificationRecipient;

  /// No description provided for @notificationAllUsers.
  ///
  /// In en, this message translates to:
  /// **'All users'**
  String get notificationAllUsers;

  /// No description provided for @notificationSearchRecipient.
  ///
  /// In en, this message translates to:
  /// **'Search by email or role'**
  String get notificationSearchRecipient;

  /// No description provided for @notificationCategory.
  ///
  /// In en, this message translates to:
  /// **'Notification type'**
  String get notificationCategory;

  /// No description provided for @notificationGeneral.
  ///
  /// In en, this message translates to:
  /// **'General announcement'**
  String get notificationGeneral;

  /// No description provided for @notificationCampaignUpdate.
  ///
  /// In en, this message translates to:
  /// **'Campaign update'**
  String get notificationCampaignUpdate;

  /// No description provided for @notificationEventReminder.
  ///
  /// In en, this message translates to:
  /// **'Event reminder'**
  String get notificationEventReminder;

  /// No description provided for @notificationSystemNotice.
  ///
  /// In en, this message translates to:
  /// **'System notice'**
  String get notificationSystemNotice;

  /// No description provided for @notificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get notificationTitle;

  /// No description provided for @notificationBody.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get notificationBody;

  /// No description provided for @notificationSend.
  ///
  /// In en, this message translates to:
  /// **'Send notification'**
  String get notificationSend;

  /// No description provided for @notificationSending.
  ///
  /// In en, this message translates to:
  /// **'Sending...'**
  String get notificationSending;

  /// No description provided for @notificationSent.
  ///
  /// In en, this message translates to:
  /// **'Notification sent to the device.'**
  String get notificationSent;

  /// No description provided for @notificationSavedNoDevice.
  ///
  /// In en, this message translates to:
  /// **'Saved to the inbox; the recipient has no registered FCM device.'**
  String get notificationSavedNoDevice;

  /// No description provided for @notificationTitleRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a title.'**
  String get notificationTitleRequired;

  /// No description provided for @notificationBodyRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a message.'**
  String get notificationBodyRequired;

  /// No description provided for @notificationLoadUsersFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load recipients.'**
  String get notificationLoadUsersFailed;

  /// No description provided for @notificationSendFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to send the notification. Try again.'**
  String get notificationSendFailed;

  /// No description provided for @supportedNotifications.
  ///
  /// In en, this message translates to:
  /// **'Supported notifications'**
  String get supportedNotifications;

  /// No description provided for @supportedNotificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Automatic pushes and administrator messages.'**
  String get supportedNotificationsDescription;

  /// No description provided for @notifyRegistrationResult.
  ///
  /// In en, this message translates to:
  /// **'Registration review result: approved, rejected, or cancelled'**
  String get notifyRegistrationResult;

  /// No description provided for @notifyCampaignCreated.
  ///
  /// In en, this message translates to:
  /// **'New campaign created'**
  String get notifyCampaignCreated;

  /// No description provided for @notifyEventCreated.
  ///
  /// In en, this message translates to:
  /// **'New event created'**
  String get notifyEventCreated;

  /// No description provided for @notifyEventAssignment.
  ///
  /// In en, this message translates to:
  /// **'Staff event assignment'**
  String get notifyEventAssignment;

  /// No description provided for @notifyAccountDeactivated.
  ///
  /// In en, this message translates to:
  /// **'Account deactivated'**
  String get notifyAccountDeactivated;

  /// No description provided for @notifyDailyEventReminder.
  ///
  /// In en, this message translates to:
  /// **'Same-day event reminder'**
  String get notifyDailyEventReminder;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationInboxDescription.
  ///
  /// In en, this message translates to:
  /// **'Notifications sent to your account are stored here.'**
  String get notificationInboxDescription;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get noNotifications;

  /// No description provided for @markAllNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all read'**
  String get markAllNotificationsRead;

  /// No description provided for @allNotificationsRead.
  ///
  /// In en, this message translates to:
  /// **'All notifications marked as read.'**
  String get allNotificationsRead;

  /// No description provided for @notificationLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load notifications.'**
  String get notificationLoadFailed;

  /// No description provided for @notificationJustNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get notificationJustNow;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
