import 'package:equatable/equatable.dart';

class SaleItemEntity extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const SaleItemEntity({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  @override
  List<Object?> get props => [id];
}

class SaleEntity extends Equatable {
  final String id;
  final String invoiceNo;
  final String status;
  final String taxType;
  final String vatType;
  final String paymentMethod;
  final double subtotal;
  final double netAmount;
  final double totalVat;
  final double total;
  final double discount;
  final String? customerId;
  final String? customerName;
  final String? customerPhone;
  final String cashierId;
  final String companyId;
  final List<SaleItemEntity> items;
  final DateTime createdAt;

  const SaleEntity({
    required this.id,
    required this.invoiceNo,
    required this.status,
    required this.taxType,
    required this.vatType,
    required this.paymentMethod,
    required this.subtotal,
    required this.netAmount,
    required this.totalVat,
    required this.total,
    required this.discount,
    this.customerId,
    this.customerName,
    this.customerPhone,
    required this.cashierId,
    required this.companyId,
    required this.items,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, invoiceNo];
}
