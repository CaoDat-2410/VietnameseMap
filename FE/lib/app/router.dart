import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/admin/presentation/pages/admin_users_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/logout_page.dart';
import '../features/auth/shared/auth_routes.dart';
import '../features/auth/shared/providers/auth_provider.dart';
import '../features/auth/shared/token_storage.dart';
import '../features/campaign/dashboard/pages/campaign_dashboard_page.dart';
import '../features/campaign/dashboard/pages/campaign_list_page.dart';
import '../features/campaign/events/pages/campaign_events_page.dart';
import '../features/campaign/events/pages/event_detail_page.dart';
import '../features/campaign/presentation/pages/campaigns_temp_page.dart';
import '../features/map/presentation/pages/map_page.dart';
import '../features/map/presentation/widgets/vietnam_map_view.dart';
import '../features/school/presentation/pages/school_detail_page.dart';
import '../features/school/presentation/pages/school_list_page.dart';
import '../features/school/presentation/pages/schools_temp_page.dart';
import '../features/student/presentation/pages/my_registrations_page.dart';
import '../features/student/presentation/pages/student_register_page.dart';
import '../features/weather/presentation/pages/weather_page.dart';

final router = GoRouter(
  initialLocation: '/map',
  redirect: (context, state) async {
    if (state.uri.path == '/') return '/map';
    if (state.uri.path.startsWith('/province/')) return '/map';
    final path = state.uri.path;
    final isPublic = path == '/login' ||
        path == '/map' ||
        path == '/weather' ||
        path == '/logout' ||
        path.startsWith('/student/register/');
    final hasToken =
        (await TokenStorage().readAccessToken())?.isNotEmpty == true;
    if (!hasToken && !isPublic) return '/login';
    if (hasToken && path == '/login') {
      final token = await TokenStorage().readAccessToken();
      return landingPathForRole(_roleFromAccessToken(token));
    }
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
            final params = state.uri.queryParameters;
            final lat = double.tryParse(params['lat'] ?? '');
            final lng = double.tryParse(params['lng'] ?? '');
            final label = params['eventName'];
            return NoTransitionPage(
              child: MapPage(
                focusLat: lat,
                focusLng: lng,
                focusLabel: (label == null || label.isEmpty) ? null : label,
              ),
            );
          },
        ),
        GoRoute(
          path: '/weather',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WeatherPage(),
          ),
        ),
        GoRoute(
          path: '/campaigns',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _RoleGate(
              allowedRoles: {'STAFF', 'MANAGER', 'ADMIN'},
              child: CampaignListPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/campaigns/:campaignId/dashboard',
          pageBuilder: (context, state) => NoTransitionPage(
            child: _RoleGate(
              allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
              child: CampaignDashboardPage(
                campaignId: int.parse(state.pathParameters['campaignId']!),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/campaigns/:campaignId/events',
          pageBuilder: (context, state) => NoTransitionPage(
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
          pageBuilder: (context, state) => NoTransitionPage(
            child: _RoleGate(
              allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
              child: EventDetailPage(
                eventId: int.parse(state.pathParameters['eventId']!),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/campaigns-temp',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CampaignsTempPage(),
          ),
        ),
        GoRoute(
          path: '/schools',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _RoleGate(
              allowedRoles: {'STAFF', 'MANAGER', 'ADMIN'},
              child: SchoolListPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/schools/:schoolUid',
          pageBuilder: (context, state) => NoTransitionPage(
            child: _RoleGate(
              allowedRoles: const {'STAFF', 'MANAGER', 'ADMIN'},
              child: SchoolDetailPage(
                schoolUid: state.pathParameters['schoolUid']!,
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/schools-temp',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SchoolsTempPage(),
          ),
        ),
        GoRoute(
          path: '/student/my-registrations',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _RoleGate(
              allowedRoles: {'STUDENT'},
              child: MyRegistrationsPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/admin/users',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: _RoleGate(
              allowedRoles: {'ADMIN'},
              child: AdminUsersPage(),
            ),
          ),
        ),
        GoRoute(
          path: '/logout',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: LogoutPage(),
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
    final location = GoRouterState.of(context).uri.path;
    final user = ref.watch(activeUserProvider).valueOrNull;
    final navItems = _navItemsFor(user?.role);
    final activePath = _activeNavPath(location);
    final index = navItems.indexWhere((item) => item.path == activePath);
    final selectedIndex = index < 0 ? 0 : index;

    final navBar = Container(
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.08),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (i) {
          context.go(navItems[i].path);
        },
        destinations: [
          for (final item in navItems)
            NavigationDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: item.label,
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Scaffold(
            body: Row(
              children: [
                const Expanded(
                  flex: 6,
                  child: VietnamMapView(),
                ),
                Container(
                  width: 1,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  flex: 4,
                  child: Scaffold(
                    body: child,
                    bottomNavigationBar: navBar,
                  ),
                ),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: child,
            bottomNavigationBar: navBar,
          );
        }
      },
    );
  }

  String _activeNavPath(String location) {
    if (location.startsWith('/campaigns') || location.startsWith('/events')) {
      return '/campaigns';
    }
    if (location.startsWith('/schools')) return '/schools';
    if (location.startsWith('/student/my-registrations')) {
      return '/student/my-registrations';
    }
    if (location.startsWith('/admin/users')) return '/admin/users';
    if (location.startsWith('/weather')) return '/weather';
    return '/map';
  }

  List<_NavItem> _navItemsFor(String? role) {
    final items = <_NavItem>[
      const _NavItem('/map', 'Map', Icons.map_outlined, Icons.map),
      const _NavItem('/weather', 'Weather', Icons.cloud_outlined, Icons.cloud),
    ];
    if (role == 'STUDENT') {
      items.add(const _NavItem('/student/my-registrations', 'Mine',
          Icons.assignment_ind_outlined, Icons.assignment_ind));
      items.add(const _NavItem(
          '/logout', 'Logout', Icons.logout_outlined, Icons.logout));
      return items;
    }
    if (role == 'STAFF' || role == 'MANAGER' || role == 'ADMIN') {
      items.add(const _NavItem(
          '/campaigns', 'Campaign', Icons.campaign_outlined, Icons.campaign));
      items.add(const _NavItem(
          '/schools', 'Schools', Icons.school_outlined, Icons.school));
    }
    if (role == 'ADMIN') {
      items.add(const _NavItem('/admin/users', 'Users',
          Icons.admin_panel_settings_outlined, Icons.admin_panel_settings));
    }
    if (role != null) {
      items.add(const _NavItem(
          '/logout', 'Logout', Icons.logout_outlined, Icons.logout));
    }
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
          appBar: AppBar(title: const Text('Access denied')),
          body: const Center(
            child: Text('You do not have permission to view this page.'),
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
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final json = jsonDecode(payload) as Map<String, dynamic>;
    return json['role'] as String?;
  } catch (_) {
    return null;
  }
}
