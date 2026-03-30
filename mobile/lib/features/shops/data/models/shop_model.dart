import '../../domain/entities/shop_entity.dart';

class ShopModel extends ShopEntity {
  const ShopModel({
    required super.id,
    required super.name,
    super.address = '',
    super.phone = '',
    super.email = '',
    super.currency = 'TZS',
    super.status = 'active',
    super.manager,
    super.ownerName,
    super.ownerEmail,
    super.branchesCount,
    super.staffCount,
    super.createdAt,
    super.updatedAt,
  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      id: json['id'] as int,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      currency: json['currency'] as String? ?? 'TZS',
      status: 'active', // Default status since API doesn't include it in list
      manager: json['owner']?['name'] as String?,
      ownerName: json['owner']?['name'] as String?,
      ownerEmail: json['owner']?['email'] as String?,
      branchesCount: json['branches_count'] as int?,
      staffCount: json['staff_count'] as int?,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'email': email,
      'currency': currency,
      'status': status,
      'manager_name': manager,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'branches_count': branchesCount,
      'staff_count': staffCount,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
