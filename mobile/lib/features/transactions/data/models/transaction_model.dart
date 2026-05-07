import '../../domain/entities/transaction_entity.dart';

class TransactionModel {
  final int id;
  final String cashierName;
  final String paymentMethod;
  final double total;
  final String status;
  final DateTime createdAt;
  final String? customerName;
  final List<TransactionItemModel> items;

  TransactionModel({
    required this.id,
    required this.cashierName,
    required this.paymentMethod,
    required this.total,
    required this.status,
    required this.createdAt,
    this.customerName,
    required this.items,
  });

  TransactionEntity toEntity() {
    return TransactionEntity(
      id: id,
      cashierName: cashierName,
      paymentMethod: paymentMethod,
      total: total,
      status: status,
      createdAt: createdAt,
      customerName: customerName,
      items: items.map((item) => item.toEntity()).toList(),
    );
  }
}

class TransactionItemModel {
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  TransactionItemModel({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  TransactionItemEntity toEntity() {
    return TransactionItemEntity(
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }
}
