import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/campaign/presentation/pages/campaigns_temp_page.dart';
import '../features/map/presentation/pages/map_page.dart';
import '../features/map/presentation/widgets/vietnam_map_view.dart';
import '../features/school/presentation/pages/schools_temp_page.dart';
import '../features/weather/presentation/pages/weather_page.dart';

final router = GoRouter(
  initialLocation: '/map',
  redirect: (context, state) {
    if (state.uri.path == '/') return '/map';
    if (state.uri.path.startsWith('/province/')) return '/map';
    return null;
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) => _AppShell(child: child),
      routes: [
        GoRoute(
          path: '/map',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: MapPage(),
          ),
        ),
        GoRoute(
          path: '/weather',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: WeatherPage(),
          ),
        ),
        GoRoute(
          path: '/campaigns-temp',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CampaignsTempPage(),
          ),
        ),
        GoRoute(
          path: '/schools-temp',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SchoolsTempPage(),
          ),
        ),
      ],
    ),
  ],
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = location.startsWith('/weather')
        ? 1
        : location.startsWith('/campaigns')
            ? 2
            : location.startsWith('/schools')
                ? 3
                : 0;

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
        selectedIndex: index,
        onDestinationSelected: (i) {
          context
              .go(['/map', '/weather', '/campaigns-temp', '/schools-temp'][i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Weather',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Campaign',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            selectedIcon: Icon(Icons.school),
            label: 'Schools',
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
}
