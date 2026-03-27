import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/app_constants.dart';
import '../network/api_client.dart';
import '../network/rest_client.dart';
import '../storage/secure_storage.dart';
import '../storage/hive_storage.dart';
import '../api/api_service.dart';
import '../api/products_api.dart';
import '../api/sales_api.dart';

import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_remote_datasource_impl.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/verify_phone_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

import '../../features/sales/data/datasources/sales_remote_datasource.dart';
import '../../features/sales/data/repositories/sales_repository_impl.dart';
import '../../features/sales/domain/repositories/sales_repository.dart';
import '../../features/sales/domain/usecases/create_sale_usecase.dart';
import '../../features/sales/domain/usecases/get_sales_usecase.dart';
import '../../features/sales/presentation/bloc/sales_bloc.dart';

import '../../features/products/data/datasources/products_remote_datasource.dart';
import '../../features/products/data/repositories/products_repository_impl.dart';
import '../../features/products/domain/repositories/products_repository.dart';
import '../../features/products/domain/usecases/get_products_usecase.dart';
import '../../features/products/presentation/bloc/products_bloc.dart';

import '../../features/analytics/data/datasources/analytics_remote_datasource.dart';
import '../../features/analytics/data/repositories/analytics_repository_impl.dart';
import '../../features/analytics/domain/repositories/analytics_repository.dart';
import '../../features/analytics/presentation/bloc/analytics_bloc.dart';

import '../../features/staff/data/repositories/staff_repository_impl.dart';
import '../../features/staff/domain/repositories/staff_repository.dart';
import '../../features/staff/presentation/bloc/staff_bloc.dart';

import '../../features/shops/data/repositories/shop_repository_impl.dart';
import '../../features/shops/domain/repositories/shop_repository.dart';
import '../../features/shops/presentation/bloc/shop_bloc.dart';

import '../../features/users/data/repositories/user_repository_impl.dart';
import '../../features/users/domain/repositories/user_repository.dart';
import '../../features/users/presentation/bloc/user_bloc.dart';

final sl = GetIt.instance;

Future<void> setupDependencies({required String baseUrl}) async {
  final salesBox = await Hive.openBox(AppConstants.salesBox);
  final productsBox = await Hive.openBox(AppConstants.productsBox);

  sl.registerSingleton<HiveStorage>(HiveStorage(salesBox),
      instanceName: 'sales');
  sl.registerSingleton<HiveStorage>(HiveStorage(productsBox),
      instanceName: 'products');

  sl.registerSingleton<SecureStorage>(SecureStorage());

  final restClient =
      RestClient(baseUrl: baseUrl, secureStorage: sl<SecureStorage>());
  sl.registerSingleton<ApiClient>(restClient);

  sl.registerSingleton<ApiService>(
    ApiService(
      dio: restClient.dio,
      secureStorage: const FlutterSecureStorage(),
    ),
  );

  sl.registerSingleton<ProductsApi>(ProductsApi(sl<ApiService>()));
  sl.registerSingleton<SalesApi>(SalesApi(sl<ApiService>()));

  sl.registerSingleton<AuthRemoteDataSource>(
    AuthRemoteDataSourceImpl(apiService: sl<ApiService>()),
  );
  sl.registerSingleton<AuthLocalDataSource>(
    AuthLocalDataSource(secureStorage: sl<SecureStorage>()),
  );
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(
      remoteDataSource: sl<AuthRemoteDataSource>(),
      localDataSource: sl<AuthLocalDataSource>(),
    ),
  );
  sl.registerSingleton<LoginUseCase>(LoginUseCase(sl<AuthRepository>()));
  sl.registerSingleton<RegisterUseCase>(RegisterUseCase(sl<AuthRepository>()));
  sl.registerSingleton<VerifyPhoneUseCase>(
      VerifyPhoneUseCase(sl<AuthRepository>()));
  sl.registerSingleton<LogoutUseCase>(LogoutUseCase(sl<AuthRepository>()));

  sl.registerFactory<AuthBloc>(
    () => AuthBloc(
      loginUseCase: sl<LoginUseCase>(),
      registerUseCase: sl<RegisterUseCase>(),
      verifyPhoneUseCase: sl<VerifyPhoneUseCase>(),
      logoutUseCase: sl<LogoutUseCase>(),
      authRepository: sl<AuthRepository>(),
    ),
  );

  sl.registerSingleton<SalesRemoteDataSource>(
    SalesRemoteDataSource(apiClient: sl<ApiClient>()),
  );
  sl.registerSingleton<SalesRepository>(
    SalesRepositoryImpl(remoteDataSource: sl<SalesRemoteDataSource>()),
  );
  sl.registerSingleton<GetSalesUseCase>(GetSalesUseCase(sl<SalesRepository>()));
  sl.registerSingleton<CreateSaleUseCase>(
      CreateSaleUseCase(sl<SalesRepository>()));

  sl.registerFactory<SalesBloc>(
    () => SalesBloc(
      getSalesUseCase: sl<GetSalesUseCase>(),
      createSaleUseCase: sl<CreateSaleUseCase>(),
      salesRepository: sl<SalesRepository>(),
    ),
  );

  sl.registerSingleton<ProductsRemoteDataSource>(
    ProductsRemoteDataSource(productsApi: sl<ProductsApi>()),
  );
  sl.registerSingleton<ProductsRepository>(
    ProductsRepositoryImpl(remoteDataSource: sl<ProductsRemoteDataSource>()),
  );
  sl.registerSingleton<GetProductsUseCase>(
      GetProductsUseCase(sl<ProductsRepository>()));

  sl.registerFactory<ProductsBloc>(
    () => ProductsBloc(
      getProductsUseCase: sl<GetProductsUseCase>(),
      productsRepository: sl<ProductsRepository>(),
    ),
  );

  sl.registerSingleton<AnalyticsRemoteDataSource>(
    AnalyticsRemoteDataSource(apiClient: sl<ApiClient>()),
  );
  sl.registerSingleton<AnalyticsRepository>(
    AnalyticsRepositoryImpl(
        remoteDataSource: sl<AnalyticsRemoteDataSource>()),
  );

  sl.registerFactory<AnalyticsBloc>(       
    () => AnalyticsBloc(analyticsRepository: sl<AnalyticsRepository>()),
  );

  sl.registerSingleton<StaffRepository>(
    StaffRepositoryImpl(sl<ApiClient>()),
  );

  sl.registerFactory<StaffBloc>(
    () => StaffBloc(sl<StaffRepository>()),
  );

  sl.registerSingleton<ShopRepository>(
    ShopRepositoryImpl(sl<ApiClient>()),
  );

  sl.registerFactory<ShopBloc>(
    () => ShopBloc(sl<ShopRepository>()),
  );

  sl.registerSingleton<UserRepository>(
    UserRepositoryImpl(sl<ApiClient>()),
  );

  sl.registerFactory<UserBloc>(
    () => UserBloc(sl<UserRepository>()),
  );
}
