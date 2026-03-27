import 'package:equatable/equatable.dart';

abstract class ShopEvent extends Equatable {
  const ShopEvent();

  @override
  List<Object?> get props => [];
}

class ShopRequested extends ShopEvent {
  const ShopRequested();
}

class ShopCreateRequested extends ShopEvent {
  final String name;
  final String address;
  final String phone;
  final String email;

  const ShopCreateRequested({
    required this.name,
    required this.address,
    required this.phone,
    required this.email,
  });

  @override
  List<Object?> get props => [name, address, phone, email];
}

class ShopUpdateRequested extends ShopEvent {
  final int id;
  final String? name;
  final String? address;
  final String? phone;
  final String? email;
  final String? status;

  const ShopUpdateRequested({
    required this.id,
    this.name,
    this.address,
    this.phone,
    this.email,
    this.status,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        phone,
        email,
        status,
      ];
}

class ShopDeleteRequested extends ShopEvent {
  final int id;

  const ShopDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

class ShopDetailRequested extends ShopEvent {
  final int id;

  const ShopDetailRequested(this.id);

  @override
  List<Object?> get props => [id];
}
