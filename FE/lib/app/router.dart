import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'widgets/app_sidebar.dart';
import 'widgets/app_shell_scaffold.dart';
import '../core/monitoring/navigation_observer.dart';
import '../features/admin/presentation/pages/admin_users_page.dart';
import '../features/analytics/presentation/pages/analytics_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/logout_page.dart';
import '../features/auth/shared/auth_routes.dart';
import '../features/auth/shared/providers/auth_provider.dart';
import '../features/auth/shared/token_storage.dart';
import '../features/campaign/dashboard/pages/campaign_dashboard_page.dart';
import '../features/campaign/dashboard/pages/campaign_list_page.dart';
import '../features/campaign/events/pages/campaign_events_page.dart';
import '../features/campaign/events/pages/event_detail_page.dart';
import '../features/home/presentation/pages/manager_home_page.dart';
import '../features/home/presentation/pages/staff_home_page.dart';
import '../features/home/presentation/pages/student_home_page.dart';
import '../features/home/presentation/pages/admin_home_page.dart';
import '../features/map/presentation/pages/map_page.dart';
import '../features/school/presentation/pages/school_detail_page.dart';
import '../features/school/presentation/pages/school_list_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/student/presentation/pages/my_registrations_page.dart';
import '../features/student/presentation/pages/student_register_page.dart';
import '../features/weather/presentation/pages/weather_page.dart';
import '../l10n/app_localizations.dart';

// Smooth page transition for better UX
CustomTransitionPage<void> _buildPageWithSlideTransition({
  required BuildContext context,
  required Widget child,
  required GoRouterState state,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Slide from right with fade
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      final fadeTween = Tween(begin: 0.0, end: 1.0);

      return SlideTransition(
        position: animation.drive(tween),
        child: FadeTransition(
          opacity: animation.drive(fadeTween),
          child: child,
        ),
      );
    },
  );
}

/// Arguments parsed from a `/map` URL — used by both the narrow-screen
/// `MapPage` and the wide-screen `_AppShell` so the map receives the same
/// focus/selection data on every viewport width.
class MapRouteArgs {
  const MapRouteArgs({
    this.focusLat,
    this.focusLng,
    this.focusLabel,
    this.schoolUids,
  });
  final double? focusLat;
  final double? focusLng;
  final String? focusLabel;
  final List<String>? schoolUids;
}

MapRouteArgs parseMapArgs(Uri uri) {
  final params = uri.queryParameters;
  final lat = double.tryParse(params['lat'] ?? '');
  final lng = double.tryParse(params['lng'] ?? '');
  final label = params['eventName'];
  final schoolsParam = params['schools'];
  List<String>? schoolUids;
  if (schoolsParam != null && schoolsParam.isNotEmpty) {
    schoolUids =
        schoolsParam.split(',').where((s) => s.isNotEmpty).toList();
  }
  return MapRouteArgs(
    focusLat: lat,
    focusLng: lng,
    focusLabel: (label == null || label.isEmpty) ? null : label,
    schoolUids: schoolUids,
  );
}

final router = GoRouter(
  initialLocation: '/login',
  observers: [
    AnalyticsNavigationObserver(),
  ],
  redirect: (context, state) async {
    final path = state.uri.path;
    if (path == '/' || path.startsWith('/province/')) return '/map';
    final hasToken =
        (await TokenStorage().readAccessToken())?.isNotEmpty == true;

    // Always allow /login, /logout, and student self-registration links.
    final isAlwaysPublic = path == '/login' ||
        path == '/logout' ||
        path.startsWith('/student/register/');

    if (isAlwaysPublic) {
      // If user is already signed in, skip the login screen and go to landing.
      if (hasToken && path == '/login') {
        final token = await TokenStorage().readAccessToken();
        return landingPathForRole(_roleFromAccessToken(token));
      }
      return null;
    }

    // Everything else requires a token.
    if (!hasToken) return '/login';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(
        child: LoginPage(),
      ),
    ),
    GoRoute(
      path: '/student/register/:campaignId',
      pageBuilder: (context, state) => NoTransitionPage(
        child: StudentRegisterPage(
          campaignId: int.parse(state.pathParameters['campaignId']!),
        ),
      ),
    ),
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) {
            final args = parseMapArgs(state.uri);
            return _buildPageWithSlideTransition(
              context: context,
              state: state,
              child: MapPage(
                focusLat: args.focusLat,
                focusLng: args.focusLng,
                focusLabel: args.focusLabel,
                schoolUids: args.schoolUids,
              ),
            );
          },
        ),
        GoRoute(
          path: '/weather',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const WeatherPage(),
          ),
        ),
        GoRoute(
          path: '/campaigns',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: {'STAFF', 'MANAGER', 'ADMIN'},
              child: const CampaignListPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/campaigns/:campaignId/dashboard',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
              child: CampaignDashboardPage(
                campaignId: int.parse(state.pathParameters['campaignId']!),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
              child: const AnalyticsPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/campaigns/:campaignId/events',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
              child: CampaignEventsPage(
                campaignId: int.parse(state.pathParameters['campaignId']!),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/events/:eventId',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
              child: EventDetailPage(
                eventId: int.parse(state.pathParameters['eventId']!),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/schools',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: {'STAFF', 'MANAGER', 'ADMIN'},
              child: const SchoolListPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/schools/:schoolUid',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
              child: SchoolDetailPage(
                schoolUid: state.pathParameters['schoolUid']!,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/student/my-registrations',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: {'STUDENT'},
              child: const MyRegistrationsPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/users',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: {'ADMIN'},
              child: const AdminUsersPage(),
            ),
          ),
        ),
        // Role-specific home pages
        GoRoute(
          path: '/home/manager',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: {'MANAGER', 'ADMIN'},
              child: const ManagerHomePage(),
            ),
          ),
        ),
        GoRoute(
          path: '/home/staff',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: {'STAFF', 'MANAGER', 'ADMIN'},
              child: const StaffHomePage(),
            ),
          ),
        ),
        GoRoute(
          path: '/home/student',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: {'STUDENT'},
              child: const StudentHomePage(),
            ),
          ),
        ),
        GoRoute(
          path: '/home/admin',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: _RoleGate(
              allowedRoles: {'ADMIN'},
              child: const AdminHomePage(),
            ),
          ),
        ),
        GoRoute(
          path: '/logout',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LogoutPage(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => _buildPageWithSlideTransition(
            context: context,
            state: state,
            child: const SettingsPage(),
          ),
        ),
      ],
    ),
  ],
);

