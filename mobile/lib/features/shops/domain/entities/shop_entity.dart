import 'package:equatable/equatable.dart';

class ShopEntity extends Equatable {
  final int id;
  final String name;
  final String address;
  final String phone;
  final String email;
  final String status;
  final String? manager;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ShopEntity({
    required this.id,
    required this.name,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.status = 'active',
    this.manager,
    this.createdAt,
    this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        email,
        status,
        manager,
        createdAt,
        updatedAt,
      ];
}
