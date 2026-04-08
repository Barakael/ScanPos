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
import '../../features/settings/presentation/pages/owner_settings_page.dart' as owner_settings;
import '../../features/shops/presentation/pages/shops_page.dart';
import '../../features/staff/presentation/pages/staff_page.dart';
import '../../features/transactions/presentation/pages/transactions_page.dart';
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
            path: RouteNames.transactions,
            builder: (_, __) => const TransactionsPage(),
          ),
          GoRoute(
            path: RouteNames.settings,
            builder: (context, state) {
              return BlocBuilder<AuthBloc, AuthState>(
                builder: (context, authState) {
                  if (authState is AuthAuthenticated) {
                    final role = authState.user.roleName.toLowerCase();
                    if (role == 'owner' || role == 'store owner' || role == 'shop owner') {
                      return const owner_settings.OwnerSettingsPage();
                    }
                  }
                  return const SettingsPage();
                },
              );
            },
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

    if (loc == RouteNames.home) return null;

    if (loc == RouteNames.login) {
      if (isLoggedIn) return RouteNames.dashboard;
      return null;
    }

    if (loc == RouteNames.register) {
      if (isLoggedIn) return RouteNames.dashboard;
      return null;
    }

    if (!isLoggedIn) return RouteNames.login;

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
      if (role != 'owner' && role != 'store owner' && role != 'shop owner') return RouteNames.dashboard;
    }
    if (loc.startsWith(RouteNames.inventory)) {
      if (role == 'cashier') return RouteNames.dashboard;
    }

    return null;
  }
}

// ---------------------------------------------------------------------------
// Shell
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Bottom nav
// ---------------------------------------------------------------------------

class _RoleBasedBottomNav extends StatelessWidget {
  final String userRole;
  const _RoleBasedBottomNav({required this.userRole});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final role = userRole.toLowerCase();

    final List<NavigationItem> primaryItems;
    final List<NavigationItem> overflowItems;

    switch (role) {
      case 'super_admin':
        primaryItems = [
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
        ];
        overflowItems = [
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
      case 'store owner':
      case 'shop owner':
        primaryItems = [
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
        ];
        overflowItems = [
          NavigationItem(
            icon: Icons.badge_outlined,
            label: 'Staff',
            route: RouteNames.staff,
          ),
          NavigationItem(
            icon: Icons.receipt_long_outlined,
            label: 'Transactions',
            route: RouteNames.transactions,
          ),
          NavigationItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            route: RouteNames.settings,
          ),
        ];
        break;

      case 'cashier':
        primaryItems = [
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
        overflowItems = [];
        break;

      default:
        primaryItems = [
          NavigationItem(
            icon: Icons.dashboard_outlined,
            label: 'Dashboard',
            route: RouteNames.dashboard,
          ),
        ];
        overflowItems = [];
    }

    final showMore = overflowItems.isNotEmpty;

    // Is the active route inside the overflow group?
    final overflowActive =
        overflowItems.any((item) => location.startsWith(item.route));

    int currentIndex = overflowActive ? primaryItems.length : 0;
    for (var i = 0; i < primaryItems.length; i++) {
      if (location.startsWith(primaryItems[i].route)) {
        currentIndex = i;
        break;
      }
    }

    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: (index) {
        if (index < primaryItems.length) {
          context.go(primaryItems[index].route);
        } else {
          _MoreBottomSheet.show(context, overflowItems);
        }
      },
      destinations: [
        ...primaryItems.map(
          (item) => NavigationDestination(
            icon: Icon(item.icon),
            label: item.label,
          ),
        ),
        if (showMore)
          NavigationDestination(
            icon: overflowActive
                ? const Icon(Icons.more_horiz)
                : const Icon(Icons.more_horiz_outlined),
            label: 'More',
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// "More" bottom sheet
// ---------------------------------------------------------------------------

class _MoreBottomSheet {
  static void show(BuildContext context, List<NavigationItem> items) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ...items.map(
                  (item) => ListTile(
                    leading: Icon(item.icon),
                    title: Text(item.label),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      context.go(item.route);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

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