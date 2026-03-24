import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/customer_entity.dart';

part 'customer_model.g.dart';

@JsonSerializable()
class CustomerModel {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final String companyId;
  final DateTime createdAt;

  const CustomerModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.companyId,
    required this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) =>
      _$CustomerModelFromJson(json);
  Map<String, dynamic> toJson() => _$CustomerModelToJson(this);

  CustomerEntity toEntity() => CustomerEntity(
        id: id,
        name: name,
        email: email,
        phone: phone,
        companyId: companyId,
        createdAt: createdAt,
      );
}
