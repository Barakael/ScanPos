import 'package:get_it/get_it.dart';
import '../data/datasources/transactions_remote_datasource.dart';
import '../data/models/transaction_model.dart';
import '../data/repositories/transactions_repository_impl.dart';
import '../domain/repositories/transactions_repository.dart';
import '../domain/usecases/get_transactions_usecase.dart';
import '../presentation/bloc/transactions_bloc.dart';

class TransactionsInjection {
  static void init() {
    final GetIt getIt = GetIt.instance;
    
    // DataSource
    getIt.registerLazySingleton<TransactionsRemoteDataSource>(
      () => TransactionsRemoteDataSourceImpl(),
    );
    
    // Repository
    getIt.registerLazySingleton<TransactionsRepository>(
      () => TransactionsRepositoryImpl(
        remoteDataSource: getIt<TransactionsRemoteDataSource>(),
      ),
    );
    
    // Use Cases
    getIt.registerLazySingleton<GetTransactionsUseCase>(
      () => GetTransactionsUseCase(
        repository: getIt<TransactionsRepository>(),
      ),
    );
    
    // BLoC
    getIt.registerFactory<TransactionsBloc>(
      () => TransactionsBloc(
        getTransactionsUseCase: getIt<GetTransactionsUseCase>(),
      ),
    );
  }
}