class _AppShell extends ConsumerWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final location = GoRouterState.of(context).uri.path;
    final user = ref.watch(activeUserProvider).valueOrNull;
    final rawItems = _navItemsFor(user?.role, l10n);
    final items = rawItems.map(navItemFrom).toList();
    final activePath = _activeNavPath(location);

    return AppShellScaffold(
      items: items,
      selectedPath: activePath,
      onSelected: (item) => context.go(item.path),
      body: child,
    );
  }

  String _activeNavPath(String location) {
    if (location.startsWith('/login')) return '/login';
    if (location.startsWith('/logout')) return '/logout';
    if (location.startsWith('/settings')) return '/settings';
    if (location.startsWith('/campaigns') || location.startsWith('/events')) {
      return '/campaigns';
    }
    if (location.startsWith('/schools')) return '/schools';
    if (location.startsWith('/student/my-registrations')) {
      return '/student/my-registrations';
    }
    if (location.startsWith('/admin/users')) return '/admin/users';
    if (location.startsWith('/home/')) {
      return location; // Return the actual role-specific path so sidebar highlights correctly
    }
    if (location.startsWith('/weather')) return '/map';
    return '/map';
  }

  String _homePathFor(String? role) => switch (role) {
    'MANAGER' => '/home/manager',
    'ADMIN'   => '/home/admin',
    'STAFF'   => '/home/staff',
    'STUDENT' => '/home/student',
    _         => '/home/staff',
  };

  List<_NavItem> _navItemsFor(String? role, AppLocalizations l10n) {
    final items = <_NavItem>[];

    // Home item for logged-in users
    if (role != null) {
      items.add(_NavItem(
        _homePathFor(role),
        'Tổng quan',
        Icons.dashboard_outlined,
        Icons.dashboard,
      ));
    }

    items.add(_NavItem('/map', l10n.map, Icons.map_outlined, Icons.map));

    if (role == null) {
      items.add(
          _NavItem('/settings', l10n.settings, Icons.settings_outlined, Icons.settings));
      items.add(
          _NavItem('/login', l10n.login, Icons.login_outlined, Icons.login));
      return items;
    }

    if (role == 'STUDENT') {
      items.add(_NavItem('/student/my-registrations', l10n.mine,
          Icons.assignment_ind_outlined, Icons.assignment_ind));
      items.add(_NavItem('/settings', l10n.settings,
          Icons.settings_outlined, Icons.settings));
      items.add(_NavItem(
          '/logout', l10n.logout, Icons.logout_outlined, Icons.logout));
      return items;
    }

    if (role == 'STAFF' || role == 'MANAGER' || role == 'ADMIN') {
      items.add(_NavItem(
          '/campaigns', l10n.campaigns, Icons.campaign_outlined, Icons.campaign));
      items.add(_NavItem(
          '/analytics', 'Analytics', Icons.analytics_outlined, Icons.analytics));
      items.add(_NavItem(
          '/schools', l10n.schools, Icons.school_outlined, Icons.school));
    }
    if (role == 'ADMIN') {
      items.add(_NavItem('/admin/users', l10n.users,
          Icons.admin_panel_settings_outlined, Icons.admin_panel_settings));
    }
    items.add(_NavItem('/settings', l10n.settings,
        Icons.settings_outlined, Icons.settings));
    items.add(_NavItem(
        '/logout', l10n.logout, Icons.logout_outlined, Icons.logout));
    return items;
  }
}

class _RoleGate extends ConsumerWidget {
  const _RoleGate({
    required this.allowedRoles,
    required this.child,
  });

  final Set<String> allowedRoles;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(activeUserProvider);
    return user.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Unable to load current user: $error')),
      ),
      data: (value) {
        if (value != null && allowedRoles.contains(value.role)) {
          return child;
        }
        return Scaffold(
          appBar: AppBar(title: Text(l10n.accessDenied)),
          body: Center(
            child: Text(l10n.noPermission),
          ),
        );
      },
    );
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

String? _roleFromAccessToken(String? token) {
  if (token == null || token.isEmpty) return null;
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return json['role'] as String?;
  } catch (_) {
    return null;
  }
}
