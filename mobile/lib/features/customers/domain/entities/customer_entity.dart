import 'package:equatable/equatable.dart';

class CustomerEntity extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String companyId;
  final DateTime createdAt;

  const CustomerEntity({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.companyId,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, name];
}
