import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../models/transaction_model.dart';

abstract class TransactionsRemoteDataSource {
  Future<List<TransactionModel>> getTransactions({String? date});
}

class TransactionsRemoteDataSourceImpl implements TransactionsRemoteDataSource {
  final ApiClient apiClient;
  
  const TransactionsRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<TransactionModel>> getTransactions({String? date}) async {
    try {
      // Use the sales endpoint since transactions are essentially sales
      final response = await apiClient.get<List<dynamic>>(
        endpoint: ApiEndpoints.sales,
        queryParameters: {
          if (date != null && date.isNotEmpty) 'date': date,
        },
        parser: (json) => json as List<dynamic>,
      );
      
      // Convert sales data to transaction models
      return response.map((saleData) {
        final sale = saleData as Map<String, dynamic>;
        return TransactionModel(
          id: sale['id'] as int,
          cashierName: sale['cashier_id']?.toString() ?? 'Unknown',
          paymentMethod: sale['payment_method']?.toString() ?? 'Unknown',
          total: (sale['total'] as num?)?.toDouble() ?? 0.0,
          status: sale['status'] ?? 'unknown',
          createdAt: sale['created_at'] != null 
              ? DateTime.parse(sale['created_at'] as String)
              : DateTime.now(),
          customerName: sale['customer_name'],
          items: _parseItems(sale['items'] as List<dynamic>? ?? []),
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }
  
  List<TransactionItemModel> _parseItems(List<dynamic> itemsData) {
    return itemsData.map((item) {
      final itemMap = item as Map<String, dynamic>;
      return TransactionItemModel(
        productName: itemMap['product_name']?.toString() ?? 'Unknown Product',
        quantity: (itemMap['quantity'] as num?)?.toInt() ?? 0,
        unitPrice: (itemMap['unit_price'] as num?)?.toDouble() ?? 0.0,
        totalPrice: (itemMap['subtotal'] as num?)?.toDouble() ?? 0.0,
      );
    }).toList();
  }
}
