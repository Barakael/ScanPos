import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/customer_entity.dart';
import '../../domain/repositories/customers_repository.dart';

// Events
abstract class CustomersEvent extends Equatable {
  const CustomersEvent();
  @override
  List<Object?> get props => [];
}

class CustomersFetchRequested extends CustomersEvent {
  final String? search;
  const CustomersFetchRequested({this.search});
}

class CustomerCreateRequested extends CustomersEvent {
  final Map<String, dynamic> data;
  const CustomerCreateRequested(this.data);
}

class CustomerUpdateRequested extends CustomersEvent {
  final String id;
  final Map<String, dynamic> data;
  const CustomerUpdateRequested(this.id, this.data);
}

class CustomerDeleteRequested extends CustomersEvent {
  final String id;
  const CustomerDeleteRequested(this.id);
}

// States
abstract class CustomersState extends Equatable {
  const CustomersState();
  @override
  List<Object?> get props => [];
}

class CustomersInitial extends CustomersState { const CustomersInitial(); }
class CustomersLoading extends CustomersState { const CustomersLoading(); }

class CustomersLoaded extends CustomersState {
  final List<CustomerEntity> customers;
  const CustomersLoaded(this.customers);
  @override
  List<Object?> get props => [customers];
}

class CustomerActionSuccess extends CustomersState {
  final String message;
  const CustomerActionSuccess(this.message);
}

class CustomersError extends CustomersState {
  final String message;
  const CustomersError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class CustomersBloc extends Bloc<CustomersEvent, CustomersState> {
  final CustomersRepository customersRepository;

  CustomersBloc({required this.customersRepository})
      : super(const CustomersInitial()) {
    on<CustomersFetchRequested>(_onFetch);
    on<CustomerCreateRequested>(_onCreate);
    on<CustomerUpdateRequested>(_onUpdate);
    on<CustomerDeleteRequested>(_onDelete);
  }

  Future<void> _onFetch(
    CustomersFetchRequested event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    final result =
        await customersRepository.getCustomers(search: event.search);
    result.fold(
      (f) => emit(CustomersError(f.message)),
      (customers) => emit(CustomersLoaded(customers)),
    );
  }

  Future<void> _onCreate(
    CustomerCreateRequested event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    final result = await customersRepository.createCustomer(event.data);
    result.fold(
      (f) => emit(CustomersError(f.message)),
      (_) => emit(const CustomerActionSuccess('Customer created')),
    );
  }

  Future<void> _onUpdate(
    CustomerUpdateRequested event,
    Emitter<CustomersState> emit,
  ) async {
    emit(const CustomersLoading());
    final result =
        await customersRepository.updateCustomer(event.id, event.data);
    result.fold(
      (f) => emit(CustomersError(f.message)),
      (_) => emit(const CustomerActionSuccess('Customer updated')),
    );
  }

  Future<void> _onDelete(
    CustomerDeleteRequested event,
    Emitter<CustomersState> emit,
  ) async {
    final result = await customersRepository.deleteCustomer(event.id);
    result.fold(
      (f) => emit(CustomersError(f.message)),
      (_) => emit(const CustomerActionSuccess('Customer deleted')),
    );
  }
}
