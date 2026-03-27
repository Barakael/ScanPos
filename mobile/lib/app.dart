import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection_container.dart';
import 'core/router/app_router.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/analytics/presentation/bloc/analytics_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/products/presentation/bloc/products_bloc.dart';
import 'features/sales/presentation/bloc/sales_bloc.dart';
import 'features/staff/presentation/bloc/staff_bloc.dart';
import 'features/shops/presentation/bloc/shop_bloc.dart';
import 'features/users/presentation/bloc/user_bloc.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouter _appRouter;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize the router using the already-registered SecureStorage
    _appRouter = AppRouter(secureStorage: sl<SecureStorage>());
                        
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized, wrap the loader in MaterialApp to provide Directionality
    if (!_isInitialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => sl<AuthBloc>(), // Add back but don't auto-check
        ),
        BlocProvider<SalesBloc>(create: (_) => sl<SalesBloc>()),
        BlocProvider<ProductsBloc>(create: (_) => sl<ProductsBloc>()),
        BlocProvider<AnalyticsBloc>(create: (_) => sl<AnalyticsBloc>()),
        BlocProvider<StaffBloc>(create: (_) => sl<StaffBloc>()),
        BlocProvider<ShopBloc>(create: (_) => sl<ShopBloc>()),
        BlocProvider<UserBloc>(create: (_) => sl<UserBloc>()),
      ],
      child: MaterialApp.router(
        title: 'Tera POS',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: _appRouter.router,
      ),
    );
  }
}