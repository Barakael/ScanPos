import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/repositories/sales_repository.dart';
import '../datasources/sales_remote_datasource.dart';

class SalesRepositoryImpl implements SalesRepository {
  final SalesRemoteDataSource remoteDataSource;
  const SalesRepositoryImpl({required this.remoteDataSource});

  /// Normalizes mobile/legacy payloads to Laravel `POST /sales` body.
  static Map<String, dynamic> normalizeSalePayload(Map<String, dynamic> raw) {
    final rawItems = raw['items'] as List<dynamic>? ?? [];
    final items = rawItems.map((e) {
      final m = e as Map<String, dynamic>;
      final pid = m['product_id'] ?? m['productId'];
      return {
        'product_id': pid is int ? pid : int.tryParse(pid.toString()) ?? pid,
        'quantity': m['quantity'],
      };
    }).toList();

    final pm = (raw['payment_method'] ?? raw['paymentMethod'] ?? 'cash')
        .toString()
        .toLowerCase();
    final method = switch (pm) {
      'cash' => 'cash',
      'card' => 'card',
      'mobile' => 'mobile',
      _ when pm.contains('card') => 'card',
      _ when pm.contains('mobile') => 'mobile',
      _ => 'cash',
    };

    return {
      'payment_method': method,
      'items': items,
    };
  }

  @override
  Future<Either<Failure, List<SaleEntity>>> getSales({String? date}) async {
    try {
      final models = await remoteDataSource.getSales(date: date);
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
  Future<Either<Failure, SaleEntity>> getSaleById(String id) async {
    try {
      final model = await remoteDataSource.getSaleById(id);
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, SaleEntity>> createSale(
    Map<String, dynamic> saleData,
  ) async {
    try {
      final model = await remoteDataSource.createSale(
        normalizeSalePayload(saleData),
      );
      return Right(model.toEntity());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }
}
