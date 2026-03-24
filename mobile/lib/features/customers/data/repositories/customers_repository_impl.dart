import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customers_repository.dart';
import '../datasources/customers_remote_datasource.dart';

class CustomersRepositoryImpl implements CustomersRepository {
  final CustomersRemoteDataSource remoteDataSource;
  const CustomersRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<CustomerEntity>>> getCustomers({
    String? search,
  }) async {
    try {
      final models = await remoteDataSource.getCustomers(search: search);
      return Right(models.map((m) => m.toEntity()).toList());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> createCustomer(
      Map<String, dynamic> data) async {
    try {
      return Right((await remoteDataSource.createCustomer(data)).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomerEntity>> updateCustomer(
      String id, Map<String, dynamic> data) async {
    try {
      return Right(
          (await remoteDataSource.updateCustomer(id, data)).toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomer(String id) async {
    try {
      await remoteDataSource.deleteCustomer(id);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
