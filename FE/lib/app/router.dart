import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/map/presentation/pages/map_page.dart';
import '../features/map/presentation/pages/province_detail_page.dart';
import '../features/map/presentation/widgets/vietnam_map_view.dart';
import '../features/weather/presentation/pages/weather_page.dart';

final router = GoRouter(
  initialLocation: '/map',
  redirect: (context, state) {
    if (state.uri.path == '/') return '/map';
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
      ],
    ),
    GoRoute(
      path: '/province/:code',
      builder: (context, state) => ProvinceDetailPage(
        code: state.pathParameters['code']!,
      ),
    ),
  ],
);

class _AppShell extends StatelessWidget {
  const _AppShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = location.startsWith('/weather') ? 1 : 0;

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
          context.go(['/map', '/weather'][i]);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Bản đồ',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_outlined),
            selectedIcon: Icon(Icons.cloud),
            label: 'Thời tiết',
          ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          // Wide Screen: Map on the left, child on the right
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
          // Mobile Screen
          return Scaffold(
            body: child,
            bottomNavigationBar: navBar,
          );
        }
      },
    );
  }
}
