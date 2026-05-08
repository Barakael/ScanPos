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
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? customerAddress;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? customerIdType;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String serialNumber;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String znr;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String uin;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String verificationCode;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final double totalExclTax;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final double totalTax;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final double amountTendered;
  @JsonKey(includeFromJson: false, includeToJson: false)
  final double cashChange;
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
    this.customerAddress,
    this.customerIdType,
    this.serialNumber = '',
    this.znr = '',
    this.uin = '',
    this.verificationCode = '',
    this.totalExclTax = 0,
    this.totalTax = 0,
    this.amountTendered = 0,
    this.cashChange = 0,
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

    final serial = json['serial_number']?.toString() ?? '';
    final totalExcl =
        (json['total_excl_tax'] as num?)?.toDouble() ?? 0.0;
    final totalTaxApi =
        (json['total_tax'] as num?)?.toDouble() ??
            (json['tax'] as num?)?.toDouble() ??
            0.0;

    return SaleModel(
      id: json['id']?.toString() ?? '',
      invoiceNo: serial.isNotEmpty ? serial : (json['id']?.toString() ?? ''),
      status: 'completed',
      taxType: '',
      vatType: '',
      paymentMethod: json['payment_method']?.toString() ?? 'cash',
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
      netAmount: (json['subtotal'] as num?)?.toDouble() ?? 0,
      totalVat: totalTaxApi,
      total: (json['total'] as num?)?.toDouble() ?? 0,
      discount: 0,
      customerId: json['customer_id']?.toString(),
      customerName: json['customer_name']?.toString(),
      customerPhone: json['customer_phone']?.toString(),
      customerAddress: json['customer_address']?.toString(),
      customerIdType: json['customer_id_type']?.toString(),
      serialNumber: serial,
      znr: json['znr']?.toString() ?? '',
      uin: json['uin']?.toString() ?? '',
      verificationCode: json['verification_code']?.toString() ?? '',
      totalExclTax: totalExcl,
      totalTax: totalTaxApi,
      amountTendered:
          (json['amount_tendered'] as num?)?.toDouble() ?? 0.0,
      cashChange: (json['change'] as num?)?.toDouble() ??
          (json['cash_change'] as num?)?.toDouble() ??
          0.0,
      cashierId: json['cashier_id']?.toString() ?? '',
      companyId: json['shop_id']?.toString() ?? '',
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
        customerAddress: customerAddress,
        customerIdType: customerIdType,
        serialNumber: serialNumber,
        znr: znr,
        uin: uin,
        verificationCode: verificationCode,
        totalExclTax: totalExclTax,
        totalTax: totalTax,
        amountTendered: amountTendered,
        cashChange: cashChange,
        cashierId: cashierId,
        companyId: companyId,
        items: items.map((i) => i.toEntity()).toList(),
        createdAt: createdAt,
      );
}
