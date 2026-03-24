import '../models/customer_model.dart';

/// Backend has no `/customers` routes; stub keeps legacy code compiling.
class CustomersRemoteDataSource {
  const CustomersRemoteDataSource();

  Future<List<CustomerModel>> getCustomers({String? search}) async => [];

  Future<CustomerModel> createCustomer(Map<String, dynamic> data) async {
    throw UnsupportedError('Customers API is not available on this backend');
  }

  Future<CustomerModel> updateCustomer(
    String id,
    Map<String, dynamic> data,
  ) async {
    throw UnsupportedError('Customers API is not available on this backend');
  }

  Future<void> deleteCustomer(String id) async {
    throw UnsupportedError('Customers API is not available on this backend');
  }
}
