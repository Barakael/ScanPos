import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/pos/presentation/pages/pos_page.dart';
import '../../features/products/presentation/pages/products_list_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/sales/presentation/pages/create_sale_page.dart';
import '../../features/sales/presentation/pages/sale_detail_page.dart';
import '../../features/sales/presentation/pages/sales_list_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/shops/presentation/pages/shops_page.dart';
import '../../features/staff/presentation/pages/staff_page.dart';
import '../../features/users/presentation/pages/users_page.dart';
import '../storage/secure_storage.dart';
import 'route_names.dart';

class AppRouter {
  final SecureStorage secureStorage;

  AppRouter({required this.secureStorage});

  late final GoRouter router = GoRouter(
    initialLocation: RouteNames.home,
    redirect: _authGuard,
    routes: [
      GoRoute(
        path: RouteNames.home,
        builder: (_, __) => const HomePage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (_, __) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => DashboardShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (_, __) => const DashboardPage(),
          ),
          GoRoute(
            path: RouteNames.pos,
            builder: (_, __) => const POSPage(),
          ),
          GoRoute(
            path: RouteNames.inventory,
            builder: (_, __) => const ProductsListPage(),
          ),
          GoRoute(
            path: RouteNames.reports,
            builder: (_, __) => const ReportsPage(),
          ),
          GoRoute(
            path: RouteNames.users,
            builder: (_, __) => const UsersPage(),
          ),
          GoRoute(
            path: RouteNames.shops,
            builder: (_, __) => const ShopsPage(),
          ),
          GoRoute(
            path: RouteNames.staff,
            builder: (_, __) => const StaffPage(),
          ),
          GoRoute(
            path: RouteNames.settings,
            builder: (_, __) => const SettingsPage(),
          ),
          // Order matters: `/sales/create` before `/sales/:id`.
          GoRoute(
            path: RouteNames.createSale,
            builder: (_, __) => const CreateSalePage(),
          ),
          GoRoute(
            path: '/sales/:id',
            builder: (context, state) => SaleDetailPage(
              saleId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: RouteNames.sales,
            builder: (_, __) => const SalesListPage(),
          ),
        ],
      ),
    ],
  );

  Future<String?> _authGuard(
    BuildContext context,
    GoRouterState state,
  ) async {
    final token = await secureStorage.getToken();
    final isLoggedIn = token != null;
    final loc = state.matchedLocation;

    // Allow access to home page without authentication
    if (loc == RouteNames.home) {
      return null;
    }

    // Allow access to login and register pages
    if (loc == RouteNames.login) {
      if (isLoggedIn) return RouteNames.dashboard;
      return null;
    }

    if (loc == RouteNames.register) {
      if (isLoggedIn) return RouteNames.dashboard;
      return null;
    }

    // Require authentication for all other routes
    if (!isLoggedIn) {
      return RouteNames.login;
    }

    UserModel? user;
    final raw = await secureStorage.getUser();
    if (raw != null) {
      try {
        user = UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    final role = user?.role?.name.toLowerCase() ?? '';

    if (loc.startsWith(RouteNames.users)) {
      if (role != 'super_admin') return RouteNames.dashboard;
    }
    if (loc.startsWith(RouteNames.shops)) {
      if (role != 'super_admin') return RouteNames.dashboard;
    }
    if (loc.startsWith(RouteNames.staff) ||
        loc.startsWith(RouteNames.settings)) {
      if (role != 'owner') return RouteNames.dashboard;
    }
    if (loc.startsWith(RouteNames.inventory)) {
      if (role == 'cashier') return RouteNames.dashboard;
    }

    return null;
  }
}

/// Bottom navigation — items match `frontend/src/components/layout/AppSidebar.tsx`.
class DashboardShell extends StatelessWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is AuthAuthenticated) {
          return Scaffold(
            body: child,
            bottomNavigationBar: _RoleBasedBottomNav(
              userRole: authState.user.roleName,
            ),
          );
        }
        return Scaffold(body: child);
      },
    );
  }
}

class _RoleBasedBottomNav extends StatelessWidget {
  final String userRole;

  const _RoleBasedBottomNav({required this.userRole});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;

    final role = userRole.toLowerCase();
    List<NavigationItem> navigationItems;

    switch (role) {
      case 'super_admin':
        navigationItems = [
          NavigationItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: RouteNames.dashboard,
          ),
          NavigationItem(
            icon: Icons.point_of_sale_outlined,
            label: 'POS',
            route: RouteNames.pos,
          ),
          NavigationItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            route: RouteNames.inventory,
          ),
          NavigationItem(
            icon: Icons.assessment_outlined,
            label: 'Reports',
            route: RouteNames.reports,
          ),
          NavigationItem(
            icon: Icons.store_outlined,
            label: 'Shops',
            route: RouteNames.shops,
          ),
          NavigationItem(
            icon: Icons.people_outlined,
            label: 'Users',
            route: RouteNames.users,
          ),
        ];
        break;
      case 'owner':
        navigationItems = [
          NavigationItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: RouteNames.dashboard,
          ),
          NavigationItem(
            icon: Icons.point_of_sale_outlined,
            label: 'POS',
            route: RouteNames.pos,
          ),
          NavigationItem(
            icon: Icons.inventory_2_outlined,
            label: 'Inventory',
            route: RouteNames.inventory,
          ),
          NavigationItem(
            icon: Icons.assessment_outlined,
            label: 'Reports',
            route: RouteNames.reports,
          ),
          NavigationItem(
            icon: Icons.badge_outlined,
            label: 'Staff',
            route: RouteNames.staff,
          ),
          NavigationItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            route: RouteNames.settings,
          ),
        ];
        break;
      case 'cashier':
        navigationItems = [
          NavigationItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: RouteNames.dashboard,
          ),
          NavigationItem(
            icon: Icons.point_of_sale_outlined,
            label: 'POS',
            route: RouteNames.pos,
          ),
          NavigationItem(
            icon: Icons.assessment_outlined,
            label: 'Reports',
            route: RouteNames.reports,
          ),
        ];
        break;
      default:
        navigationItems = [
          NavigationItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: RouteNames.dashboard,
          ),
        ];
    }

    for (var i = 0; i < navigationItems.length; i++) {
      if (location.startsWith(navigationItems[i].route)) {
        currentIndex = i;
        break;
      }
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index < navigationItems.length) {
          context.go(navigationItems[index].route);
        }
      },
      destinations: navigationItems
          .map(
            (item) => NavigationDestination(
              icon: Icon(item.icon),
              label: item.label,
            ),
          )
          .toList(),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
