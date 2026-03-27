import 'package:equatable/equatable.dart';

abstract class StaffEvent extends Equatable {
  const StaffEvent();

  @override
  List<Object?> get props => [];
}

class StaffRequested extends StaffEvent {
  const StaffRequested();
}

class StaffCreateRequested extends StaffEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String password;
  final String roleId;

  const StaffCreateRequested({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.password,
    required this.roleId,
  });

  @override
  List<Object?> get props => [
        firstName,
        lastName,
        email,
        phone,
        password,
        roleId,
      ];
}

class StaffUpdateRequested extends StaffEvent {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final String? roleId;

  const StaffUpdateRequested({
    required this.id,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.roleId,
  });

  @override
  List<Object?> get props => [
        id,
        firstName,
        lastName,
        email,
        phone,
        roleId,
      ];
}

class StaffDeleteRequested extends StaffEvent {
  final int id;

  const StaffDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}
