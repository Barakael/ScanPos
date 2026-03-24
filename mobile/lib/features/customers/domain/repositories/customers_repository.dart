import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/customer_entity.dart';

abstract class CustomersRepository {
  Future<Either<Failure, List<CustomerEntity>>> getCustomers({String? search});
  Future<Either<Failure, CustomerEntity>> createCustomer(Map<String, dynamic> data);
  Future<Either<Failure, CustomerEntity>> updateCustomer(String id, Map<String, dynamic> data);
  Future<Either<Failure, void>> deleteCustomer(String id);
}
