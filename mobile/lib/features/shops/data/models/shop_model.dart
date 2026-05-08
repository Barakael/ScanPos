import '../../domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  const ShopModel({
    required super.id,
    required super.name,
    super.address = '',
    super.phone = '',
    super.email = '',
    super.taxRate = 0.0,
    super.currency = 'TZS',
    super.tin = '',
    super.vrn = '',
    super.mobile = '',
    super.location = '',
    super.taxOffice = '',
    super.serialPrefix = 'DEM',
    super.status = 'active',
    super.manager,
    super.ownerName,
    super.ownerEmail,
    super.branchesCount,
    super.staffCount,
    super.createdAt,
    super.updatedAt,
  });

  /// Laravel/API snake_case shop payload (e.g. nested under login `user.shop`).
  factory ShopModel.fromApi(Map<String, dynamic> json) {
    final idVal = json['id'];
    return ShopModel(
      id: idVal is int ? idVal : (idVal as num).toInt(),
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 18.0,
      currency: json['currency']?.toString() ?? 'TZS',
      tin: json['tin']?.toString() ?? '',
      vrn: json['vrn']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      taxOffice: json['tax_office']?.toString() ?? '',
      serialPrefix: json['serial_prefix']?.toString() ?? 'DEM',
      status: 'active',
      manager: json['owner']?['name'] as String?,
      ownerName: json['owner']?['name'] as String?,
      ownerEmail: json['owner']?['email'] as String?,
      branchesCount: json['branches_count'] as int?,
      staffCount: json['staff_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  factory ShopModel.fromJson(Map<String, dynamic> json) => ShopModel.fromApi(json);

  Map<String, dynamic> toApiJson() => {
        'id': id,
        'name': name,
        'address': address,
        'phone': phone,
        'email': email,
        'tax_rate': taxRate,
        'currency': currency,
        'tin': tin,
        'vrn': vrn,
        'mobile': mobile,
        'location': location,
        'tax_office': taxOffice,
        'serial_prefix': serialPrefix,
        'status': status,
        'manager_name': manager,
        'owner_name': ownerName,
        'owner_email': ownerEmail,
        'branches_count': branchesCount,
        'staff_count': staffCount,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  Map<String, dynamic> toJson() => toApiJson();
}
