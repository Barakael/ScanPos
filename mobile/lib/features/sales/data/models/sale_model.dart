import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/sale_entity.dart';

part 'sale_model.g.dart';

@JsonSerializable()
class SaleItemModel {
  final String id;
  final String productId;
  @JsonKey(name: 'product')
  final ProductRefModel? product;
  final int quantity;
  final double unitPrice;
  final double subtotal;

  const SaleItemModel({
    required this.id,
    required this.productId,
    this.product,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
  });

  factory SaleItemModel.fromJson(Map<String, dynamic> json) =>
      _$SaleItemModelFromJson(json);
  Map<String, dynamic> toJson() => _$SaleItemModelToJson(this);

  SaleItemEntity toEntity() => SaleItemEntity(
        id: id,
        productId: productId,
        productName: product?.name ?? '',
        quantity: quantity,
        unitPrice: unitPrice,
        subtotal: subtotal,
      );
}

@JsonSerializable()
class ProductRefModel {
  final String id;
  final String name;

  const ProductRefModel({required this.id, required this.name});

  factory ProductRefModel.fromJson(Map<String, dynamic> json) =>
      _$ProductRefModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductRefModelToJson(this);
}

@JsonSerializable()
class SaleModel {
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
  @JsonKey(name: 'saleItems', defaultValue: [])
  final List<SaleItemModel> items;
  final DateTime createdAt;

  const SaleModel({
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

  factory SaleModel.fromJson(Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);
  Map<String, dynamic> toJson() => _$SaleModelToJson(this);

  /// Laravel API response (snake_case keys, `items` relation).
  factory SaleModel.fromLaravelJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'] as List<dynamic>? ?? [];
    final items = itemsRaw.map((e) {
      final m = e as Map<String, dynamic>;
      final qty = (m['quantity'] as num?)?.toInt() ?? 0;
      final unit = (m['unit_price'] as num?)?.toDouble() ?? 0.0;
      final name = m['product_name']?.toString() ?? '';
      final pid = m['product_id']?.toString() ?? '';
      return SaleItemModel(
        id: m['id']?.toString() ?? '',
        productId: pid,
        product: ProductRefModel(id: pid, name: name),
        quantity: qty,
        unitPrice: unit,
        subtotal: unit * qty,
      );
    }).toList();

    final createdRaw = json['created_at'] ?? json['createdAt'];
    final createdAt = createdRaw is String
        ? (DateTime.tryParse(createdRaw) ?? DateTime.now())
        : DateTime.now();

    return SaleModel(
      id: json['id']?.toString() ?? '',
      invoiceNo: json['id']?.toString() ?? '',
      status: 'completed',
      taxType: '',
      vatType: '',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      netAmount: (json['subtotal'] as num?)?.toDouble() ?? 0,
      totalVat: (json['tax'] as num?)?.toDouble() ?? 0,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      discount: 0,
      customerId: null,
      customerName: null,
      customerPhone: null,
      cashierId: json['cashier_id']?.toString() ?? '',
      companyId: '',
      items: items,
      createdAt: createdAt,
    );
  }

  SaleEntity toEntity() => SaleEntity(
        id: id,
        invoiceNo: invoiceNo,
        status: status,
        taxType: taxType,
        vatType: vatType,
        paymentMethod: paymentMethod,
        subtotal: subtotal,
        netAmount: netAmount,
        totalVat: totalVat,
        total: total,
        discount: discount,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
        cashierId: cashierId,
        companyId: companyId,
        items: items.map((i) => i.toEntity()).toList(),
        createdAt: createdAt,
      );
}
